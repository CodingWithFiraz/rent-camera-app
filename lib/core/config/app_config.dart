import '../utils/whatsapp_checkout_link.dart';

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

  /// Nomor WhatsApp tujuan permintaan sewa.
  ///
  /// Format internasional tanpa `+`, spasi, atau tanda baca: kode negara
  /// diikuti nomor, tanpa awalan `0` (langkah pengisian ada di `SETUP.md` §3).
  /// Nomor final belum ditentukan pemilik, jadi **tidak ada default**: selama
  /// `WHATSAPP_NUMBER` belum diisi, aplikasi menonaktifkan tombol checkout dan
  /// menjelaskan bahwa nomor belum dikonfigurasi. Nilai ini sengaja hanya ada di
  /// sini; nomor tidak boleh disebar ke widget lain.
  static const String whatsappNumber = String.fromEnvironment(
    'WHATSAPP_NUMBER',
  );

  static bool get isAdminAliasConfigured => adminEmail.trim().isNotEmpty;

  /// `true` bila [whatsappNumber] dapat dipakai membangun tautan `wa.me`.
  static bool get isWhatsAppNumberConfigured =>
      WhatsAppCheckoutLink.isUsableNumber(whatsappNumber);

  static bool get isGoogleServerClientIdConfigured =>
      googleServerClientId.trim().isNotEmpty;

  static bool get isGoogleIosClientIdConfigured =>
      googleIosClientId.trim().isNotEmpty;
}
