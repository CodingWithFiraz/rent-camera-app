import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../data/cart_repository.dart';
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
