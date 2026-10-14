/// Lokasi route `go_router` dalam satu tempat.
abstract final class AppRoutes {
  /// Route awal: menampilkan status pemuatan sesi sebelum redirect dijalankan.
  static const String splash = '/splash';

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  /// Tujuan setelah login berhasil (katalog penuh: Fase 3).
  static const String catalog = '/catalog';

  /// Ditampilkan bila Firebase belum dikonfigurasi.
  static const String setupRequired = '/setup-required';
}
