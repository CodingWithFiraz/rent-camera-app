import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/repository_error_mapper.dart';
import '../domain/creative.dart';
import '../domain/service_rate.dart';

/// Akses collection `service_rates` dan `creatives`
/// (`docs/BLUEPRINT_APLIKASI.md` §6.6 dan §6.7).
///
/// Halaman Portfolio & Services hanya menampilkan dokumen yang benar-benar ada
/// di Firestore. Repository ini **tidak** menyediakan data contoh maupun nilai
/// pengganti: rate final, foto kreator, dan tautan portofolio adalah data milik
/// pemilik aplikasi (blueprint §1 dan §6.6), sehingga collection yang masih
/// kosong harus tampil sebagai keadaan "belum dikonfigurasi" — bukan angka,
/// foto, atau tautan rekaan yang tampak nyata.
///
/// Data contoh untuk pengembangan hanya ditulis oleh skrip Admin SDK
/// `scripts/seed_sample_data.mjs` (dijalankan pemilik di lingkungan tepercaya,
/// setiap dokumennya ditandai `isSample: true`). Aplikasi Flutter tidak pernah
/// menulis dokumen contoh: penulisan dari klien akan ditolak Security Rules
/// karena pengguna biasa bukan admin.
class PortfolioRepository {
  PortfolioRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _entityLabel = 'layanan';

  CollectionReference<Map<String, dynamic>> get _serviceRates =>
      _firestore.collection(FirestoreCollections.serviceRates);

  CollectionReference<Map<String, dynamic>> get _creatives =>
      _firestore.collection(FirestoreCollections.creatives);

  /// Stream rate card aktif, terurut `sortOrder`.
  ///
  /// Penyaringan `isActive` dan pengurutan dilakukan di klien supaya tidak
  /// memerlukan composite index. Collection kosong menghasilkan daftar kosong,
  /// dan daftar itulah yang membuat halaman menampilkan keadaan belum
  /// dikonfigurasi.
  Stream<List<ServiceRate>> watchActiveServiceRates() => guardRepositoryStream(
    _serviceRates.snapshots().map(_mapServiceRateSnapshot),
    entityLabel: _entityLabel,
  ).map(_activeServiceRates);

  /// Versi sekali-baca dari [watchActiveServiceRates].
  Future<List<ServiceRate>> fetchActiveServiceRates() async {
    try {
      return _activeServiceRates(
        _mapServiceRateSnapshot(await _serviceRates.get()),
      );
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  /// Stream kreator aktif, terurut `sortOrder`.
  Stream<List<Creative>> watchActiveCreatives() => guardRepositoryStream(
    _creatives.snapshots().map(_mapCreativeSnapshot),
    entityLabel: _entityLabel,
  ).map(_activeCreatives);

  /// Versi sekali-baca dari [watchActiveCreatives].
  Future<List<Creative>> fetchActiveCreatives() async {
    try {
      return _activeCreatives(_mapCreativeSnapshot(await _creatives.get()));
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  List<ServiceRate> _activeServiceRates(List<ServiceRate> rates) {
    final items = rates
        .where((ServiceRate rate) => rate.isActive)
        .toList(growable: true)
      ..sort(
        (ServiceRate a, ServiceRate b) => a.sortOrder.compareTo(b.sortOrder),
      );
    return List<ServiceRate>.unmodifiable(items);
  }

  List<Creative> _activeCreatives(List<Creative> creatives) {
    final items = creatives
        .where((Creative creative) => creative.isActive)
        .toList(growable: true)
      ..sort(
        (Creative a, Creative b) => a.sortOrder.compareTo(b.sortOrder),
      );
    return List<Creative>.unmodifiable(items);
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
