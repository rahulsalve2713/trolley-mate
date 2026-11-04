import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // ✅ Added for debugPrint

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> saveOrder({
    required String username,
    required String trolleyCode,
    required List<Map<String, dynamic>> items,
    required double total,
    required String status,
  }) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('⚠️ Cannot save order — no user logged in'); // ✅ Changed
      return;
    }

    try {
      await _db.collection('orders').add({
        'userId': uid,
        'username': username,
        'trolleyCode': trolleyCode,
        'items': items,
        'total': total,
        'itemCount': items.fold<int>(0, (total, e) => total + (e['qty'] as int)),
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Order saved for user $uid'); // ✅ Changed
    } catch (e) {
      debugPrint('❌ Save order error: $e'); // ✅ Changed
    }
  }

  Stream<List<Map<String, dynamic>>> myOrdersStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'trolleyCode': d['trolleyCode'] ?? '',
          'username': d['username'] ?? '',
          'items': List<Map<String, dynamic>>.from(
              (d['items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e))),
          'total': (d['total'] ?? 0).toDouble(),
          'itemCount': d['itemCount'] ?? 0,
          'status': d['status'] ?? 'completed',
          'createdAt': d['createdAt'],
        };
      }).toList();

      list.sort((a, b) {
        final ta = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final tb = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return tb.compareTo(ta);
      });

      return list;
    });
  }
}