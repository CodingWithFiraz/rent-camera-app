/// Exception dengan pesan yang aman ditampilkan ke pengguna.
///
/// Pesan di sini tidak boleh memuat token, kredensial, atau detail internal
/// Firebase. Error teknis dipetakan ke [AppException] (atau ke pesan pengguna
/// lewat `auth_error_mapper.dart`) sebelum sampai ke UI.
class AppException implements Exception {
  const AppException(this.message);

  /// Pesan yang boleh ditampilkan pada UI (bahasa Indonesia).
  final String message;

  @override
  String toString() => 'AppException: $message';
}
