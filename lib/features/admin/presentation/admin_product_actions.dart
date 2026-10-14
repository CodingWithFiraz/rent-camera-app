import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/repository_error_mapper.dart';
import 'admin_providers.dart';

/// Status satu operasi arsip/pulihkan produk pada dashboard admin.
class AdminProductActionsState {
  const AdminProductActionsState({this.busyProductId, this.errorMessage});

  /// Document ID produk yang sedang diproses; `null` bila tidak ada operasi.
  final String? busyProductId;

  /// Pesan kegagalan terakhir; `null` bila tidak ada.
  final String? errorMessage;

  bool get isBusy => busyProductId != null;
}

/// Hasil operasi arsip/pulihkan; pesannya ditampilkan apa adanya oleh layar.
class AdminProductActionOutcome {
  const AdminProductActionOutcome.success(this.message) : isSuccess = true;

  const AdminProductActionOutcome.failure(this.message) : isSuccess = false;

  final bool isSuccess;
  final String message;
}

/// Menjalankan arsip (`isActive: false`) dan pulihkan (`isActive: true`).
///
/// Pesan hasil dibangun dari keberhasilan operasi nyata: tidak ada laporan
/// sukses sebelum Firestore benar-benar menerima penulisan, dan kegagalan
/// ditampilkan dengan pesan yang sudah dipetakan.
class AdminProductActions extends Notifier<AdminProductActionsState> {
  @override
  AdminProductActionsState build() => const AdminProductActionsState();

  Future<AdminProductActionOutcome> setActive({
    required String productId,
    required bool isActive,
  }) async {
    if (state.isBusy) {
      return const AdminProductActionOutcome.failure(
        'Operasi lain masih berjalan. Tunggu sampai selesai.',
      );
    }

    state = AdminProductActionsState(busyProductId: productId);
    try {
      await ref
          .read(adminProductRepositoryProvider)
          .setActive(productId: productId, isActive: isActive);
    } catch (error) {
      final message = repositoryErrorMessageFor(error, entityLabel: 'produk');
      state = AdminProductActionsState(errorMessage: message);
      return AdminProductActionOutcome.failure(message);
    }

    state = const AdminProductActionsState();
    return AdminProductActionOutcome.success(
      isActive
          ? 'Produk dipulihkan dan kembali tampil di katalog.'
          : 'Produk diarsipkan dan tidak lagi tampil di katalog.',
    );
  }

  /// Menghapus pesan kegagalan yang sudah dibaca pengguna.
  void clearError() {
    if (state.errorMessage == null) {
      return;
    }
    state = AdminProductActionsState(busyProductId: state.busyProductId);
  }
}
