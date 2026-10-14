import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/repository_error_mapper.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/utils/external_launcher.dart';
import '../../../core/utils/whatsapp_checkout_link.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../data/cart_repository.dart';
import '../domain/cart_checkout.dart';
import '../domain/cart_item.dart';

/// Akses `users/{uid}/cart_items/{productId}`
/// (`docs/BLUEPRINT_APLIKASI.md` §6.4).
///
/// `uid` selalu berasal dari sesi login yang aktif; repository tidak pernah
/// menerima UID dari input pengguna.
final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepository(ref.watch(firebaseFirestoreProvider)),
);

/// Isi keranjang realtime milik [uid], terurut `updatedAt`.
///
/// UID kosong (belum login) menghasilkan daftar kosong tanpa menyentuh
/// Firestore, sehingga tidak ada permintaan ke path `users//cart_items`.
/// Harga dan stok pada item keranjang adalah snapshot saat ditambahkan; checkout
/// wajib membaca ulang produk dari `productByIdProvider` sebelum menghitung.
final cartItemsProvider = StreamProvider.family<List<CartItem>, String>((
  ref,
  uid,
) {
  final id = uid.trim();
  if (id.isEmpty) {
    return Stream<List<CartItem>>.value(const <CartItem>[]);
  }
  return ref.watch(cartRepositoryProvider).watchCartItems(id);
});

/// Jumlah seluruh quantity di keranjang [uid]; `0` bila belum ada data.
///
/// Dipakai penanda (badge) pada app bar. Baris yang sudah dimuat tetapi masih
/// menunggu data terbaru tetap dihitung dari data terakhir yang diketahui
/// (`AsyncValue.value`), sehingga badge tidak berkedip saat stream memperbarui.
final cartItemCountProvider = Provider.family<int, String>((ref, uid) {
  final items = ref.watch(cartItemsProvider(uid)).value;
  if (items == null || items.isEmpty) {
    return 0;
  }
  return items.fold<int>(0, (int total, item) => total + item.quantity);
});

/// Nomor WhatsApp tujuan checkout.
///
/// Nilainya hanya dibaca dari [AppConfig] (`--dart-define=WHATSAPP_NUMBER`),
/// tetapi disediakan sebagai provider supaya widget test dapat menyuntikkan
/// nomor uji tanpa menulis nomor asli ke dalam source code atau test.
final checkoutWhatsAppNumberProvider = Provider<String>(
  (ref) => AppConfig.whatsappNumber,
);

/// `true` bila nomor checkout sudah dapat dipakai membangun tautan `wa.me`.
///
/// Dipakai halaman keranjang untuk menonaktifkan tombol checkout beserta
/// alasannya selama nomor tujuan belum dikonfigurasi (`WHATSAPP_NUMBER` kosong).
final isCheckoutConfiguredProvider = Provider<bool>(
  (ref) => WhatsAppCheckoutLink.isUsableNumber(
    ref.watch(checkoutWhatsAppNumberProvider),
  ),
);

/// Pembuka tautan eksternal (WhatsApp/aplikasi lain).
///
/// Disediakan sebagai provider agar test dapat menggantinya dengan pembuka
/// palsu: tidak ada platform channel yang dipanggil saat pengujian.
final externalLauncherProvider = Provider<ExternalLauncher>(
  (ref) => const ExternalLauncher(),
);

/// Hasil pencocokan keranjang [uid] dengan data produk terbaru.
///
/// Alur blueprint §7 langkah 2–4: keranjang dibaca realtime, lalu setiap produk
/// dibaca ulang dari collection `products` dan harga/stok/statusnya dicocokkan
/// sebelum subtotal dan total dihitung. Provider ini hanya membaca: tidak ada
/// penulisan keranjang dan tidak ada penguncian stok. Perubahan keranjang
/// (termasuk dari halaman detail produk) otomatis memicu validasi ulang karena
/// hasilnya bergantung pada [cartItemsProvider].
final cartCheckoutProvider =
    FutureProvider.family<CartCheckoutValidation, String>((ref, uid) async {
      final id = uid.trim();
      if (id.isEmpty) {
        return CartCheckoutValidation.empty;
      }
      final items = await ref.watch(cartItemsProvider(id).future);
      if (items.isEmpty) {
        return CartCheckoutValidation.empty;
      }
      final products = await ref
          .watch(productRepositoryProvider)
          .fetchProductsByIds(items.map((CartItem item) => item.productId));
      return CartCheckoutValidation.validate(items: items, products: products);
    });

/// Aksi tulis dari halaman keranjang (jumlah, hapus, perbarui harga).
///
/// Semua aksi melewati [CartRepository] supaya aturan quantity (integer >= 1,
/// tidak melebihi stok terverifikasi, batas maksimum) tetap berada di satu
/// tempat, dan kegagalannya sudah berupa [AppException] siap tampil.
class CartActions {
  CartActions(this._ref);

  final Ref _ref;

  /// Mengubah jumlah satu baris keranjang.
  ///
  /// Batas stok **tidak** diambil dari angka di layar: dokumen produk dibaca
  /// ulang lebih dulu, sehingga stok yang dipakai adalah stok terverifikasi
  /// terakhir (blueprint §7). Bila dokumen produk sudah tidak ada, tidak ada
  /// yang ditulis dan pengguna diminta menghapus baris tersebut.
  Future<void> setQuantity({
    required String uid,
    required String productId,
    required int quantity,
  }) => _guard(() async {
    final product = await _ref
        .read(productRepositoryProvider)
        .fetchProductById(productId);
    if (product == null) {
      throw const AppException(
        'Alat ini sudah tidak ada di katalog. Hapus baris ini dari keranjang.',
      );
    }
    await _ref
        .read(cartRepositoryProvider)
        .setQuantity(
          uid: uid,
          productId: productId,
          quantity: quantity,
          availableStock: product.stockQuantity,
        );
  });

  /// Menghapus satu baris keranjang.
  Future<void> removeItem({required String uid, required String productId}) =>
      _guard(
        () => _ref
            .read(cartRepositoryProvider)
            .removeItem(uid: uid, productId: productId),
      );

  /// Menyalin harga dan satuan periode terbaru ke baris keranjang.
  ///
  /// Produk dibaca ulang dari Firestore lebih dulu. Bila dokumennya sudah tidak
  /// ada, tidak ada yang ditulis dan pengguna diminta menghapus baris tersebut —
  /// bukan menyalin harga yang tidak lagi berlaku.
  Future<void> refreshStoredPrice({
    required String uid,
    required String productId,
  }) => _guard(() async {
    final product = await _ref
        .read(productRepositoryProvider)
        .fetchProductById(productId);
    if (product == null) {
      throw const AppException(
        'Alat ini sudah tidak ada di katalog. Hapus baris ini dari keranjang.',
      );
    }
    await _ref
        .read(cartRepositoryProvider)
        .syncItemSnapshot(uid: uid, product: product);
  });

  /// Membaca ulang keranjang dan produk, lalu memvalidasi ulang.
  ///
  /// Dipanggil tepat sebelum pesan WhatsApp disusun (blueprint §7 langkah 2–4),
  /// sehingga pesan memuat harga dan stok yang terakhir dibaca — bukan hasil
  /// validasi lama yang mungkin sudah tidak berlaku.
  Future<CartCheckoutValidation> validateForCheckout(String uid) async {
    final id = uid.trim();
    if (id.isEmpty) {
      return CartCheckoutValidation.empty;
    }
    return _guardWithResult(() async {
      final items = await _ref.read(cartRepositoryProvider).fetchCartItems(id);
      if (items.isEmpty) {
        return CartCheckoutValidation.empty;
      }
      final products = await _ref
          .read(productRepositoryProvider)
          .fetchProductsByIds(items.map((CartItem item) => item.productId));
      return CartCheckoutValidation.validate(items: items, products: products);
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      throw _asAppException(error);
    }
  }

  Future<T> _guardWithResult<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw _asAppException(error);
    }
  }

  AppException _asAppException(Object error) => error is AppException
      ? error
      : mapRepositoryError(error, entityLabel: 'keranjang');
}

/// Aksi tulis keranjang untuk halaman keranjang.
final cartActionsProvider = Provider<CartActions>((ref) => CartActions(ref));
