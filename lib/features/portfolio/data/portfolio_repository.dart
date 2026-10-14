import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/repository_error_mapper.dart';
import '../domain/creative.dart';
import '../domain/service_rate.dart';

/// Akses collection `service_rates` dan `creatives`
/// (`docs/BLUEPRINT_APLIKASI.md` §6.6 dan §6.7).
///
/// Kedua collection dibaca oleh halaman Portfolio & Services.
class PortfolioRepository {
  PortfolioRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _serviceRateLabel = 'rate card layanan';
  static const String _creativeLabel = 'kreator';

  CollectionReference<Map<String, dynamic>> get _serviceRates =>
      _firestore.collection(FirestoreCollections.serviceRates);

  CollectionReference<Map<String, dynamic>> get _creatives =>
      _firestore.collection(FirestoreCollections.creatives);

  /// Stream rate card layanan aktif, terurut `sortOrder`.
  Stream<List<ServiceRate>> watchActiveServiceRates() {
    final Query<Map<String, dynamic>> query = _serviceRates
        .where(ServiceRateFields.isActive, isEqualTo: true)
        .orderBy(ServiceRateFields.sortOrder);
    return guardRepositoryStream(
      query.snapshots().map(_mapServiceRateSnapshot),
      entityLabel: _serviceRateLabel,
    );
  }

  /// Versi sekali-baca dari [watchActiveServiceRates].
  Future<List<ServiceRate>> fetchActiveServiceRates() async {
    try {
      final Query<Map<String, dynamic>> query = _serviceRates
          .where(ServiceRateFields.isActive, isEqualTo: true)
          .orderBy(ServiceRateFields.sortOrder);
      return _mapServiceRateSnapshot(await query.get());
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _serviceRateLabel);
    }
  }

  /// Stream kreator aktif, terurut `sortOrder`.
  Stream<List<Creative>> watchActiveCreatives() {
    final Query<Map<String, dynamic>> query = _creatives
        .where(CreativeFields.isActive, isEqualTo: true)
        .orderBy(CreativeFields.sortOrder);
    return guardRepositoryStream(
      query.snapshots().map(_mapCreativeSnapshot),
      entityLabel: _creativeLabel,
    );
  }

  /// Versi sekali-baca dari [watchActiveCreatives].
  Future<List<Creative>> fetchActiveCreatives() async {
    try {
      final Query<Map<String, dynamic>> query = _creatives
          .where(CreativeFields.isActive, isEqualTo: true)
          .orderBy(CreativeFields.sortOrder);
      return _mapCreativeSnapshot(await query.get());
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _creativeLabel);
    }
  }

  List<ServiceRate> _mapServiceRateSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => snapshot.docs
      .map((doc) => ServiceRate.fromFirestore(doc.id, doc.data()))
      .toList(growable: false);

  List<Creative> _mapCreativeSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => snapshot.docs
      .map((doc) => Creative.fromFirestore(doc.id, doc.data()))
      .toList(growable: false);
}
