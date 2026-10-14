import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/repository_error_mapper.dart';
import '../../catalog/domain/product.dart';
import '../domain/cart_item.dart';

/// Akses `users/{uid}/cart_items/{productId}`
/// (`docs/BLUEPRINT_APLIKASI.md` §6.4).
///
/// Document ID = `productId`, sehingga menambahkan produk yang sama akan
/// menaikkan quantity, bukan membuat baris duplikat. Repository tidak pernah
/// menulis ke UID lain: `uid` selalu berasal dari sesi login yang aktif.
class CartRepository {
  CartRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _entityLabel = 'keranjang';

  CollectionReference<Map<String, dynamic>> _cartItems(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.cartItems);

  /// Stream isi keranjang milik [uid], terurut saat penambahan.
  Stream<List<CartItem>> watchCartItems(String uid) {
    final Query<Map<String, dynamic>> query = _cartItems(uid)
        .orderBy(CartItemFields.updatedAt);
    return guardRepositoryStream(
      query.snapshots().map(_mapSnapshot),
      entityLabel: _entityLabel,
    );
  }

  /// Versi sekali-baca dari [watchCartItems].
  Future<List<CartItem>> fetchCartItems(String uid) async {
    try {
      final Query<Map<String, dynamic>> query = _cartItems(uid)
          .orderBy(CartItemFields.updatedAt);
      return _mapSnapshot(await query.get());
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  /// Membaca satu baris keranjang; `null` bila produk belum ada di keranjang.
  Future<CartItem?> fetchCartItem({
    required String uid,
    required String productId,
  }) async {
    final id = productId.trim();
    if (id.isEmpty) {
      return null;
    }
    try {
      final snapshot = await _cartItems(uid).doc(id).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return CartItem.fromFirestore(snapshot.id, data);
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  /// Menambahkan produk ke keranjang atau menaikkan quantity-nya.
  ///
  /// [product] harus hasil baca ulang dari Firestore (harga, stok, dan status
  /// terbaru), bukan data dari memori widget. Penambahan ditolak bila produk
  /// diarsipkan, stok habis, atau jumlah yang diminta melebihi stok saat ini.
  Future<void> addProduct({
    required String uid,
    required Product product,
    int quantity = 1,
  }) async {
    if (quantity < 1) {
      throw const AppException('Jumlah minimal 1.');
    }
    if (!product.isActive) {
      throw const AppException('Produk ini sudah tidak tersedia.');
    }

    final existing = await fetchCartItem(uid: uid, productId: product.id);
    final newQuantity = (existing?.quantity ?? 0) + quantity;
    if (newQuantity > product.stockQuantity) {
      throw AppException(
        'Stok ${product.name} hanya ${product.stockQuantity}. '
        'Jumlah di keranjang tidak dapat ditambah.',
      );
    }
    if (newQuantity > CartItem.maxQuantity) {
      throw const AppException(
        'Jumlah per produk sudah mencapai batas maksimum.',
      );
    }

    await _writeCartItem(
      uid: uid,
      item: CartItem.fromProduct(product, quantity: newQuantity),
    );
  }

  /// Menetapkan quantity sebuah baris keranjang secara eksplisit.
  ///
  /// Dipakai kontrol +/- pada halaman keranjang. Perubahan stok terbaru
  /// divalidasi pemanggil lewat [Product.stockQuantity] hasil baca ulang.
  Future<void> setQuantity({
    required String uid,
    required String productId,
    required int quantity,
    required int availableStock,
  }) async {
    if (quantity < 1) {
      throw const AppException('Jumlah minimal 1.');
    }
    if (quantity > CartItem.maxQuantity) {
      throw const AppException(
        'Jumlah per produk sudah mencapai batas maksimum.',
      );
    }
    if (quantity > availableStock) {
      throw AppException('Stok tersedia hanya $availableStock.');
    }

    final id = productId.trim();
    try {
      await _cartItems(uid).doc(id).update(<String, dynamic>{
        CartItemFields.quantity: quantity,
        CartItemFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  /// Menyalin harga dan satuan periode terbaru produk ke baris keranjang.
  ///
  /// Dipakai halaman keranjang ketika harga dokumen berubah setelah produk
  /// ditambahkan: checkout tidak boleh memakai harga lama (snapshot) karena
  /// pesan WhatsApp akan menyebut biaya yang tidak berlaku lagi. Quantity,
  /// nama, brand, dan foto tidak diubah.
  ///
  /// [product] harus hasil baca ulang dari Firestore, bukan data widget.
  Future<void> syncItemSnapshot({
    required String uid,
    required Product product,
  }) async {
    try {
      await _cartItems(uid).doc(product.id).update(<String, dynamic>{
        CartItemFields.productNameSnapshot: product.name,
        CartItemFields.brandSnapshot: product.brand,
        CartItemFields.imageUrlSnapshot: product.primaryImageUrl ?? '',
        CartItemFields.unitPriceSnapshot: product.price,
        CartItemFields.priceUnitSnapshot: product.priceUnit.storageValue,
        CartItemFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  /// Menghapus satu baris keranjang.
  Future<void> removeItem({
    required String uid,
    required String productId,
  }) async {
    final id = productId.trim();
    if (id.isEmpty) {
      return;
    }
    try {
      await _cartItems(uid).doc(id).delete();
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  Future<void> _writeCartItem({
    required String uid,
    required CartItem item,
  }) async {
    try {
      await _cartItems(uid).doc(item.productId).set(<String, dynamic>{
        CartItemFields.productId: item.productId,
        CartItemFields.productNameSnapshot: item.productNameSnapshot,
        CartItemFields.brandSnapshot: item.brandSnapshot,
        CartItemFields.imageUrlSnapshot: item.imageUrlSnapshot,
        CartItemFields.unitPriceSnapshot: item.unitPriceSnapshot,
        CartItemFields.priceUnitSnapshot: item.priceUnitSnapshot.storageValue,
        CartItemFields.quantity: item.quantity,
        CartItemFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  List<CartItem> _mapSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((doc) => CartItem.fromFirestore(doc.id, doc.data()))
          .toList(growable: false);
}
