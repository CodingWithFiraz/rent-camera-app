import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/category.dart';
import 'default_category_data.dart';

/// Akses collection `categories` (`docs/BLUEPRINT_APLIKASI.md` §6.1).
///
/// Katalog memakai stream ini untuk chip filter kategori dan form produk admin;
/// hanya kategori aktif yang dikembalikan agar produk tidak pernah dikelompokkan
/// di bawah kategori yang sudah dinonaktifkan admin.
/// Bila koleksi di Firestore masih kosong atau belum di-seed, repository secara
/// otomatis menyediakan [DefaultCategoryData.categories] agar kategori tetap tersedia.
class CategoryRepository {
  CategoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.categories);

  /// Stream kategori aktif, terurut `sortOrder`.
  ///
  /// Secara instan memancarkan [DefaultCategoryData.categories] sebagai data awal,
  /// kemudian mendengarkan pembaruan realtime dari Firestore bila ada.
  Stream<List<Category>> watchActiveCategories() async* {
    yield DefaultCategoryData.categories;
    try {
      await for (final snapshot in _collection.snapshots()) {
        final items =
            _mapSnapshot(snapshot)
                .where((Category cat) => cat.isActive)
                .toList()
              ..sort(
                (Category a, Category b) => a.sortOrder.compareTo(b.sortOrder),
              );
        if (items.isNotEmpty) {
          yield items;
        } else {
          yield DefaultCategoryData.categories;
        }
      }
    } catch (_) {
      // Pertahankan kategori default bila stream Firestore bermasalah (mis. offline/unindexed).
    }
  }

  /// Versi sekali-baca dari [watchActiveCategories].
  Future<List<Category>> fetchActiveCategories() async {
    try {
      final snapshot = await _collection.get();
      final items =
          _mapSnapshot(snapshot).where((Category cat) => cat.isActive).toList()
            ..sort(
              (Category a, Category b) => a.sortOrder.compareTo(b.sortOrder),
            );
      if (items.isNotEmpty) {
        return items;
      }
      return DefaultCategoryData.categories;
    } catch (_) {
      return DefaultCategoryData.categories;
    }
  }

  /// Menyimpan kategori default ke Firestore jika koleksi saat ini masih kosong.
  /// Bersifat idempotent dan aman dipanggil saat inisialisasi aplikasi.
  Future<void> seedDefaultCategoriesIfEmpty() async {
    try {
      final snapshot = await _collection.limit(1).get();
      if (snapshot.docs.isEmpty) {
        for (final category in DefaultCategoryData.categories) {
          await _collection.doc(category.id).set(<String, dynamic>{
            CategoryFields.name: category.name,
            CategoryFields.slug: category.slug,
            CategoryFields.description: category.description,
            CategoryFields.iconKey: category.iconKey,
            CategoryFields.sortOrder: category.sortOrder,
            CategoryFields.isActive: category.isActive,
            'isSample': true,
          }, SetOptions(merge: true));
        }
      }
    } catch (_) {
      // Best-effort: jika security rules membatasi penulisan klien,
      // aplikasi tetap menampilkan data default lewat watchActiveCategories.
    }
  }

  List<Category> _mapSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((doc) => Category.fromFirestore(doc.id, doc.data()))
          .toList(growable: false);
}
