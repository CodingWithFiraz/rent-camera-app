import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/creative.dart';
import '../domain/service_rate.dart';
import 'default_portfolio_data.dart';

/// Akses collection `service_rates` dan `creatives`
/// (`docs/BLUEPRINT_APLIKASI.md` §6.6 dan §6.7).
///
/// Kedua collection dibaca oleh halaman Portfolio & Services.
/// Jika collection di Firestore belum diisi atau sedang offline,
/// repository secara otomatis menyediakan [DefaultPortfolioData] agar
/// halaman tetap menampilkan data rate card dan kreator yang sudah dirancang.
class PortfolioRepository {
  PortfolioRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _serviceRates =>
      _firestore.collection(FirestoreCollections.serviceRates);

  CollectionReference<Map<String, dynamic>> get _creatives =>
      _firestore.collection(FirestoreCollections.creatives);

  /// Stream rate card layanan aktif, terurut `sortOrder`.
  ///
  /// Secara langsung memancarkan [DefaultPortfolioData.serviceRates] sebagai
  /// data awal, kemudian mendengarkan pembaruan realtime dari Firestore bila ada.
  Stream<List<ServiceRate>> watchActiveServiceRates() async* {
    yield DefaultPortfolioData.serviceRates;
    try {
      await for (final snapshot in _serviceRates.snapshots()) {
        final items =
            _mapServiceRateSnapshot(snapshot)
                .where((rate) => rate.isActive)
                .toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        if (items.isNotEmpty) {
          yield items;
        } else {
          yield DefaultPortfolioData.serviceRates;
        }
      }
    } catch (_) {
      // Pertahankan data default jika stream Firestore mengalami kendala.
    }
  }

  /// Versi sekali-baca dari [watchActiveServiceRates].
  Future<List<ServiceRate>> fetchActiveServiceRates() async {
    try {
      final snapshot = await _serviceRates.get();
      final items =
          _mapServiceRateSnapshot(snapshot)
              .where((rate) => rate.isActive)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (items.isNotEmpty) {
        return items;
      }
      return DefaultPortfolioData.serviceRates;
    } catch (_) {
      return DefaultPortfolioData.serviceRates;
    }
  }

  /// Stream kreator aktif, terurut `sortOrder`.
  ///
  /// Secara langsung memancarkan [DefaultPortfolioData.creatives] sebagai
  /// data awal, kemudian mendengarkan pembaruan realtime dari Firestore bila ada.
  Stream<List<Creative>> watchActiveCreatives() async* {
    yield DefaultPortfolioData.creatives;
    try {
      await for (final snapshot in _creatives.snapshots()) {
        final items =
            _mapCreativeSnapshot(snapshot)
                .where((creative) => creative.isActive)
                .toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        if (items.isNotEmpty) {
          yield items;
        } else {
          yield DefaultPortfolioData.creatives;
        }
      }
    } catch (_) {
      // Pertahankan data default jika stream Firestore mengalami kendala.
    }
  }

  /// Versi sekali-baca dari [watchActiveCreatives].
  Future<List<Creative>> fetchActiveCreatives() async {
    try {
      final snapshot = await _creatives.get();
      final items =
          _mapCreativeSnapshot(snapshot)
              .where((creative) => creative.isActive)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (items.isNotEmpty) {
        return items;
      }
      return DefaultPortfolioData.creatives;
    } catch (_) {
      return DefaultPortfolioData.creatives;
    }
  }

  /// Menuliskan data contoh ke Firestore jika collection masih kosong.
  /// Bersifat idempotent dan aman dipanggil saat inisialisasi aplikasi.
  Future<void> seedDefaultDataIfEmpty() async {
    try {
      final rateSnapshot = await _serviceRates.limit(1).get();
      if (rateSnapshot.docs.isEmpty) {
        for (final rate in DefaultPortfolioData.serviceRates) {
          await _serviceRates.doc(rate.id).set(<String, dynamic>{
            ServiceRateFields.title: rate.title,
            ServiceRateFields.description: rate.description,
            ServiceRateFields.rateLabel: rate.rateLabel,
            ServiceRateFields.startingPrice: rate.startingPrice,
            ServiceRateFields.priceUnit: rate.priceUnit.storageValue,
            ServiceRateFields.deliverables: rate.deliverables,
            ServiceRateFields.sortOrder: rate.sortOrder,
            ServiceRateFields.isActive: rate.isActive,
            'isSample': true,
          }, SetOptions(merge: true));
        }
      }

      final creativeSnapshot = await _creatives.limit(1).get();
      if (creativeSnapshot.docs.isEmpty) {
        for (final creative in DefaultPortfolioData.creatives) {
          await _creatives.doc(creative.id).set(<String, dynamic>{
            CreativeFields.name: creative.name,
            CreativeFields.roleTitle: creative.roleTitle,
            CreativeFields.specialties: creative.specialties,
            CreativeFields.photoUrl: creative.photoUrl,
            CreativeFields.portfolioUrl: creative.portfolioUrl,
            CreativeFields.sortOrder: creative.sortOrder,
            CreativeFields.isActive: creative.isActive,
            'isSample': true,
          }, SetOptions(merge: true));
        }
      }
    } catch (_) {
      // Best-effort: jika security rules membatasi penulisan klien,
      // aplikasi tetap menampilkan data default lewat watchActive* tanpa error.
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
