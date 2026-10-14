import '../../catalog/domain/price_unit.dart';
import '../../catalog/domain/product.dart';

/// Nilai produk yang sudah divalidasi dan siap ditulis ke `products/{productId}`.
///
/// Kelas ini murni (tanpa Firebase) supaya form admin, repository, dan test
/// memakai susunan nilai yang sama.
class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.description,
    required this.categoryId,
    required this.brand,
    required this.price,
    required this.priceUnit,
    required this.stockQuantity,
    required this.imageUrls,
    required this.isActive,
  });

  /// Menyusun draft dari dokumen produk yang sudah ada (form edit).
  factory ProductDraft.fromProduct(Product product) => ProductDraft(
    name: product.name,
    description: product.description,
    categoryId: product.categoryId,
    brand: product.brand,
    price: product.price,
    priceUnit: product.priceUnit,
    stockQuantity: product.stockQuantity,
    imageUrls: product.imageUrls,
    isActive: product.isActive,
  );

  final String name;
  final String description;

  /// Document ID kategori pada `categories`; wajib mengarah ke kategori nyata.
  final String categoryId;

  final String brand;

  /// Harga integer Rupiah (>= 0). Nilai `0` berarti harga belum diisi.
  final int price;

  /// Satuan periode; [PriceUnit.unspecified] berarti belum ditetapkan pemilik
  /// (katalog tidak akan menampilkan label periode apa pun).
  final PriceUnit priceUnit;

  final int stockQuantity;

  /// Daftar URL foto; foto pertama dipakai sebagai foto utama.
  final List<String> imageUrls;

  final bool isActive;

  ProductDraft copyWith({
    String? name,
    String? description,
    String? categoryId,
    String? brand,
    int? price,
    PriceUnit? priceUnit,
    int? stockQuantity,
    List<String>? imageUrls,
    bool? isActive,
  }) => ProductDraft(
    name: name ?? this.name,
    description: description ?? this.description,
    categoryId: categoryId ?? this.categoryId,
    brand: brand ?? this.brand,
    price: price ?? this.price,
    priceUnit: priceUnit ?? this.priceUnit,
    stockQuantity: stockQuantity ?? this.stockQuantity,
    imageUrls: imageUrls ?? this.imageUrls,
    isActive: isActive ?? this.isActive,
  );

  @override
  String toString() => 'ProductDraft($name)';
}

/// Validasi nilai form produk (murni, tanpa Firebase).
///
/// Seluruh pesan berbahasa Indonesia dan siap ditampilkan pada form. Batas atas
/// harga/stok adalah pengaman salah ketik; aturan blueprint yang wajib adalah
/// harga dan stok berupa integer `>= 0`.
abstract final class ProductDraftValidation {
  static const int minNameLength = 3;
  static const int maxNameLength = 80;
  static const int maxBrandLength = 40;
  static const int maxDescriptionLength = 600;
  static const int maxPrice = 1000000000;
  static const int maxStockQuantity = 999;

  /// Karakter yang boleh muncul pada nilai angka: digit beserta pemisah ribuan.
  static final RegExp _amountPattern = RegExp(r'^[0-9.,\s]+$');

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Nama alat wajib diisi.';
    }
    if (text.length < minNameLength) {
      return 'Nama alat minimal $minNameLength karakter.';
    }
    if (text.length > maxNameLength) {
      return 'Nama alat maksimal $maxNameLength karakter.';
    }
    return null;
  }

  static String? brand(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Brand wajib diisi.';
    }
    if (text.length > maxBrandLength) {
      return 'Brand maksimal $maxBrandLength karakter.';
    }
    return null;
  }

  /// Kategori wajib dipilih dari daftar `categories`, bukan diketik bebas.
  static String? categoryId(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Kategori wajib dipilih.';
    }
    return null;
  }

  /// Deskripsi bersifat opsional; hanya panjangnya dibatasi.
  static String? description(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > maxDescriptionLength) {
      return 'Deskripsi maksimal $maxDescriptionLength karakter.';
    }
    return null;
  }

  static String? price(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Harga wajib diisi.';
    }
    if (text.contains('-')) {
      return 'Harga tidak boleh negatif.';
    }
    if (!_amountPattern.hasMatch(text)) {
      return 'Harga hanya boleh berisi angka (tanpa "Rp" atau huruf).';
    }
    final amount = tryParseInteger(text);
    if (amount == null) {
      return 'Harga harus berupa angka Rupiah.';
    }
    if (amount > maxPrice) {
      return 'Harga melebihi batas wajar. Periksa kembali angkanya.';
    }
    return null;
  }

  static String? stockQuantity(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Stok wajib diisi.';
    }
    if (text.contains('-')) {
      return 'Stok tidak boleh negatif.';
    }
    if (!_amountPattern.hasMatch(text)) {
      return 'Stok harus berupa angka.';
    }
    final amount = tryParseInteger(text);
    if (amount == null) {
      return 'Stok harus berupa angka.';
    }
    if (amount > maxStockQuantity) {
      return 'Stok maksimal $maxStockQuantity unit.';
    }
    return null;
  }

  /// Bilangan bulat dari teks yang boleh memuat pemisah ribuan (`150.000`).
  ///
  /// `null` berarti teks kosong, memuat karakter selain angka/pemisah, atau
  /// bernilai negatif.
  static int? tryParseInteger(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty || text.contains('-') || !_amountPattern.hasMatch(text)) {
      return null;
    }
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return null;
    }
    return int.tryParse(digits);
  }
}
