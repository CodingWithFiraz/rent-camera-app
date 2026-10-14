import '../../../core/constants/app_constants.dart';
import '../../../core/utils/firestore_document_reader.dart';
import 'price_unit.dart';

/// Model dokumen `products/{productId}` (`docs/BLUEPRINT_APLIKASI.md` §6.2).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.brand,
    required this.price,
    this.description = '',
    this.priceUnit = PriceUnit.unspecified,
    this.stockQuantity = 0,
    this.imageUrls = const <String>[],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Document ID pada `products`; juga dipakai sebagai ID cart item.
  final String id;

  final String name;
  final String description;

  /// Document ID kategori pada `categories`.
  final String categoryId;

  final String brand;

  /// Harga dalam integer Rupiah (bukan double, bukan string berformat).
  final int price;

  /// Satuan periode harga; [PriceUnit.unspecified] berarti belum ditetapkan.
  final PriceUnit priceUnit;

  /// Stok terverifikasi, integer >= 0.
  final int stockQuantity;

  /// Daftar URL foto; MVP menampilkan foto pertama sebagai foto utama.
  final List<String> imageUrls;

  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Foto utama (foto pertama) atau `null` bila produk belum punya foto.
  String? get primaryImageUrl => imageUrls.isEmpty ? null : imageUrls.first;

  /// `true` bila produk tampil di katalog dan masih bisa disewa.
  bool get isInStock => isActive && stockQuantity > 0;

  /// `true` bila label periode boleh ditampilkan ke pengguna.
  bool get hasConfiguredPriceUnit => priceUnit.isConfigured;

  /// Batas maksimum quantity yang boleh diminta untuk produk ini.
  ///
  /// Nilai ini hanya batas atas berbasis data produk; validasi akhir stok
  /// tetap dilakukan saat add-to-cart dan checkout.
  int get maxOrderableQuantity => stockQuantity < 0 ? 0 : stockQuantity;

  /// Membaca dokumen Firestore dengan validasi field.
  ///
  /// Field wajib: `name`, `categoryId`, `brand`, `price` (integer >= 0),
  /// `stockQuantity` (integer >= 0). Dokumen dengan harga bertipe pecahan atau
  /// teks ditolak: harga harus integer Rupiah.
  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    final reader = FirestoreDocumentReader(
      documentPath: '${FirestoreCollections.products}/$id',
      data: data,
    );
    return Product(
      id: id,
      name: reader.requireNonEmptyString(ProductFields.name),
      description: reader.optionalString(ProductFields.description),
      categoryId: reader.requireNonEmptyString(ProductFields.categoryId),
      brand: reader.requireNonEmptyString(ProductFields.brand),
      price: reader.requireNonNegativeInt(ProductFields.price),
      // Satuan periode bersifat opsional: dokumen lama/nilai tak dikenal tidak
      // boleh berubah menjadi klaim periode tertentu.
      priceUnit: PriceUnit.fromStorage(data[ProductFields.priceUnit]),
      stockQuantity: reader.requireNonNegativeInt(ProductFields.stockQuantity),
      imageUrls: reader.optionalStringList(ProductFields.imageUrls),
      isActive: reader.optionalBool(ProductFields.isActive, fallback: true),
      createdAt: reader.optionalDateTime(ProductFields.createdAt),
      updatedAt: reader.optionalDateTime(ProductFields.updatedAt),
    );
  }

  @override
  String toString() => 'Product($id, $name)';
}
