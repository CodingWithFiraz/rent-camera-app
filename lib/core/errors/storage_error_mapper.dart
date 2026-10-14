/// Pemetaan kegagalan Firebase Storage menjadi pesan yang aman ditampilkan.
///
/// Dipisahkan dari `repository_error_mapper.dart` karena pesan Firestore
/// ("database belum dikonfigurasi", "Firestore Security Rules") menyesatkan bila
/// yang gagal adalah unggahan berkas: pengguna perlu tahu bahwa yang bermasalah
/// adalah penyimpanan foto, bukan data katalog.
library;

import 'package:firebase_core/firebase_core.dart';

import 'app_exception.dart';

/// Pesan pengguna untuk kode error Firebase Storage.
///
/// Tidak ada detail internal (path berkas, nama bucket, pesan mentah Firebase)
/// yang ditampilkan.
String storageErrorMessageFor(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'unauthorized':
      case 'permission-denied':
        return 'Akses unggah foto ditolak. Storage Rules belum mengizinkan '
            'akun ini menyimpan foto.';
      case 'canceled':
        return 'Unggahan foto dibatalkan sebelum selesai.';
      case 'object-not-found':
        return 'Berkas foto tidak ditemukan pada penyimpanan.';
      case 'quota-exceeded':
        return 'Penyimpanan foto sudah penuh. Hubungi admin.';
      case 'retry-limit-exceeded':
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return 'Koneksi bermasalah saat mengunggah foto. Coba lagi.';
      default:
        return 'Gagal mengunggah foto. Coba lagi.';
    }
  }
  return 'Gagal mengunggah foto. Coba lagi.';
}

/// Memetakan kegagalan Storage menjadi [AppException] siap tampil.
///
/// Dipakai lapisan repository/simpanan agar UI selalu menerima pesan, bukan
/// exception mentah Firebase.
AppException mapStorageError(Object error, {required String entityLabel}) {
  if (error is AppException) {
    return error;
  }
  if (error is FirebaseException) {
    return AppException(storageErrorMessageFor(error));
  }
  return AppException('Gagal mengunggah $entityLabel. Coba lagi.');
}
