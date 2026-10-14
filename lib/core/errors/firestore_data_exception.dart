/// Dokumen Firestore tidak sesuai schema aplikasi.
///
/// Dilempar model domain saat field wajib hilang, kosong, atau bertipe salah,
/// supaya kesalahan data tidak diam-diam berubah menjadi nilai default yang
/// tampak benar. Repository memetakan exception ini ke pesan yang aman
/// ditampilkan (lihat `repository_error_mapper.dart`).
///
/// `documentPath` dan `reason` hanya untuk log/diagnostik internal; keduanya
/// tidak boleh ditampilkan mentah ke pengguna.
class FirestoreDataException implements Exception {
  const FirestoreDataException({
    required this.documentPath,
    required this.field,
    required this.reason,
  });

  /// Path dokumen sumber, misalnya `products/{productId}`.
  final String documentPath;

  /// Nama field yang bermasalah.
  final String field;

  /// Alasan kegagalan (bahasa Indonesia, tanpa nilai sensitif).
  final String reason;

  @override
  String toString() =>
      'FirestoreDataException($documentPath): field "$field" $reason';
}
