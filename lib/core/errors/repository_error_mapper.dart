import 'package:cloud_firestore/cloud_firestore.dart';
// `ProviderException` tidak diekspor `flutter_riverpod.dart` pada versi ini
// (riverpod 3.4.3); kelas itu berada di `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show ProviderException;

import 'app_exception.dart';
import 'auth_error_mapper.dart';
import 'firestore_data_exception.dart';

/// Memetakan kegagalan repository menjadi [AppException] yang aman untuk UI.
///
/// Repository adalah satu-satunya lapisan yang menyentuh Firebase, sehingga
/// lapisan ini juga yang bertanggung jawab mengubah exception mentah
/// (Firebase, parsing dokumen) menjadi pesan pengguna yang jujur tanpa detail
/// internal.
AppException mapRepositoryError(Object error, {required String entityLabel}) {
  if (error is AppException) {
    return error;
  }
  if (error is FirestoreDataException) {
    return AppException(
      'Data $entityLabel tidak sesuai format aplikasi. Hubungi admin.',
    );
  }
  if (error is FirebaseException) {
    return AppException(firestoreErrorMessageFor(error));
  }
  return AppException('Gagal memuat $entityLabel. Coba lagi.');
}

/// Stream yang mengubah error menjadi [AppException].
///
/// Dipakai repository supaya `AsyncError` yang diterima UI selalu berisi
/// pesan siap tampil, bukan exception mentah Firebase.
Stream<T> guardRepositoryStream<T>(
  Stream<T> source, {
  required String entityLabel,
}) async* {
  try {
    yield* source;
  } catch (error) {
    throw mapRepositoryError(error, entityLabel: entityLabel);
  }
}

/// Pesan siap tampil dari `AsyncError.error` sebuah provider Riverpod.
///
/// Error provider sering dibungkus `ProviderException` ketika penyebabnya ada
/// pada provider dependensi (mis. Firestore belum dikonfigurasi), sehingga
/// pembungkusnya dibuka lebih dulu sebelum dipetakan dengan
/// [mapRepositoryError]. Hanya pesan aman yang dikembalikan; tipe exception,
/// stack trace, dan pesan internal tidak pernah ditampilkan ke pengguna.
String repositoryErrorMessageFor(Object? error, {required String entityLabel}) {
  // Pembungkus provider dapat bersarang (provider A gagal karena provider B),
  // jadi dibuka bertingkat sampai kedalaman yang masih wajar.
  var current = error;
  for (var depth = 0; depth < 8 && current is ProviderException; depth++) {
    current = current.exception;
  }

  if (current == null) {
    return 'Gagal memuat $entityLabel. Coba lagi.';
  }
  // `StateError` berasal dari provider Firebase yang belum terinisialisasi
  // (lihat `firebaseFirestoreProvider`), bukan dari repository.
  if (current is StateError) {
    return 'Aplikasi belum terhubung ke Firebase, sehingga data belum dapat '
        'dimuat. Hubungi admin, lalu coba lagi.';
  }
  return mapRepositoryError(current, entityLabel: entityLabel).message;
}
