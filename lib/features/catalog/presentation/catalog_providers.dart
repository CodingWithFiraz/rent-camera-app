import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../data/banner_repository.dart';
import '../data/category_repository.dart';
import '../data/product_repository.dart';
import '../domain/banner.dart';
import '../domain/banner_selection.dart';
import '../domain/catalog_brands.dart';
import '../domain/catalog_filter.dart';
import '../domain/category.dart';
import '../domain/product.dart';

/// Akses collection `products` (`docs/BLUEPRINT_APLIKASI.md` §6.2).
///
/// Widget katalog membaca data lewat provider ini, bukan lewat
/// `FirebaseFirestore` langsung, supaya filter `isActive` dan pemetaan model
/// tetap berada di satu tempat (repository).
final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(firebaseFirestoreProvider)),
);

/// Akses collection `categories` (§6.1).
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(firebaseFirestoreProvider)),
);

/// Akses collection `banners` (§6.5).
final bannerRepositoryProvider = Provider<BannerRepository>(
  (ref) => BannerRepository(ref.watch(firebaseFirestoreProvider)),
);

/// Produk aktif realtime, opsional disaring satu kategori.
///
/// Kunci family `null` berarti seluruh kategori. Filter `isActive == true`
/// diterapkan pada query di `ProductRepository`, sehingga perubahan admin
/// tercermin tanpa reload. Pencarian dan filter brand digabungkan di lapisan UI
/// pada fase katalog.
final activeProductsProvider = StreamProvider.family<List<Product>, String?>((
  ref,
  categoryId,
) {
  return ref
      .watch(productRepositoryProvider)
      .watchActiveProducts(categoryId: categoryId);
});

/// Satu produk apa adanya, termasuk produk yang sudah diarsipkan.
///
/// Dipakai aksi "Sewa"/checkout untuk membaca ulang harga, status, dan stok
/// dari Firestore sebelum menyusun pesan WhatsApp. `null` berarti dokumen
/// produk sudah tidak ada.
final productByIdProvider = FutureProvider.family<Product?, String>((
  ref,
  productId,
) {
  return ref.watch(productRepositoryProvider).fetchProductById(productId);
});

/// Kategori aktif, terurut `sortOrder`.
final activeCategoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchActiveCategories(),
);

/// Banner aktif, terurut `sortOrder`.
///
/// Blueprint §5 menetapkan katalog memakai tiga banner. Repository mengembalikan
/// seluruh banner aktif; pemotongan menjadi tiga slide dan validasi target
/// navigasi dilakukan UI katalog, bukan di sini.
final activeBannersProvider = StreamProvider<List<Banner>>(
  (ref) => ref.watch(bannerRepositoryProvider).watchActiveBanners(),
);

/// Kriteria pencarian dan filter katalog yang sedang aktif.
///
/// Satu sumber kebenaran untuk kombinasi pencarian + kategori + brand, supaya
/// perubahan dari beberapa tempat (kolom pencarian, chip filter, banner
/// kategori, drawer) tidak saling menimpa tanpa arah.
final catalogFilterProvider =
    NotifierProvider<CatalogFilterNotifier, CatalogFilter>(
      CatalogFilterNotifier.new,
    );

/// Pengelola kriteria pencarian/filter katalog.
class CatalogFilterNotifier extends Notifier<CatalogFilter> {
  @override
  CatalogFilter build() => CatalogFilter.none;

  /// Mengubah kata kunci pencarian tanpa mengosongkan kategori/brand.
  void setQuery(String query) {
    if (state.query == query) {
      return;
    }
    state = state.copyWith(query: query);
  }

  /// Memilih kategori; `null` atau string kosong berarti semua kategori.
  ///
  /// Brand yang sedang dipilih selalu dibuang karena daftar brand mengikuti
  /// kategori terpilih; menyisakan brand dari kategori lain akan menghasilkan
  /// hasil kosong yang membingungkan.
  void selectCategory(String? categoryId) {
    final id = categoryId?.trim() ?? '';
    state = id.isEmpty
        ? state.copyWith(clearCategory: true, clearBrand: true)
        : state.copyWith(categoryId: id, clearBrand: true);
  }

  /// Memilih brand; `null` atau string kosong berarti semua brand.
  void selectBrand(String? brand) {
    final value = brand?.trim() ?? '';
    state = value.isEmpty
        ? state.copyWith(clearBrand: true)
        : state.copyWith(brand: value);
  }

  /// Mengembalikan katalog ke keadaan tanpa kriteria.
  void reset() {
    if (!state.isFiltering) {
      return;
    }
    state = CatalogFilter.none;
  }
}

/// Produk aktif yang lolos pencarian/filter, siap ditampilkan katalog.
///
/// Query Firestore dibatasi kategori terpilih (mengurangi jumlah dokumen yang
/// dibaca), lalu pencarian teks dan filter brand diselesaikan di sisi klien oleh
/// [CatalogFilter]. Nilai `AsyncValue` diteruskan apa adanya agar UI tetap bisa
/// membedakan memuat, error, dan kosong.
final catalogProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final filter = ref.watch(catalogFilterProvider);
  final products = ref.watch(activeProductsProvider(filter.categoryId));
  return products.whenData(filter.apply);
});

/// Nama brand unik pada kategori yang sedang terpilih.
///
/// Diturunkan dari dokumen produk aktif, bukan daftar hardcoded, sehingga
/// berisi daftar kosong selama produk masih dimuat atau belum ada data. Karena
/// kategori ikut diambil dari filter, memilih kategori baru memuat ulang produk
/// dan otomatis mempersempit pilihan brand.
final catalogBrandsProvider = Provider<List<String>>((ref) {
  final filter = ref.watch(catalogFilterProvider);
  // `AsyncValue.value` mengembalikan data terakhir yang diketahui (termasuk saat
  // refresh), dan `null` selama pemuatan pertama atau saat error tanpa data.
  final products = ref.watch(activeProductsProvider(filter.categoryId)).value;
  if (products == null || products.isEmpty) {
    return const <String>[];
  }
  return CatalogBrands.fromProducts(products);
});

/// Slide carousel katalog: maksimal tiga banner aktif beserta status konfigurasi.
///
/// Pemotongan dan pemeriksaan tujuan Portofolio dilakukan di [BannerSelection]
/// (domain) supaya aturan blueprint dapat diuji tanpa Firestore, dan UI hanya
/// merender hasilnya — termasuk saat banner belum dikonfigurasi.
final catalogBannerSelectionProvider = Provider<AsyncValue<BannerSelection>>((
  ref,
) {
  return ref.watch(activeBannersProvider).whenData(BannerSelection.from);
});

/// Nama kategori untuk [categoryId] dari daftar kategori aktif.
///
/// `null` berarti kategori belum dimuat, tidak aktif, atau tidak ada. UI
/// menampilkan ID dokumen apa adanya pada keadaan itu: menebak nama kategori
/// akan menyamarkan data yang sebenarnya belum tersedia.
final categoryNameProvider = Provider.family<String?, String>((
  ref,
  categoryId,
) {
  final id = categoryId.trim();
  if (id.isEmpty) {
    return null;
  }
  final categories = ref.watch(activeCategoriesProvider).value;
  if (categories == null) {
    return null;
  }
  for (final category in categories) {
    if (category.id == id) {
      return category.name;
    }
  }
  return null;
});
