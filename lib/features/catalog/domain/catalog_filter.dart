import 'product.dart';

/// Kriteria pencarian dan filter katalog.
///
/// Dipisahkan dari widget supaya aturan pencarian dapat diuji tanpa membangun
/// UI: teks pencarian, kategori, dan brand digabungkan (AND) — produk hanya
/// tampil bila memenuhi semua kriteria yang aktif. Nilai `null` pada kategori/
/// brand berarti kriteria tersebut tidak dipakai.
class CatalogFilter {
  const CatalogFilter({this.query = '', this.categoryId, this.brand});

  /// Kriteria kosong: seluruh produk aktif ditampilkan tanpa penyaringan.
  static const CatalogFilter none = CatalogFilter();

  /// Teks pencarian apa adanya, dipakai untuk mengisi ulang kolom pencarian.
  final String query;

  /// Document ID kategori terpilih; `null` berarti semua kategori.
  final String? categoryId;

  /// Nama brand terpilih; `null` berarti semua brand.
  final String? brand;

  /// Teks pencarian yang sudah dinormalisasi (dibuang spasi tepi, huruf kecil).
  String get normalizedQuery => query.trim().toLowerCase();

  bool get hasQuery => normalizedQuery.isNotEmpty;
  bool get hasCategory => (categoryId ?? '').trim().isNotEmpty;
  bool get hasBrand => (brand ?? '').trim().isNotEmpty;

  /// `true` bila minimal satu kriteria aktif, sehingga tombol "Hapus filter"
  /// relevan ditampilkan.
  bool get isFiltering => hasQuery || hasCategory || hasBrand;

  /// Menyalin kriteria dengan nilai baru.
  ///
  /// [clearCategory] dan [clearBrand] diperlukan karena `null` pada [categoryId]
  /// atau [brand] berarti "nilai tidak diubah", bukan "dikosongkan".
  CatalogFilter copyWith({
    String? query,
    String? categoryId,
    String? brand,
    bool clearCategory = false,
    bool clearBrand = false,
  }) {
    return CatalogFilter(
      query: query ?? this.query,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      brand: clearBrand ? null : (brand ?? this.brand),
    );
  }

  /// `true` bila [product] memenuhi seluruh kriteria yang aktif.
  bool matches(Product product) {
    if (hasCategory && product.categoryId.trim() != categoryId!.trim()) {
      return false;
    }
    if (hasBrand && product.brand.trim().toLowerCase() != _normalizedBrand) {
      return false;
    }
    if (hasQuery && !_matchesQuery(product)) {
      return false;
    }
    return true;
  }

  String get _normalizedBrand => (brand ?? '').trim().toLowerCase();

  /// Pencarian sederhana pada nama, brand, dan deskripsi.
  ///
  /// Kategori sengaja tidak diikutkan karena kategori sudah punya filter
  /// tersendiri; mengetik "kamera" tidak boleh menampilkan seluruh isi kategori
  /// kamera.
  bool _matchesQuery(Product product) {
    final needle = normalizedQuery;
    return product.name.toLowerCase().contains(needle) ||
        product.brand.toLowerCase().contains(needle) ||
        product.description.toLowerCase().contains(needle);
  }

  /// Menyaring [products] dan mengurutkannya berdasarkan nama.
  ///
  /// Urutan mengikuti nama (tanpa membedakan besar/kecil huruf, lalu nama asli
  /// sebagai pemecah seri) supaya posisi kartu tidak berubah-ubah saat stream
  /// Firestore mengirim daftar baru.
  List<Product> apply(Iterable<Product> products) {
    final filtered = products.where(matches).toList();
    filtered.sort((a, b) {
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return byName != 0 ? byName : a.name.compareTo(b.name);
    });
    return List<Product>.unmodifiable(filtered);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CatalogFilter &&
        other.query == query &&
        other.categoryId == categoryId &&
        other.brand == brand;
  }

  @override
  int get hashCode => Object.hash(query, categoryId, brand);

  @override
  String toString() =>
      'CatalogFilter(query: $query, categoryId: $categoryId, brand: $brand)';
}
