import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/features/admin/domain/admin_access.dart';
import 'package:rent_camera_app/features/admin/domain/admin_guard.dart';
import 'package:rent_camera_app/core/routing/app_routes.dart';

/// Test route guard admin (`docs/BLUEPRINT_APLIKASI.md` §9).
///
/// Guard ini hanya mengatur navigasi; penolakan tulis yang sebenarnya tetap
/// dilakukan Firestore/Storage Rules. Test di bawah membuktikan guard
/// **fail closed** tanpa menghubungi Firebase.
void main() {
  group('isAdminRoute', () {
    test('mengenali route admin beserta sub-route-nya', () {
      expect(isAdminRoute(AppRoutes.admin), isTrue);
      expect(isAdminRoute('${AppRoutes.admin}/produk/baru'), isTrue);
      expect(isAdminRoute('  ${AppRoutes.admin}  '), isTrue);
    });

    test('tidak menganggap route lain sebagai area admin', () {
      expect(isAdminRoute(AppRoutes.catalog), isFalse);
      expect(isAdminRoute('/administrasi'), isFalse);
      expect(isAdminRoute('/adminpanel'), isFalse);
      expect(isAdminRoute(''), isFalse);
    });
  });

  group('resolveAdminRedirect', () {
    test('denied pada route admin dialihkan ke katalog', () {
      expect(
        resolveAdminRedirect(
          location: AppRoutes.admin,
          access: AdminAccessStatus.denied,
        ),
        AppRoutes.catalog,
      );
      expect(
        resolveAdminRedirect(
          location: '${AppRoutes.admin}/produk/baru',
          access: AdminAccessStatus.denied,
        ),
        AppRoutes.catalog,
      );
    });

    test('unknown tidak dialihkan karena pemeriksaan belum selesai', () {
      expect(
        resolveAdminRedirect(
          location: AppRoutes.admin,
          access: AdminAccessStatus.unknown,
        ),
        isNull,
      );
    });

    test('granted tidak dialihkan', () {
      expect(
        resolveAdminRedirect(
          location: AppRoutes.admin,
          access: AdminAccessStatus.granted,
        ),
        isNull,
      );
    });

    test('route non-admin tidak pernah diubah', () {
      for (final access in AdminAccessStatus.values) {
        expect(
          resolveAdminRedirect(location: AppRoutes.portfolio, access: access),
          isNull,
          reason: 'route portofolio tidak boleh dialihkan saat $access',
        );
      }
    });
  });
}
