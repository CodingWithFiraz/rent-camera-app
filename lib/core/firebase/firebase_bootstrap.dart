import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show FlutterError, TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart'
    show MissingPluginException, PlatformException;

import '../../firebase_options.dart';

/// Hasil bootstrap Firebase sebelum aplikasi dijalankan.
///
/// Opsi Firebase diambil dari hasil `flutterfire configure` pada
/// `lib/firebase_options.dart` (lihat `SETUP.md`). Bootstrap tidak boleh
/// mengasumsikan Firebase siap: bila opsi tersebut tidak dapat dipakai pada
/// platform yang sedang berjalan, aplikasi menampilkan layar setup, bukan
/// berpura-pura autentikasi berjalan.
class FirebaseBootstrapStatus {
  const FirebaseBootstrapStatus.configured()
    : isConfigured = true,
      diagnosticCode = null,
      configurationSource = null;

  const FirebaseBootstrapStatus.notConfigured(
    this.diagnosticCode, {
    this.configurationSource,
  }) : isConfigured = false;

  /// `true` bila `Firebase.initializeApp()` berhasil.
  final bool isConfigured;

  /// Kode diagnostik singkat dan tidak sensitif (mis. `no-app`,
  /// `plugin-unavailable`) yang hanya ditampilkan pada layar setup.
  final String? diagnosticCode;

  /// Opsi/berkas konfigurasi yang dibutuhkan platform yang sedang berjalan;
  /// `null` bila Firebase sudah siap dipakai.
  final String? configurationSource;
}

abstract final class FirebaseBootstrap {
  /// Mencoba menginisialisasi Firebase memakai [DefaultFirebaseOptions].
  ///
  /// Opsi wajib diberikan: web dan desktop tidak punya berkas konfigurasi
  /// native, sehingga `Firebase.initializeApp()` tanpa opsi gagal dengan
  /// assertion "FirebaseOptions cannot be null when creating the default app.".
  ///
  /// Tidak pernah melempar exception: kegagalan konfigurasi dikembalikan sebagai
  /// [FirebaseBootstrapStatus.notConfigured] agar aplikasi tetap dapat dibuka
  /// dan menjelaskan kepada developer apa yang harus dilakukan.
  ///
  /// Binding Flutter harus sudah siap sebelum pemanggilan (dilakukan
  /// `WidgetsFlutterBinding.ensureInitialized()` di `lib/main.dart`), karena
  /// channel plugin Firebase bergantung padanya. Bila belum, status yang
  /// dikembalikan bernilai `flutter-binding-unavailable`; test unit karena itu
  /// memanggil `TestWidgetsFlutterBinding.ensureInitialized()` lebih dulu.
  static Future<FirebaseBootstrapStatus> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        return const FirebaseBootstrapStatus.configured();
      }
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return const FirebaseBootstrapStatus.configured();
    } catch (error) {
      return FirebaseBootstrapStatus.notConfigured(
        diagnosticCodeFor(error),
        configurationSource: describeConfigurationSource(),
      );
    }
  }

  /// Menerjemahkan kegagalan inisialisasi menjadi kode stabil yang aman
  /// ditampilkan (tanpa nama tipe internal, tanpa kredensial, tanpa pesan SDK).
  static String diagnosticCodeFor(Object error) {
    if (error is FirebaseException) {
      // Kode dari SDK Firebase apa adanya, mis. `no-app` atau `invalid-api-key`.
      return error.code;
    }
    if (error is UnsupportedError) {
      // `DefaultFirebaseOptions.currentPlatform` melempar ini untuk platform
      // yang belum didaftarkan pada `flutterfire configure`.
      return 'unsupported-platform';
    }
    if (error is FlutterError) {
      // Diperiksa sebelum `AssertionError` karena `FlutterError` (lihat
      // `foundation/assertions.dart`) `implements AssertionError`. Penyebabnya
      // bukan konfigurasi Firebase, melainkan binding Flutter belum diinisialisasi
      // saat bootstrap dipanggil (mis. unit test tanpa binding).
      return 'flutter-binding-unavailable';
    }
    if (error is AssertionError) {
      return 'options-unavailable';
    }
    if (error is MissingPluginException ||
        (error is PlatformException && error.code == 'channel-error')) {
      // Plugin native Firebase belum terdaftar pada platform/lingkungan ini.
      return 'plugin-unavailable';
    }
    return 'initialization-failed';
  }

  /// Sumber konfigurasi Firebase untuk platform yang sedang berjalan.
  ///
  /// Dipakai layar setup supaya instruksi yang ditampilkan sesuai platform:
  /// web/desktop membaca `lib/firebase_options.dart`, sedangkan Android/iOS
  /// memakai berkas konfigurasi native.
  static String describeConfigurationSource() {
    if (kIsWeb) {
      return 'bagian `web` pada lib/firebase_options.dart';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android/app/google-services.json atau bagian `android` pada '
            'lib/firebase_options.dart';
      case TargetPlatform.iOS:
        return 'ios/Runner/GoogleService-Info.plist atau bagian `ios` pada '
            'lib/firebase_options.dart';
      case TargetPlatform.macOS:
        return 'bagian `macos` pada lib/firebase_options.dart';
      case TargetPlatform.windows:
        return 'bagian `windows` pada lib/firebase_options.dart';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
        return 'platform ini belum dikonfigurasi oleh `flutterfire configure` '
            '(lihat SETUP.md §2)';
    }
  }
}
