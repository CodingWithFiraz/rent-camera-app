/// Lokasi route `go_router` dalam satu tempat.
abstract final class AppRoutes {
  /// Route awal: menampilkan status pemuatan sesi sebelum redirect dijalankan.
  static const String splash = '/splash';

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  /// Tujuan setelah login berhasil: halaman katalog.
  static const String catalog = '/catalog';

  /// Pola route detail produk; path nyatanya dibentuk [productDetailPath].
  static const String productDetail = '/product/:productId';

  /// Halaman Portofolio & Layanan (isi penuh dikerjakan pada Fase 5).
  static const String portfolio = '/portfolio';

  /// Halaman Keranjang (isi penuh dikerjakan pada Fase 4).
  static const String cart = '/cart';

  /// Halaman Profil pengguna (isi penuh dikerjakan pada Fase 5).
  static const String profile = '/profile';

  /// Ditampilkan bila Firebase belum dikonfigurasi.
  static const String setupRequired = '/setup-required';

  /// Path detail produk untuk [productId] (document ID `products`).
  ///
  /// Nilai di-encode supaya karakter khusus tidak mengubah struktur path.
  static String productDetailPath(String productId) =>
      '/product/${Uri.encodeComponent(productId.trim())}';
}
