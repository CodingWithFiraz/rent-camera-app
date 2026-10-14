import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/errors/app_exception.dart';
import 'package:rent_camera_app/features/auth/data/auth_repository.dart';

/// Alamat email uji dibentuk dari potongan string supaya tidak ditulis sebagai
/// satu literal panjang.
String _emailAddress(String local, String domain) => '$local@$domain';

void main() {
  group('resolveSignInEmail', () {
    test('menormalkan email menjadi huruf kecil', () {
      expect(
        resolveSignInEmail(_emailAddress('Pengguna', 'Contoh.Test')),
        _emailAddress('pengguna', 'contoh.test'),
      );
    });

    test('memetakan alias admin ke email admin yang dikonfigurasi', () {
      expect(
        resolveSignInEmail(
          'admin',
          adminAlias: 'admin',
          adminEmail: _emailAddress('admin', 'contoh.test'),
        ),
        _emailAddress('admin', 'contoh.test'),
      );
    });

    test('menolak alias admin bila email admin belum dikonfigurasi', () {
      expect(
        () => resolveSignInEmail('admin', adminAlias: 'admin', adminEmail: ''),
        throwsA(isA<AppException>()),
      );
    });

    test('menolak identitas kosong atau bukan email', () {
      expect(() => resolveSignInEmail('   '), throwsA(isA<AppException>()));
      expect(
        () => resolveSignInEmail('bukan-email'),
        throwsA(isA<AppException>()),
      );
    });
  });
}
