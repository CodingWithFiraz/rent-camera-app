import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/repository_error_mapper.dart';
import '../domain/banner.dart';

/// Akses collection `banners` (`docs/BLUEPRINT_APLIKASI.md` §6.5).
///
/// Carousel katalog memakai stream ini; UI bertanggung jawab membatasi jumlah
/// slide dan memvalidasi [Banner.hasNavigableTarget] sebelum navigasi.
class BannerRepository {
  BannerRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _entityLabel = 'banner';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.banners);

  /// Stream banner aktif, terurut `sortOrder`.
  Stream<List<Banner>> watchActiveBanners() {
    final Query<Map<String, dynamic>> query = _collection
        .where(BannerFields.isActive, isEqualTo: true)
        .orderBy(BannerFields.sortOrder);
    return guardRepositoryStream(
      query.snapshots().map(_mapSnapshot),
      entityLabel: _entityLabel,
    );
  }

  /// Versi sekali-baca dari [watchActiveBanners].
  Future<List<Banner>> fetchActiveBanners() async {
    try {
      final Query<Map<String, dynamic>> query = _collection
          .where(BannerFields.isActive, isEqualTo: true)
          .orderBy(BannerFields.sortOrder);
      return _mapSnapshot(await query.get());
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  List<Banner> _mapSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((doc) => Banner.fromFirestore(doc.id, doc.data()))
          .toList(growable: false);
}
