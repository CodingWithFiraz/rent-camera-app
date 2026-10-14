import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/routing/app_routes.dart';
import 'package:rent_camera_app/core/routing/auth_guard.dart';

void main() {
  group('resolveAuthRedirect — Firebase belum dikonfigurasi', () {
    test('semua lokasi diarahkan ke layar setup', () {
      for (final String location in <String>[
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.catalog,
      ]) {
        expect(
          resolveAuthRedirect(
            location: location,
            isFirebaseConfigured: false,
            sessionStatus: AuthSessionStatus.signedOut,
          ),
          AppRoutes.setupRequired,
          reason: 'lokasi $location seharusnya diarahkan ke layar setup',
        );
      }
    });

    test('layar setup tidak diarahkan ulang', () {
      expect(
        resolveAuthRedirect(
          location: AppRoutes.setupRequired,
          isFirebaseConfigured: false,
          sessionStatus: AuthSessionStatus.signedOut,
        ),
        isNull,
      );
    });
  });

  group('resolveAuthRedirect — sesi belum diketahui', () {
    test('menahan pengguna pada splash', () {
      expect(
        resolveAuthRedirect(
          location: AppRoutes.splash,
          isFirebaseConfigured: true,
          sessionStatus: AuthSessionStatus.unknown,
        ),
        isNull,
      );
    });

    test('mengembalikan ke splash dari route terproteksi', () {
      expect(
        resolveAuthRedirect(
          location: AppRoutes.catalog,
          isFirebaseConfigured: true,
          sessionStatus: AuthSessionStatus.unknown,
        ),
        AppRoutes.splash,
      );
    });
  });

  group('resolveAuthRedirect — belum login', () {
    test('route publik auth boleh dibuka', () {
      for (final String location in <String>[
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ]) {
        expect(
          resolveAuthRedirect(
            location: location,
            isFirebaseConfigured: true,
            sessionStatus: AuthSessionStatus.signedOut,
          ),
          isNull,
        );
      }
    });

    test('route terproteksi dialihkan ke login', () {
      expect(
        resolveAuthRedirect(
          location: AppRoutes.catalog,
          isFirebaseConfigured: true,
          sessionStatus: AuthSessionStatus.signedOut,
        ),
        AppRoutes.login,
      );
      expect(
        resolveAuthRedirect(
          location: '/route-baru-yang-belum-didaftarkan',
          isFirebaseConfigured: true,
          sessionStatus: AuthSessionStatus.signedOut,
        ),
        AppRoutes.login,
        reason: 'guard bersifat default-deny untuk route tak dikenal',
      );
    });
  });

  group('resolveAuthRedirect — sudah login', () {
    test('route auth publik dialihkan ke katalog', () {
      for (final String location in <String>[
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ]) {
        expect(
          resolveAuthRedirect(
            location: location,
            isFirebaseConfigured: true,
            sessionStatus: AuthSessionStatus.signedIn,
          ),
          AppRoutes.catalog,
        );
      }
    });

    test('route terproteksi boleh dibuka', () {
      expect(
        resolveAuthRedirect(
          location: AppRoutes.catalog,
          isFirebaseConfigured: true,
          sessionStatus: AuthSessionStatus.signedIn,
        ),
        isNull,
      );
    });

    test('layar setup tidak dipakai saat sudah login', () {
      expect(
        resolveAuthRedirect(
          location: AppRoutes.setupRequired,
          isFirebaseConfigured: true,
          sessionStatus: AuthSessionStatus.signedIn,
        ),
        AppRoutes.catalog,
      );
    });
  });

  group('klasifikasi route', () {
    test('route publik auth dikenali', () {
      expect(isPublicAuthRoute(AppRoutes.login), isTrue);
      expect(isPublicAuthRoute(AppRoutes.register), isTrue);
      expect(isPublicAuthRoute(AppRoutes.forgotPassword), isTrue);
      expect(isPublicAuthRoute(AppRoutes.catalog), isFalse);
    });

    test('route terproteksi dikenali', () {
      expect(isProtectedRoute(AppRoutes.catalog), isTrue);
      expect(isProtectedRoute('/admin'), isTrue);
      expect(isProtectedRoute(AppRoutes.login), isFalse);
      expect(isProtectedRoute(AppRoutes.splash), isFalse);
      expect(isProtectedRoute(AppRoutes.setupRequired), isFalse);
    });
  });
}
