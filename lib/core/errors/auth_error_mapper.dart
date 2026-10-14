import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app_exception.dart';

/// Pesan pengguna untuk kode error Firebase Auth.
///
/// Kode `user-not-found`, `wrong-password`, dan `invalid-credential` sengaja
/// disatukan supaya UI tidak membocorkan email mana yang terdaftar.
String authErrorMessageForCode(String code) {
  switch (code) {
    case 'invalid-email':
    case 'missing-email':
      return 'Format email tidak valid.';
    case 'user-disabled':
      return 'Akun ini dinonaktifkan. Hubungi admin.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Email atau kata sandi salah.';
    case 'email-already-in-use':
      return 'Email ini sudah terdaftar. Silakan masuk atau gunakan lupa kata sandi.';
    case 'weak-password':
      return 'Kata sandi terlalu lemah. Gunakan minimal 8 karakter.';
    case 'operation-not-allowed':
      return 'Metode login ini belum diaktifkan pada project Firebase (lihat SETUP.md).';
    case 'too-many-requests':
      return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
    case 'network-request-failed':
      return 'Koneksi bermasalah. Periksa jaringan lalu coba lagi.';
    case 'requires-recent-login':
      return 'Sesi sudah terlalu lama. Silakan masuk kembali.';
    case 'account-exists-with-different-credential':
      return 'Email ini sudah terdaftar dengan metode login lain. Masuk memakai metode tersebut.';
    case 'credential-already-in-use':
      return 'Akun Google ini sudah tertaut ke akun lain.';
    case 'provider-already-linked':
      return 'Metode login ini sudah tertaut ke akun Anda.';
    case 'user-mismatch':
      return 'Kredensial tidak cocok dengan sesi yang sedang aktif.';
    case 'permission-denied':
      return 'Akses ditolak oleh Firebase. Hubungi admin.';
    case 'unavailable':
      return 'Layanan autentikasi sedang tidak dapat dihubungi. Coba lagi.';
    case 'internal-error':
      return 'Terjadi gangguan pada layanan autentikasi. Coba lagi.';
    case 'cancelled':
    case 'canceled':
      return 'Proses login dibatalkan.';
    default:
      return 'Terjadi masalah saat memproses autentikasi. Coba lagi.';
  }
}

/// Memetakan error autentikasi ke pesan yang aman ditampilkan.
///
/// Mengembalikan `null` bila tidak ada yang perlu ditampilkan ke pengguna
/// (misalnya pembatalan Google Sign-In oleh pengguna). Tidak pernah
/// mengembalikan pesan mentah dari exception.
String? authErrorMessageFor(Object error) {
  if (error is AppException) {
    return error.message;
  }
  if (error is FirebaseAuthException) {
    return authErrorMessageForCode(error.code);
  }
  if (error is GoogleSignInException) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return null;
      case GoogleSignInExceptionCode.interrupted:
        return 'Proses login Google terhenti sebelum selesai. Coba lagi.';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Konfigurasi Google Sign-In belum benar (lihat SETUP.md).';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Jendela login Google tidak dapat ditampilkan. Coba lagi.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'Akun Google tidak cocok dengan sesi yang aktif.';
      case GoogleSignInExceptionCode.unknownError:
        return 'Login Google gagal. Coba lagi.';
    }
  }
  return 'Terjadi kesalahan yang tidak terduga. Coba lagi.';
}

/// Pesan pengguna untuk kegagalan pengiriman email reset kata sandi.
///
/// `user-not-found` sengaja tidak ditampilkan supaya aplikasi tidak mengungkap
/// apakah sebuah email punya akun atau tidak.
String? authErrorMessageForPasswordReset(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return null;
      case 'invalid-email':
        return 'Format email tidak valid.';
      default:
        return authErrorMessageForCode(error.code);
    }
  }
  return authErrorMessageFor(error);
}

/// Pesan pengguna untuk kegagalan Cloud Firestore.
///
/// Dipakai saat sinkronisasi dokumen profil gagal (misalnya Security Rules
/// belum dideploy), sehingga pengguna mendapat penjelasan yang jujur dan bukan
/// exception mentah.
String firestoreErrorMessageFor(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Akses ditolak. Firestore Security Rules belum mengizinkan operasi ini.';
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return 'Koneksi ke database bermasalah. Coba lagi.';
      case 'failed-precondition':
        return 'Operasi database belum dapat dijalankan. Hubungi admin.';
      case 'not-found':
        return 'Data yang dituju tidak ditemukan.';
      default:
        return 'Gagal mengakses database. Coba lagi.';
    }
  }
  return 'Gagal mengakses database. Coba lagi.';
}
