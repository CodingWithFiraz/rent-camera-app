import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/firebase/firebase_bootstrap.dart';

/// Cabang web pada `describeConfigurationSource` tidak dapat diuji dari VM
/// (`kIsWeb` selalu false di sana), dan sebaliknya cabang platform native tidak
/// relevan saat test dijalankan di browser (`flutter test --platform chrome`).
String? _skipOnWeb() =>
    kIsWeb ? 'Deteksi web menggantikan cabang platform native.' : null;

void main() {
  group('FirebaseBootstrapStatus', () {
    test('configured: ditandai siap tanpa diagnostik', () {
      const status = FirebaseBootstrapStatus.configured();

      expect(status.isConfigured, isTrue);
      expect(status.diagnosticCode, isNull);
      expect(status.configurationSource, isNull);
    });

    test('notConfigured: menyimpan kode diagnostik dan sumber konfigurasi', () {
      const status = FirebaseBootstrapStatus.notConfigured(
        'plugin-unavailable',
        configurationSource: 'lib/firebase_options.dart',
      );

      expect(status.isConfigured, isFalse);
      expect(status.diagnosticCode, 'plugin-unavailable');
      expect(status.configurationSource, 'lib/firebase_options.dart');
    });

    test('notConfigured: sumber konfigurasi opsional', () {
      const status = FirebaseBootstrapStatus.notConfigured(
        'options-unavailable',
      );

      expect(status.isConfigured, isFalse);
      expect(status.configurationSource, isNull);
    });
  });

  group('FirebaseBootstrap.diagnosticCodeFor', () {
    test('FirebaseException memakai code SDK apa adanya', () {
      expect(
        FirebaseBootstrap.diagnosticCodeFor(
          FirebaseException(
            plugin: 'core',
            code: 'no-app',
            message: 'No Firebase App has been created',
          ),
        ),
        'no-app',
      );
    });

    test('FlutterError berarti binding Flutter belum siap', () {
      // `FlutterError` mengimplementasikan `AssertionError`, sehingga cabang ini
      // harus tepat: kegagalannya bukan soal opsi Firebase.
      expect(
        FirebaseBootstrap.diagnosticCodeFor(
          FlutterError('Binding has not yet been initialized.'),
        ),
        'flutter-binding-unavailable',
      );
    });

    test('UnsupportedError berarti platform belum dikonfigurasi', () {
      expect(
        FirebaseBootstrap.diagnosticCodeFor(
          UnsupportedError('not configured for linux'),
        ),
        'unsupported-platform',
      );
    });

    test('AssertionError berarti opsi Firebase tidak tersedia', () {
      expect(
        FirebaseBootstrap.diagnosticCodeFor(
          AssertionError('FirebaseOptions cannot be null'),
        ),
        'options-unavailable',
      );
    });

    test('MissingPluginException berarti plugin belum terdaftar', () {
      expect(
        FirebaseBootstrap.diagnosticCodeFor(MissingPluginException()),
        'plugin-unavailable',
      );
    });

    test('PlatformException channel-error berarti plugin belum terdaftar', () {
      expect(
        FirebaseBootstrap.diagnosticCodeFor(
          PlatformException(code: 'channel-error', message: 'no connection'),
        ),
        'plugin-unavailable',
      );
    });

    test('PlatformException lain tidak diklaim sebagai plugin hilang', () {
      expect(
        FirebaseBootstrap.diagnosticCodeFor(
          PlatformException(code: 'invalid-api-key'),
        ),
        'initialization-failed',
      );
    });

    test('tidak membocorkan nama tipe exception pada kegagalan umum', () {
      final String code = FirebaseBootstrap.diagnosticCodeFor(
        StateError('boom'),
      );

      expect(code, 'initialization-failed');
      expect(code, isNot(contains('StateError')));
    });
  });

  group('FirebaseBootstrap.describeConfigurationSource', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('android memakai google-services.json atau opsi android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(
        FirebaseBootstrap.describeConfigurationSource(),
        contains('google-services.json'),
      );
    }, skip: _skipOnWeb());

    test('iOS memakai GoogleService-Info.plist atau opsi ios', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      expect(
        FirebaseBootstrap.describeConfigurationSource(),
        contains('GoogleService-Info.plist'),
      );
    }, skip: _skipOnWeb());

    test('macOS memakai opsi macos pada firebase_options.dart', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      expect(
        FirebaseBootstrap.describeConfigurationSource(),
        contains('macos'),
      );
    }, skip: _skipOnWeb());

    test('windows memakai opsi windows pada firebase_options.dart', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      expect(
        FirebaseBootstrap.describeConfigurationSource(),
        contains('windows'),
      );
    }, skip: _skipOnWeb());

    test('linux dilaporkan belum dikonfigurasi oleh flutterfire configure', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      expect(
        FirebaseBootstrap.describeConfigurationSource(),
        contains('belum dikonfigurasi'),
      );
    }, skip: _skipOnWeb());
  });

  group('FirebaseBootstrap.initialize', () {
    // Binding Flutter wajib siap sebelum bootstrap, sama seperti `lib/main.dart`
    // memanggil `WidgetsFlutterBinding.ensureInitialized()` sebelum
    // [FirebaseBootstrap.initialize]. Tanpa binding, kegagalannya bukan soal
    // konfigurasi melainkan `flutter-binding-unavailable`.
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    // Kontrak bootstrap: tidak pernah melempar exception. Pada VM test sudah ada
    // binding tetapi tidak ada plugin Firebase terdaftar, sehingga kegagalannya
    // berupa `PlatformException(channel-error)`; di browser Firebase justru
    // berhasil memakai `DefaultFirebaseOptions.web`.
    test('melaporkan status, bukan melempar exception', () async {
      final FirebaseBootstrapStatus status =
          await FirebaseBootstrap.initialize();

      if (kIsWeb) {
        expect(status.isConfigured, isTrue);
        expect(status.diagnosticCode, isNull);
        expect(status.configurationSource, isNull);
      } else {
        expect(status.isConfigured, isFalse);
        expect(status.diagnosticCode, 'plugin-unavailable');
        expect(status.configurationSource, isNotNull);
      }
    });
  });
}
