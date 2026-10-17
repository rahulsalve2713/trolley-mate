import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  CartService._();
  static final CartService instance = CartService._();

  // ============================================================
  // FIREBASE REALTIME DATABASE URL
  // ============================================================
  static const String _dbUrl =
      'https://trolley-mate-3c373-default-rtdb.asia-southeast1.firebasedatabase.app';

  // Explicitly use the URL so Flutter Web doesn't fail
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: _dbUrl,
  );

  final Map<String, Map<String, dynamic>> _items = {};
  String? _trolleyCode;
  String? _username;
  bool _initialized = false;

  final _controller =
      StreamController<Map<String, Map<String, dynamic>>>.broadcast();
  Stream<Map<String, Map<String, dynamic>>> get itemsStream =>
      _controller.stream;
  Map<String, Map<String, dynamic>> get items => Map.unmodifiable(_items);

  List<Map<String, dynamic>> get itemList => _items.entries
      .map((e) => {
            'name': e.key,
            'price': e.value['price'],
            'qty': e.value['qty'],
            'emoji': e.value['emoji'],
          })
      .toList();

  String get trolleyCode => _trolleyCode ?? '0000';
  String get username => _username ?? 'guest';
  int get totalItems =>
      _items.values.fold(0, (s, e) => s + (e['qty'] as int));
  double get totalPrice => _items.values.fold(
      0.0, (s, e) => s + (e['price'] as int) * (e['qty'] as int));

  // ============================================================
  // INIT
  // ============================================================
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _trolleyCode = prefs.getString('trolleyCode');
    _username = prefs.getString('username') ?? 'guest';
    _initialized = true;
  }

  // ============================================================
  // REFRESH IDENTITY
  // ============================================================
  Future<void> refreshIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'guest';
    _trolleyCode = prefs.getString('trolleyCode');
    _initialized = true;
  }

  // ============================================================
  // SET TROLLEY CODE
  // ============================================================
  Future<void> setTrolleyCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trolleyCode', code);
    _trolleyCode = code;
    _initialized = true;
    await _syncToFirebase();
  }

  // ============================================================
  // CLEAR TROLLEY CODE
  // ============================================================
  Future<void> clearTrolleyCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('trolleyCode');
    _trolleyCode = null;
    _items.clear();
    _emit();
  }

  // ============================================================
  // ITEM OPERATIONS
  // ============================================================
  Future<void> addItem(String name, int price, String emoji) async {
    await init();
    if (_trolleyCode == null || _trolleyCode!.isEmpty) {
      print('⚠️ Cannot add item — trolley code not set');
      return;
    }
    if (_items.containsKey(name)) {
      _items[name]!['qty'] = (_items[name]!['qty'] as int) + 1;
    } else {
      _items[name] = {'price': price, 'qty': 1, 'emoji': emoji};
    }
    _emit();
    await _syncToFirebase();
  }

  Future<void> removeItem(String name) async {
    if (!_items.containsKey(name)) return;
    if (_items[name]!['qty'] > 1) {
      _items[name]!['qty'] = (_items[name]!['qty'] as int) - 1;
    } else {
      _items.remove(name);
    }
    _emit();
    await _syncToFirebase();
  }

  Future<void> clear() async {
    _items.clear();
    _emit();
    await _syncToFirebase();
  }

  void _emit() {
    _controller.add(Map.from(_items));
  }

  // ============================================================
  // FIREBASE SYNC
  // ============================================================
  Future<void> _syncToFirebase() async {
    if (_trolleyCode == null || _trolleyCode!.isEmpty) {
      print('⚠️ Cannot sync — trolley code not set');
      return;
    }
    try {
      final ref = _db.ref('liveCarts/$_trolleyCode');
      if (_items.isEmpty) {
        await ref.remove();
      } else {
        await ref.set({
          'user': _username,
          'status': 'active',
          'total': totalPrice,
          'items': itemList,
          'updatedAt': ServerValue.timestamp,
        });
      }
      print('✅ Cart synced → liveCarts/$_trolleyCode');
    } catch (e) {
      print('❌ Cart sync error: $e');
    }
  }

  // ============================================================
  // MARK PAID
  // ============================================================
  Future<void> markPaid() async {
    await init();
    if (_trolleyCode == null || _trolleyCode!.isEmpty) return;
    try {
      await _db.ref('liveCarts/$_trolleyCode').update({'status': 'paid'});
    } catch (e) {
      print('❌ markPaid error: $e');
    }
  }
}