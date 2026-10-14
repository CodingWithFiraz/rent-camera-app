/// Konfigurasi aplikasi yang terpusat.
///
/// Tidak ada kredensial di sini: nilai yang bergantung pada pemilik project
/// (nama brand, email admin, client ID Google) diberikan lewat `--dart-define`
/// sehingga tidak perlu ditulis di source code. Semua nilai default dibuat
/// eksplisit sebagai "belum dikonfigurasi" agar aplikasi menampilkan state
/// konfigurasi, bukan data karangan.
abstract final class AppConfig {
  /// Nama aplikasi yang tampil pada app bar/title.
  ///
  /// TODO(pemilik): tentukan nama/brand final, lalu jalankan aplikasi dengan
  /// `--dart-define=APP_NAME="Nama Brand"`. Lihat `SETUP.md` §1.
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Rent Camera App',
  );

  /// Alias username untuk akun admin (dipetakan ke [adminEmail]).
  ///
  /// Alias **hanya** nama pengguna: password tetap divalidasi Firebase Auth.
  static const String adminLoginAlias = String.fromEnvironment(
    'ADMIN_LOGIN_ALIAS',
    defaultValue: 'admin',
  );

  /// Email akun admin yang dikontrol pemilik project.
  ///
  /// Kosong berarti alias admin belum dikonfigurasi; aplikasi akan menolak
  /// login memakai alias tersebut dan tidak menebak email apa pun.
  static const String adminEmail = String.fromEnvironment('ADMIN_EMAIL');

  /// Server (web) client ID OAuth untuk Google Sign-In di Android/iOS.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// Client ID OAuth untuk iOS/macOS.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  static bool get isAdminAliasConfigured => adminEmail.trim().isNotEmpty;

  static bool get isGoogleServerClientIdConfigured =>
      googleServerClientId.trim().isNotEmpty;

  static bool get isGoogleIosClientIdConfigured =>
      googleIosClientId.trim().isNotEmpty;
}
