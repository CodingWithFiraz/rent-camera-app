import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/repository_error_mapper.dart';
import '../domain/product.dart';

/// Akses collection `products` (`docs/BLUEPRINT_APLIKASI.md` §6.2).
///
/// Blueprint §5 "Realtime": katalog memakai stream Firestore dan hanya
/// menampilkan produk `isActive == true`. Filter itu diterapkan pada query di
/// sini (bukan di widget), sehingga katalog otomatis menyesuaikan saat admin
/// mengubah data.
class ProductRepository {
  ProductRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _entityLabel = 'produk';

  /// Batas `whereIn` agar dokumen tetap dapat dibaca dalam satu query.
  static const int _whereInLimit = 30;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.products);

  /// Stream produk aktif, opsional disaring satu kategori.
  ///
  /// Kombinasi `isActive == true` + `categoryId` memakai composite index pada
  /// `firebase/firestore.indexes.json`.
  Stream<List<Product>> watchActiveProducts({String? categoryId}) {
    return guardRepositoryStream(
      _activeQuery(categoryId).snapshots().map(_mapSnapshot),
      entityLabel: _entityLabel,
    );
  }

  /// Versi sekali-baca dari [watchActiveProducts].
  Future<List<Product>> fetchActiveProducts({String? categoryId}) async {
    try {
      return _mapSnapshot(await _activeQuery(categoryId).get());
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  /// Membaca satu produk apa adanya, termasuk yang sudah diarsipkan.
  ///
  /// Dipakai tombol "Sewa"/checkout untuk membaca ulang harga, status, dan
  /// stok dari Firestore sebelum menyusun pesan WhatsApp.
  Future<Product?> fetchProductById(String productId) async {
    final id = productId.trim();
    if (id.isEmpty) {
      return null;
    }
    try {
      final snapshot = await _collection.doc(id).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return Product.fromFirestore(snapshot.id, data);
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  /// Membaca beberapa produk sekaligus berdasarkan document ID.
  ///
  /// Produk yang sudah dihapus permanen tidak muncul pada hasil, sehingga
  /// pemanggil dapat menandai item keranjang sebagai tidak tersedia.
  Future<Map<String, Product>> fetchProductsByIds(
    Iterable<String> productIds,
  ) async {
    final ids = productIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ids.isEmpty) {
      return const <String, Product>{};
    }

    try {
      final Map<String, Product> products = <String, Product>{};
      for (var start = 0; start < ids.length; start += _whereInLimit) {
        final end = start + _whereInLimit > ids.length
            ? ids.length
            : start + _whereInLimit;
        final chunk = ids.sublist(start, end);
        final snapshot = await _collection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snapshot.docs) {
          products[doc.id] = Product.fromFirestore(doc.id, doc.data());
        }
      }
      return products;
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  Query<Map<String, dynamic>> _activeQuery(String? categoryId) {
    Query<Map<String, dynamic>> query = _collection.where(
      ProductFields.isActive,
      isEqualTo: true,
    );
    final normalizedCategoryId = categoryId?.trim();
    if (normalizedCategoryId != null && normalizedCategoryId.isNotEmpty) {
      query = query.where(
        ProductFields.categoryId,
        isEqualTo: normalizedCategoryId,
      );
    }
    return query;
  }

  List<Product> _mapSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((doc) => Product.fromFirestore(doc.id, doc.data()))
          .toList(growable: false);
}
