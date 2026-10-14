import '../../../core/constants/app_constants.dart';
import '../../../core/errors/firestore_data_exception.dart';
import '../../../core/utils/firestore_document_reader.dart';
import '../../catalog/domain/price_unit.dart';
import '../../catalog/domain/product.dart';

/// Model dokumen `users/{uid}/cart_items/{productId}`
/// (`docs/BLUEPRINT_APLIKASI.md` §6.4).
///
/// Document ID = `productId`, sehingga satu produk hanya punya satu baris cart.
/// Field snapshot dipakai agar tampilan keranjang tetap stabil; saat checkout,
/// harga/status produk dibaca ulang dari Firestore (lihat fase cart).
class CartItem {
  const CartItem({
    required this.productId,
    required this.unitPriceSnapshot,
    required this.quantity,
    this.productNameSnapshot = '',
    this.brandSnapshot = '',
    this.imageUrlSnapshot = '',
    this.priceUnitSnapshot = PriceUnit.unspecified,
    this.updatedAt,
  });

  /// Document ID sekaligus ID produk.
  final String productId;

  /// Nama produk saat ditambahkan ke keranjang.
  final String productNameSnapshot;

  /// Brand produk saat ditambahkan ke keranjang.
  final String brandSnapshot;

  /// URL foto utama saat ditambahkan ke keranjang.
  final String imageUrlSnapshot;

  /// Harga satuan (integer Rupiah) saat ditambahkan ke keranjang.
  final int unitPriceSnapshot;

  /// Satuan periode harga saat ditambahkan ke keranjang.
  final PriceUnit priceUnitSnapshot;

  /// Jumlah yang diminta; integer >= 1.
  final int quantity;

  final DateTime? updatedAt;

  /// Batas quantity per item, sejalan dengan Security Rules.
  static const int maxQuantity = 999;

  /// `true` bila quantity berada pada rentang yang sah.
  bool get hasValidQuantity => quantity >= 1 && quantity <= maxQuantity;

  /// Subtotal integer Rupiah: harga satuan x quantity.
  int get subtotal => unitPriceSnapshot * quantity;

  /// `true` bila label periode boleh ditampilkan.
  bool get hasConfiguredPriceUnit => priceUnitSnapshot.isConfigured;

  /// Membaca dokumen Firestore dengan validasi field.
  ///
  /// Field wajib: `unitPriceSnapshot` (integer >= 0) dan `quantity`
  /// (integer >= 1). `productId` diverifikasi sama dengan document ID supaya
  /// baris cart tidak menunjuk produk lain.
  factory CartItem.fromFirestore(String productId, Map<String, dynamic> data) {
    final reader = FirestoreDocumentReader(
      documentPath: '${FirestoreCollections.cartItems}/$productId',
      data: data,
    );

    final storedProductId = reader.optionalString(
      CartItemFields.productId,
      fallback: productId,
    );
    if (storedProductId.trim().isNotEmpty &&
        storedProductId.trim() != productId) {
      throw FirestoreDataException(
        documentPath: '${FirestoreCollections.cartItems}/$productId',
        field: CartItemFields.productId,
        reason: 'tidak cocok dengan document ID baris keranjang',
      );
    }

    final quantity = data[CartItemFields.quantity];
    if (quantity is! int) {
      throw FirestoreDataException(
        documentPath: '${FirestoreCollections.cartItems}/$productId',
        field: CartItemFields.quantity,
        reason: 'harus berupa bilangan bulat dan tidak boleh hilang',
      );
    }
    if (quantity < 1) {
      throw FirestoreDataException(
        documentPath: '${FirestoreCollections.cartItems}/$productId',
        field: CartItemFields.quantity,
        reason: 'harus minimal 1',
      );
    }

    return CartItem(
      productId: productId,
      productNameSnapshot: reader.optionalString(
        CartItemFields.productNameSnapshot,
      ),
      brandSnapshot: reader.optionalString(CartItemFields.brandSnapshot),
      imageUrlSnapshot: reader.optionalString(CartItemFields.imageUrlSnapshot),
      unitPriceSnapshot: reader.requireNonNegativeInt(
        CartItemFields.unitPriceSnapshot,
      ),
      priceUnitSnapshot: PriceUnit.fromStorage(
        data[CartItemFields.priceUnitSnapshot],
      ),
      quantity: quantity,
      updatedAt: reader.optionalDateTime(CartItemFields.updatedAt),
    );
  }

  /// Membuat item keranjang dari produk yang sudah dibaca ulang dari Firestore.
  ///
  /// Snapshot diambil dari [product] saat ini, bukan dari input pengguna.
  factory CartItem.fromProduct(Product product, {int quantity = 1}) {
    return CartItem(
      productId: product.id,
      productNameSnapshot: product.name,
      brandSnapshot: product.brand,
      imageUrlSnapshot: product.primaryImageUrl ?? '',
      unitPriceSnapshot: product.price,
      priceUnitSnapshot: product.priceUnit,
      quantity: quantity,
    );
  }

  CartItem copyWith({int? quantity, DateTime? updatedAt}) {
    return CartItem(
      productId: productId,
      productNameSnapshot: productNameSnapshot,
      brandSnapshot: brandSnapshot,
      imageUrlSnapshot: imageUrlSnapshot,
      unitPriceSnapshot: unitPriceSnapshot,
      priceUnitSnapshot: priceUnitSnapshot,
      quantity: quantity ?? this.quantity,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'CartItem($productId x$quantity)';
}
