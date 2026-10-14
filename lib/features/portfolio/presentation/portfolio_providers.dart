import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../data/portfolio_repository.dart';
import '../domain/creative.dart';
import '../domain/service_rate.dart';

/// Akses collection `service_rates` dan `creatives`
/// (`docs/BLUEPRINT_APLIKASI.md` §6.6 dan §6.7).
final portfolioRepositoryProvider = Provider<PortfolioRepository>(
  (ref) => PortfolioRepository(ref.watch(firebaseFirestoreProvider)),
);

/// Rate card layanan aktif, terurut `sortOrder`.
///
/// Katalog layanan menampilkan empat kategori layanan dari dokumen ini. Bila
/// collection masih kosong, UI wajib menampilkan keadaan kosong/konten belum
/// dikonfigurasi — bukan kartu layanan rekaan.
final activeServiceRatesProvider = StreamProvider<List<ServiceRate>>(
  (ref) => ref.watch(portfolioRepositoryProvider).watchActiveServiceRates(),
);

/// Kreator aktif, terurut `sortOrder`.
///
/// Halaman jasa menampilkan dua kartu kreator dari data ini; jumlahnya mengikuti
/// dokumen yang benar-benar ada di Firestore.
final activeCreativesProvider = StreamProvider<List<Creative>>(
  (ref) => ref.watch(portfolioRepositoryProvider).watchActiveCreatives(),
);
