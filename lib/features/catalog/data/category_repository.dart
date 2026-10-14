import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/repository_error_mapper.dart';
import '../domain/category.dart';

/// Akses collection `categories` (`docs/BLUEPRINT_APLIKASI.md` §6.1).
///
/// Katalog memakai stream ini untuk chip filter kategori; hanya kategori aktif
/// yang dikembalikan agar produk tidak pernah dikelompokkan di bawah kategori
/// yang sudah dinonaktifkan admin.
class CategoryRepository {
  CategoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _entityLabel = 'kategori';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.categories);

  /// Stream kategori aktif, terurut `sortOrder`.
  Stream<List<Category>> watchActiveCategories() {
    final Query<Map<String, dynamic>> query = _collection
        .where(CategoryFields.isActive, isEqualTo: true)
        .orderBy(CategoryFields.sortOrder);
    return guardRepositoryStream(
      query.snapshots().map(_mapSnapshot),
      entityLabel: _entityLabel,
    );
  }

  /// Versi sekali-baca dari [watchActiveCategories].
  Future<List<Category>> fetchActiveCategories() async {
    try {
      final Query<Map<String, dynamic>> query = _collection
          .where(CategoryFields.isActive, isEqualTo: true)
          .orderBy(CategoryFields.sortOrder);
      return _mapSnapshot(await query.get());
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  List<Category> _mapSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((doc) => Category.fromFirestore(doc.id, doc.data()))
          .toList(growable: false);
}
