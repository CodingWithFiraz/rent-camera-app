/// Nama collection Firestore yang dipakai aplikasi.
///
/// Sumber: `docs/BLUEPRINT_APLIKASI.md` §6. Collection lain ditambahkan pada
/// fase yang memperkenalkan repository-nya, supaya tidak ada nama collection
/// yang tersebar sebagai string literal di widget.
abstract final class FirestoreCollections {
  /// `users/{uid}`
  static const String users = 'users';

  /// `users/{uid}/cart_items/{productId}` — satu dokumen per produk.
  static const String cartItems = 'cart_items';

  /// `categories/{categoryId}`
  static const String categories = 'categories';

  /// `products/{productId}`
  static const String products = 'products';

  /// `banners/{bannerId}`
  static const String banners = 'banners';

  /// `service_rates/{serviceId}`
  static const String serviceRates = 'service_rates';

  /// `creatives/{creativeId}`
  static const String creatives = 'creatives';
}

/// Nama field dokumen `users/{uid}` (`docs/BLUEPRINT_APLIKASI.md` §6.3).
///
/// Field role/claim admin **tidak** ada di sini dengan sengaja: role admin
/// hanya berasal dari custom claim Firebase Authentication.
abstract final class UserProfileFields {
  static const String displayName = 'displayName';
  static const String email = 'email';
  static const String phoneNumber = 'phoneNumber';
  static const String photoUrl = 'photoUrl';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';

  /// Field yang **tidak** boleh dipakai sebagai sumber otoritas admin.
  ///
  /// Blueprint §6.3: role admin hanya berasal dari custom claim Firebase Auth.
  /// Dokumen profil yang memuat field ini diabaikan, bukan dipercaya.
  static const List<String> nonAuthoritativeRoleFields = <String>[
    'role',
    'admin',
    'isAdmin',
    'claims',
  ];
}

/// Nama field dokumen `categories/{categoryId}` (§6.1).
abstract final class CategoryFields {
  static const String name = 'name';
  static const String slug = 'slug';
  static const String description = 'description';
  static const String iconKey = 'iconKey';
  static const String sortOrder = 'sortOrder';
  static const String isActive = 'isActive';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

/// Kunci ikon kategori yang dikenal aplikasi (`categories.iconKey`).
///
/// Blueprint §6.1: `iconKey` dipetakan ke ikon yang dikenal aplikasi, bukan
/// nama class yang dieksekusi dinamis. Nilai kosong/tak dikenal jatuh ke
/// [defaultKey] supaya dokumen lama tidak membuat katalog gagal dirender.
abstract final class CategoryIconKeys {
  static const String camera = 'camera';
  static const String lens = 'lens';
  static const String flash = 'flash';
  static const String lighting = 'lighting';
  static const String drone = 'drone';
  static const String microphone = 'microphone';
  static const String mic = 'mic';
  static const String stabilizer = 'stabilizer';
  static const String tripod = 'tripod';
  static const String sdCard = 'sd_card';
  static const String accessory = 'accessory';

  /// Dipakai bila `iconKey` kosong atau tidak dikenal.
  static const String defaultKey = 'category';

  /// Semua kunci yang boleh dipakai seed/admin.
  static const List<String> known = <String>[
    camera,
    lens,
    flash,
    lighting,
    drone,
    microphone,
    mic,
    stabilizer,
    tripod,
    sdCard,
    accessory,
    defaultKey,
  ];

  static bool isKnown(String? iconKey) => known.contains(iconKey);
}

/// Nama field dokumen `products/{productId}` (§6.2).
abstract final class ProductFields {
  static const String name = 'name';
  static const String description = 'description';
  static const String categoryId = 'categoryId';
  static const String brand = 'brand';
  static const String price = 'price';
  static const String priceUnit = 'priceUnit';
  static const String stockQuantity = 'stockQuantity';
  static const String imageUrls = 'imageUrls';
  static const String isActive = 'isActive';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

/// Nama field dokumen `banners/{bannerId}` (§6.5).
abstract final class BannerFields {
  static const String title = 'title';
  static const String imageUrl = 'imageUrl';
  static const String targetType = 'targetType';
  static const String targetValue = 'targetValue';
  static const String sortOrder = 'sortOrder';
  static const String isActive = 'isActive';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

/// Nama field dokumen `service_rates/{serviceId}` (§6.6).
abstract final class ServiceRateFields {
  static const String title = 'title';
  static const String description = 'description';
  static const String rateLabel = 'rateLabel';
  static const String startingPrice = 'startingPrice';
  static const String priceUnit = 'priceUnit';
  static const String deliverables = 'deliverables';
  static const String sortOrder = 'sortOrder';
  static const String isActive = 'isActive';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

/// Nama field dokumen `creatives/{creativeId}` (§6.7).
abstract final class CreativeFields {
  static const String name = 'name';
  static const String roleTitle = 'roleTitle';
  static const String specialties = 'specialties';
  static const String photoUrl = 'photoUrl';
  static const String portfolioUrl = 'portfolioUrl';
  static const String sortOrder = 'sortOrder';
  static const String isActive = 'isActive';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

/// Path dasar berkas pada Firebase Storage.
///
/// Dipakai bersama `firebase/storage.rules`: rules hanya mengizinkan admin
/// menulis `products/**`, `banners/**`, dan `creatives/**`, serta pemilik UID
/// menulis `profiles/{uid}/**`. Nama folder di sini harus sama dengan aturan
/// pada `firebase/storage.rules`; bila salah satu diubah, ubah keduanya.
abstract final class StoragePaths {
  /// Foto produk: `products/{productId}/{fileName}`.
  static const String products = 'products';

  /// Gambar banner: `banners/{bannerId}/{fileName}`.
  static const String banners = 'banners';

  /// Foto kreator: `creatives/{creativeId}/{fileName}`.
  static const String creatives = 'creatives';

  /// Foto profil: `profiles/{uid}/{fileName}`.
  static const String profiles = 'profiles';

  /// Path satu foto produk pada Storage.
  static String productImage(String productId, String fileName) =>
      '$products/${productId.trim()}/$fileName';

  /// Path satu gambar banner pada Storage.
  static String bannerImage(String bannerId, String fileName) =>
      '$banners/${bannerId.trim()}/$fileName';

  /// Path satu foto kreator pada Storage.
  static String creativePhoto(String creativeId, String fileName) =>
      '$creatives/${creativeId.trim()}/$fileName';

  /// Path foto profil milik [uid].
  static String profilePhoto(String uid, String fileName) =>
      '$profiles/${uid.trim()}/$fileName';
}

/// Batas unggahan berkas gambar.
///
/// Nilai ini mengikuti `firebase/storage.rules` (5 MB per berkas). UI wajib
/// memvalidasi sebelum mengunggah supaya pengguna tidak menunggu transfer yang
/// pasti ditolak rules.
abstract final class UploadLimits {
  /// Ukuran maksimum satu berkas gambar: 5 MB.
  static const int maxImageSizeBytes = 5 * 1024 * 1024;
}

/// Nama field dokumen `users/{uid}/cart_items/{productId}` (§6.4).
abstract final class CartItemFields {
  static const String productId = 'productId';
  static const String productNameSnapshot = 'productNameSnapshot';
  static const String brandSnapshot = 'brandSnapshot';
  static const String imageUrlSnapshot = 'imageUrlSnapshot';
  static const String unitPriceSnapshot = 'unitPriceSnapshot';
  static const String priceUnitSnapshot = 'priceUnitSnapshot';
  static const String quantity = 'quantity';
  static const String updatedAt = 'updatedAt';
}
