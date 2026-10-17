import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/banner.dart';

/// Akses collection `banners` (`docs/BLUEPRINT_APLIKASI.md` §6.5).
///
/// Carousel katalog memakai stream ini; UI bertanggung jawab membatasi jumlah
/// slide dan memvalidasi [Banner.hasNavigableTarget] sebelum navigasi.
class BannerRepository {
  BannerRepository([FirebaseFirestore? _]);

  /// Daftar banner lokal statis untuk katalog utama.
  static const List<Banner> defaultBanners = <Banner>[
    Banner(
      id: 'banner_promo_kamera',
      title: 'Sewa Kamera & Lensa Terbaik untuk Karya Terbaikmu',
      imageUrl:
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=1200&q=80',
      targetType: BannerTargetType.category,
      targetValue: 'kamera',
      sortOrder: 1,
      isActive: true,
    ),
    Banner(
      id: 'banner_portofolio_layanan',
      title: 'Layanan Foto & Video Kreator Profesional',
      imageUrl:
          'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?auto=format&fit=crop&w=1200&q=80',
      targetType: BannerTargetType.portfolio,
      targetValue: '',
      sortOrder: 2,
      isActive: true,
    ),
    Banner(
      id: 'banner_lighting_studio',
      title: 'Perlengkapan Studio & Lighting Lengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1588780984956-4084437d2f64?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=NHwxMjA3fDA%3D',
      targetType: BannerTargetType.category,
      targetValue: 'lighting',
      sortOrder: 3,
      isActive: true,
    ),
  ];

  /// Mengembalikan stream banner lokal statis tanpa mengakses Firebase.
  Stream<List<Banner>> watchActiveBanners() =>
      Stream<List<Banner>>.value(defaultBanners);

  /// Versi sekali-baca dari [watchActiveBanners].
  Future<List<Banner>> fetchActiveBanners() async => defaultBanners;
}
