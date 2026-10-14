import 'product.dart';

/// Daftar brand yang diturunkan dari dokumen produk.
///
/// Brand pada katalog tidak pernah di-hardcode di widget: pilihan filter brand
/// selalu berasal dari produk aktif yang sedang dibaca, sehingga brand yang
/// sudah tidak dipakai otomatis hilang dan brand baru muncul tanpa perubahan
/// kode.
abstract final class CatalogBrands {
  /// Nama brand unik dari [products], terurut tanpa membedakan besar/kecil
  /// huruf. Brand kosong/spasi dibuang karena tidak dapat dipakai menyaring.
  static List<String> fromProducts(Iterable<Product> products) {
    final brands = <String>{
      for (final product in products)
        if (product.brand.trim().isNotEmpty) product.brand.trim(),
    };
    final sorted = brands.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List<String>.unmodifiable(sorted);
  }
}
