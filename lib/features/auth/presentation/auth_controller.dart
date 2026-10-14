import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/auth_error_mapper.dart';
import '../data/auth_repository.dart';
import 'auth_providers.dart';

/// Status pengiriman form autentikasi.
class AuthActionState {
  const AuthActionState.idle()
    : isSubmitting = false,
      errorMessage = null,
      noticeMessage = null;

  const AuthActionState.submitting()
    : isSubmitting = true,
      errorMessage = null,
      noticeMessage = null;

  const AuthActionState.failure(String this.errorMessage)
    : isSubmitting = false,
      noticeMessage = null;

  const AuthActionState.notice(String this.noticeMessage)
    : isSubmitting = false,
      errorMessage = null;

  /// True selama permintaan ke Firebase berjalan; UI harus menonaktifkan form.
  final bool isSubmitting;

  /// Pesan error yang sudah dipetakan (aman ditampilkan ke pengguna).
  final String? errorMessage;

  /// Pesan informasi non-fatal, misalnya sinkronisasi profil gagal padahal
  /// login berhasil.
  final String? noticeMessage;
}

/// Menjalankan aksi autentikasi dan menyimpan status pengirimannya.
///
/// Kelas ini tidak menyentuh Firebase secara langsung: seluruh akses lewat
/// [AuthRepository] sehingga dapat diuji dengan implementasi palsu.
class AuthController extends Notifier<AuthActionState> {
  @override
  AuthActionState build() => const AuthActionState.idle();

  /// Login memakai email, atau alias admin bila sudah dikonfigurasi pemilik.
  Future<bool> signInWithEmail({
    required String identifier,
    required String password,
  }) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(identifier: identifier, password: password),
    );
  }

  /// Registrasi akun baru beserta dokumen profil `users/{uid}`.
  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .registerWithEmail(name: name, email: email, password: password),
    );
  }

  /// Login Google native: credential Google dikirim ke Firebase Auth.
  Future<bool> signInWithGoogle() {
    return _run(() => ref.read(authRepositoryProvider).signInWithGoogle());
  }

  /// Mengirim email reset kata sandi.
  ///
  /// Pesan sukses ditampilkan sama baik email terdaftar maupun tidak, supaya
  /// aplikasi tidak mengungkap email mana yang punya akun.
  Future<bool> sendPasswordResetEmail({required String email}) async {
    state = const AuthActionState.submitting();
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(email: email);
    } catch (error) {
      final message = authErrorMessageForPasswordReset(error);
      if (message != null) {
        state = AuthActionState.failure(message);
        return false;
      }
    }
    state = const AuthActionState.notice(
      'Jika email tersebut terdaftar, tautan reset kata sandi sudah dikirim. '
      'Periksa kotak masuk dan folder spam.',
    );
    return true;
  }

  /// Logout dari Firebase Auth dan membersihkan status form.
  ///
  /// Sesi pada [authSessionNotifierProvider] ikut terbarui melalui
  /// `authStateChanges`, sehingga route terproteksi otomatis tertutup.
  Future<void> signOut() async {
    state = const AuthActionState.submitting();
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (error) {
      state = AuthActionState.failure(
        authErrorMessageFor(error) ?? 'Gagal keluar dari akun.',
      );
      return;
    }
    state = const AuthActionState.idle();
  }

  /// Menghapus pesan dari percobaan sebelumnya.
  void clearMessages() {
    if (state.isSubmitting) {
      return;
    }
    state = const AuthActionState.idle();
  }

  Future<bool> _run(Future<AuthResult> Function() action) async {
    state = const AuthActionState.submitting();
    try {
      final result = await action();
      final warning = result.profileSyncWarning;
      state = warning == null
          ? const AuthActionState.idle()
          : AuthActionState.notice(warning);
      return true;
    } catch (error) {
      final message = authErrorMessageFor(error);
      state = message == null
          ? const AuthActionState.idle()
          : AuthActionState.failure(message);
      return false;
    }
  }
}

/// Status pengiriman form autentikasi.
final authControllerProvider =
    NotifierProvider<AuthController, AuthActionState>(AuthController.new);
