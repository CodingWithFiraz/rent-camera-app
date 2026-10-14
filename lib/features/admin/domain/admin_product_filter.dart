import '../../catalog/domain/product.dart';

/// Penanda tampilan daftar produk pada dashboard admin.
enum AdminProductVisibility {
  /// Produk aktif dan arsip.
  all,

  /// Hanya produk yang tampil di katalog (`isActive == true`).
  active,

  /// Hanya produk yang diarsipkan (`isActive == false`).
  archived,
}

/// Kriteria pencarian/filter daftar produk admin.
///
/// Nilainya murni sehingga pencarian dan filter dapat diuji tanpa Firestore.
class AdminProductFilter {
  const AdminProductFilter({
    this.query = '',
    this.visibility = AdminProductVisibility.all,
  });

  /// Keadaan tanpa kriteria apa pun.
  static const AdminProductFilter none = AdminProductFilter();

  final String query;
  final AdminProductVisibility visibility;

  bool get isFiltering =>
      query.trim().isNotEmpty || visibility != AdminProductVisibility.all;

  AdminProductFilter copyWith({
    String? query,
    AdminProductVisibility? visibility,
  }) => AdminProductFilter(
    query: query ?? this.query,
    visibility: visibility ?? this.visibility,
  );

  /// Menyaring daftar produk; urutan masukan dipertahankan.
  List<Product> apply(List<Product> products) =>
      products.where(matches).toList(growable: false);

  /// `true` bila [product] lolos seluruh kriteria.
  ///
  /// Pencarian mencocokkan nama, brand, dan document ID kategori. Nama kategori
  /// bukan bagian dari dokumen produk, jadi pencocokan nama kategori dikerjakan
  /// pemanggil bila memang dibutuhkan.
  bool matches(Product product) {
    if (visibility == AdminProductVisibility.active && !product.isActive) {
      return false;
    }
    if (visibility == AdminProductVisibility.archived && product.isActive) {
      return false;
    }
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) {
      return true;
    }
    return product.name.toLowerCase().contains(keyword) ||
        product.brand.toLowerCase().contains(keyword) ||
        product.categoryId.toLowerCase().contains(keyword);
  }
}

/// Ringkasan jumlah produk pada dashboard admin.
///
/// Angka di sini dihitung dari dokumen produk yang benar-benar terbaca, bukan
/// analitik atau angka karangan; selama data belum tersedia pemanggil
/// menampilkan keadaan memuat/error.
class AdminProductSummary {
  const AdminProductSummary({
    required this.total,
    required this.active,
    required this.archived,
  });

  factory AdminProductSummary.fromProducts(List<Product> products) {
    var active = 0;
    for (final product in products) {
      if (product.isActive) {
        active += 1;
      }
    }
    return AdminProductSummary(
      total: products.length,
      active: active,
      archived: products.length - active,
    );
  }

  const AdminProductSummary.empty() : total = 0, active = 0, archived = 0;

  final int total;
  final int active;
  final int archived;
}
