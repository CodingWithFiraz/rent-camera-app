import '../../../core/constants/app_constants.dart';
import '../domain/category.dart';

/// Data kategori default yang digunakan aplikasi saat Firestore belum di-seed
/// atau koleksi `categories` masih kosong.
///
/// Memastikan form produk admin (dropdown kategori) dan filter katalog langsung
/// memiliki opsi kategori yang dapat dipilih.
abstract final class DefaultCategoryData {
  static const List<Category> categories = <Category>[
    Category(
      id: 'kamera',
      name: 'Kamera',
      slug: 'kamera',
      description: 'Kamera mirrorless, DSLR, dan kamera sinema.',
      iconKey: CategoryIconKeys.camera,
      sortOrder: 1,
      isActive: true,
    ),
    Category(
      id: 'lensa',
      name: 'Lensa',
      slug: 'lensa',
      description: 'Lensa prime, zoom, dan telefoto.',
      iconKey: CategoryIconKeys.lens,
      sortOrder: 2,
      isActive: true,
    ),
    Category(
      id: 'lighting',
      name: 'Lighting',
      slug: 'lighting',
      description: 'Lampu studio, continuous light, flash, dan panel LED.',
      iconKey: CategoryIconKeys.lighting,
      sortOrder: 3,
      isActive: true,
    ),
    Category(
      id: 'drone',
      name: 'Drone',
      slug: 'drone',
      description: 'Drone rekaman udara dan perlengkapannya.',
      iconKey: CategoryIconKeys.drone,
      sortOrder: 4,
      isActive: true,
    ),
    Category(
      id: 'mic',
      name: 'Mic',
      slug: 'mic',
      description: 'Mikrofon wireless, shotgun mic, dan clip-on lavalier.',
      iconKey: CategoryIconKeys.mic,
      sortOrder: 5,
      isActive: true,
    ),
    Category(
      id: 'tripod',
      name: 'Tripod',
      slug: 'tripod',
      description: 'Tripod, monopod, gimbal, dan fluid head.',
      iconKey: CategoryIconKeys.tripod,
      sortOrder: 6,
      isActive: true,
    ),
    Category(
      id: 'sd_card',
      name: 'SD Card',
      slug: 'sd-card',
      description:
          'Kartu memori SD card, microSD, dan CFexpress kecepatan tinggi.',
      iconKey: CategoryIconKeys.sdCard,
      sortOrder: 7,
      isActive: true,
    ),
  ];
}
