import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============ PRODUCTS ============
  Stream<List<Map<String, dynamic>>> productsStream() {
    return _db.collection('products').snapshots().map((snap) {
      return snap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'name': d['name'] ?? '',
          'price': d['price'] ?? 0,
          'category': d['category'] ?? '',
          'emoji': d['emoji'] ?? '🛒',
          'barcode': d['barcode'] ?? '',
        };
      }).toList();
    });
  }

  Future<void> addProduct({
    required String name,
    required int price,
    required String category,
    required String emoji,
    required String barcode,
  }) async {
    await _db.collection('products').add({
      'name': name,
      'price': price,
      'category': category,
      'emoji': emoji,
      'barcode': barcode,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBarcode(String id, String barcode) async {
    await _db.collection('products').doc(id).update({'barcode': barcode});
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  Future<void> deleteProductsInCategory(String category) async {
    final snap = await _db
        .collection('products')
        .where('category', isEqualTo: category)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // ============ CATEGORIES ============
  Stream<List<String>> categoriesStream() {
    return _db
        .collection('categories')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => d.data()['name'] as String? ?? '').toList());
  }

  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final existing = await _db
        .collection('categories')
        .where('name', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;
    await _db.collection('categories').add({
      'name': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String name) async {
    final snap = await _db
        .collection('categories')
        .where('name', isEqualTo: name)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
    await deleteProductsInCategory(name);
  }
}