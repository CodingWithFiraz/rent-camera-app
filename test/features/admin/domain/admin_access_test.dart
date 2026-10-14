import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/features/admin/domain/admin_access.dart';

/// Test pembacaan custom claim admin (`docs/BLUEPRINT_APLIKASI.md` §9).
///
/// Keputusan izin harus **fail closed**: apa pun yang bukan boolean `true`
/// dianggap bukan admin, karena Security Rules membandingkan
/// `request.auth.token.admin == true`.
void main() {
  group('AdminAccess.isAdminClaim', () {
    test('menerima hanya boolean true', () {
      expect(AdminAccess.isAdminClaim(true), isTrue);
    });

    test('menolak nilai bertipe lain atau bernilai false', () {
      expect(AdminAccess.isAdminClaim(false), isFalse);
      expect(AdminAccess.isAdminClaim(null), isFalse);
      expect(AdminAccess.isAdminClaim('true'), isFalse);
      expect(AdminAccess.isAdminClaim('1'), isFalse);
      expect(AdminAccess.isAdminClaim(1), isFalse);
      expect(AdminAccess.isAdminClaim(<String, dynamic>{}), isFalse);
    });
  });

  group('AdminAccess.fromClaims', () {
    test('claim admin true menghasilkan status granted', () {
      final access = AdminAccess.fromClaims(<String, dynamic>{'admin': true});
      expect(access.status, AdminAccessStatus.granted);
      expect(access.isGranted, isTrue);
      expect(access.isDenied, isFalse);
    });

    test('tanpa sesi login (claims null) akses ditolak', () {
      final access = AdminAccess.fromClaims(null);
      expect(access.status, AdminAccessStatus.denied);
      expect(access.isDenied, isTrue);
    });

    test('claim hilang, false, atau bertipe salah ditolak', () {
      final claims = <Map<String, dynamic>>[
        <String, dynamic>{},
        <String, dynamic>{'admin': false},
        <String, dynamic>{'admin': 'true'},
        <String, dynamic>{'admin': 1},
        <String, dynamic>{'admin': null},
        <String, dynamic>{'isAdmin': true},
      ];
      for (final entry in claims) {
        expect(
          AdminAccess.fromClaims(entry).status,
          AdminAccessStatus.denied,
          reason: 'claims $entry seharusnya ditolak',
        );
      }
    });

    test('status unknown berarti belum diperiksa, bukan izin', () {
      const access = AdminAccess.unknown();
      expect(access.status, AdminAccessStatus.unknown);
      expect(access.isGranted, isFalse);
      expect(access.isDenied, isFalse);
    });
  });

  test('nama claim sama dengan yang diperiksa rules dan aplikasi', () {
    expect(adminClaimKey, 'admin');
  });
}
