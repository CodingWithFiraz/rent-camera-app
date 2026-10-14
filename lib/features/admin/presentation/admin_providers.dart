import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../catalog/domain/product.dart';
import '../data/admin_access_repository.dart';
import '../data/admin_product_image_picker.dart';
import '../data/admin_product_repository.dart';
import '../data/product_image_storage.dart';
import '../domain/admin_product_filter.dart';
import 'admin_access_notifier.dart';
import 'admin_product_actions.dart';
import 'admin_product_form_controller.dart';

/// Akses claim admin dari ID token Firebase Auth.
final adminAccessRepositoryProvider = Provider<AdminAccessRepository>(
  (ref) => AdminAccessRepository(ref.watch(firebaseAuthProvider)),
);

/// Status akses admin yang dipakai route guard dan entri drawer.
///
/// Status diperbarui otomatis setiap kali sesi login berubah. Bila Firebase
/// belum dikonfigurasi, pembacaan claim tidak mungkin dilakukan sehingga akses
/// ditolak — bukan dianggap admin.
///
/// Pembacaan claim disusun **malas** (`ref.read` baru dijalankan saat claim
/// benar-benar dibaca): provider ini dibangun pada setiap perubahan rute, jadi
/// `FirebaseAuth` tidak boleh disentuh hanya untuk menyusun status awal. Bila
/// pembacaan gagal (termasuk saat `FirebaseAuth` belum siap), notifier
/// menanggapinya sebagai akses ditolak.
final adminAccessNotifierProvider = Provider<AdminAccessNotifier>((ref) {
  final isFirebaseConfigured = ref
      .watch(firebaseBootstrapProvider)
      .isConfigured;
  final session = ref.watch(authSessionNotifierProvider);
  final notifier = AdminAccessNotifier(
    readClaims: isFirebaseConfigured
        ? () => ref.read(adminAccessRepositoryProvider).readClaims()
        : null,
  );

  void handleSessionChange() {
    unawaited(notifier.onSessionChanged(isSignedIn: session.isSignedIn));
  }

  session.addListener(handleSessionChange);
  ref.onDispose(() => session.removeListener(handleSessionChange));
  handleSessionChange();
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Akses tulis collection `products` untuk dashboard admin.
final adminProductRepositoryProvider = Provider<AdminProductRepository>(
  (ref) => FirebaseAdminProductRepository(ref.watch(firebaseFirestoreProvider)),
);

/// Seluruh produk (aktif dan arsip) untuk dashboard admin.
final adminProductsProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(adminProductRepositoryProvider).watchAllProducts(),
);

/// Produk yang lolos pencarian/filter dashboard.
///
/// Nilai `AsyncValue` diteruskan apa adanya supaya layar tetap dapat membedakan
/// memuat, error, dan kosong.
final adminVisibleProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final filter = ref.watch(adminProductFilterProvider);
  return ref.watch(adminProductsProvider).whenData(filter.apply);
});

/// Jumlah produk nyata (total/aktif/arsip) untuk header dashboard.
///
/// `null` berarti data belum terbaca (memuat atau error): header menampilkan
/// keadaan belum tersedia alih-alih angka nol yang menyesatkan.
final adminProductSummaryProvider = Provider<AdminProductSummary?>((ref) {
  final products = ref.watch(adminProductsProvider).value;
  return products == null ? null : AdminProductSummary.fromProducts(products);
});

/// Kriteria pencarian/filter daftar produk admin.
final adminProductFilterProvider =
    NotifierProvider<AdminProductFilterNotifier, AdminProductFilter>(
      AdminProductFilterNotifier.new,
    );

/// Pengelola kriteria pencarian/filter dashboard admin.
class AdminProductFilterNotifier extends Notifier<AdminProductFilter> {
  @override
  AdminProductFilter build() => AdminProductFilter.none;

  /// Mengubah kata kunci pencarian tanpa mengubah filter status.
  void setQuery(String query) {
    if (state.query == query) {
      return;
    }
    state = state.copyWith(query: query);
  }

  /// Memilih kelompok produk yang ditampilkan (semua/aktif/arsip).
  void setVisibility(AdminProductVisibility visibility) {
    if (state.visibility == visibility) {
      return;
    }
    state = state.copyWith(visibility: visibility);
  }

  /// Mengembalikan daftar ke keadaan tanpa kriteria.
  void reset() {
    if (!state.isFiltering) {
      return;
    }
    state = AdminProductFilter.none;
  }
}

/// Penyimpanan foto produk pada `products/{productId}/**` (blueprint §9 dan §10).
final productImageStorageProvider = Provider<ProductImageStorage>(
  (ref) => FirebaseProductImageStorage(ref.watch(firebaseStorageProvider)),
);

/// Pemilih beberapa foto produk dari galeri.
///
/// Disediakan sebagai provider supaya test dapat memakai pemilih palsu: tidak
/// ada platform channel `image_picker` yang dipanggil saat pengujian.
final adminProductImagePickerProvider = Provider<AdminProductImagePicker>(
  (ref) => ImagePickerAdminProductImagePicker(),
);

/// Aksi arsip/pulihkan produk (`docs/BLUEPRINT_APLIKASI.md` §8).
final adminProductActionsProvider =
    NotifierProvider<AdminProductActions, AdminProductActionsState>(
      AdminProductActions.new,
    );

/// Pengelola form tambah/edit produk (unggah foto dan penulisan Firestore).
final adminProductFormControllerProvider =
    NotifierProvider<AdminProductFormController, AdminProductFormState>(
      AdminProductFormController.new,
    );
