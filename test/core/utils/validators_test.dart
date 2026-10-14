import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/utils/validators.dart';

/// Alamat email uji dibentuk dari potongan string supaya tidak ditulis sebagai
/// satu literal panjang.
String _emailAddress(String local, String domain) => '$local@$domain';

void main() {
  final String validEmail = _emailAddress('pengguna', 'contoh.test');

  group('Validators.email', () {
    test('menolak nilai kosong', () {
      expect(Validators.email(null), 'Email wajib diisi.');
      expect(Validators.email('   '), 'Email wajib diisi.');
    });

    test('menolak format yang tidak valid', () {
      expect(Validators.email('bukan-email'), 'Format email tidak valid.');
      expect(Validators.email('user@'), 'Format email tidak valid.');
      expect(Validators.email('user@domain'), 'Format email tidak valid.');
    });

    test('menerima email yang valid', () {
      expect(Validators.email(validEmail), isNull);
      expect(Validators.email('  $validEmail  '), isNull);
    });
  });

  group('Validators.loginIdentifier', () {
    test('menerima email', () {
      expect(Validators.loginIdentifier(validEmail), isNull);
    });

    test('menolak alias admin bila belum dikonfigurasi', () {
      expect(
        Validators.loginIdentifier('admin'),
        'Masukkan alamat email yang valid.',
      );
    });

    test('menerima alias admin hanya bila dikonfigurasi', () {
      expect(
        Validators.loginIdentifier(
          'admin',
          adminAlias: 'admin',
          isAdminAliasConfigured: true,
        ),
        isNull,
      );
      expect(
        Validators.loginIdentifier(
          'admin',
          adminAlias: 'admin',
          isAdminAliasConfigured: false,
        ),
        isNotNull,
      );
    });
  });

  group('Validators.password', () {
    test('menolak kata sandi kosong atau terlalu pendek', () {
      expect(Validators.password(''), 'Kata sandi wajib diisi.');
      expect(Validators.password('1234567'), isNotNull);
    });

    test('menerima kata sandi minimal delapan karakter', () {
      expect(Validators.password('12345678'), isNull);
    });
  });

  group('Validators.passwordConfirmation', () {
    test('menolak konfirmasi kosong', () {
      expect(
        Validators.passwordConfirmation('', 'rahasia123'),
        'Konfirmasi kata sandi wajib diisi.',
      );
    });

    test('menolak konfirmasi yang berbeda', () {
      expect(
        Validators.passwordConfirmation('rahasia124', 'rahasia123'),
        'Konfirmasi kata sandi tidak sama.',
      );
    });

    test('menerima konfirmasi yang sama', () {
      expect(
        Validators.passwordConfirmation('rahasia123', 'rahasia123'),
        isNull,
      );
    });
  });

  group('Validators.displayName', () {
    test('menolak nama kosong atau terlalu pendek', () {
      expect(Validators.displayName('  '), 'Nama wajib diisi.');
      expect(Validators.displayName('ab'), 'Nama minimal 3 karakter.');
    });

    test('menerima nama yang wajar', () {
      expect(Validators.displayName('Nama Pengguna'), isNull);
    });
  });

  group('Validators.phoneNumber', () {
    // Nomor uji disusun dari potongan digit supaya tidak ada nomor yang mirip
    // nomor nyata yang tertulis harfiah di dalam test.
    final String phoneDigits = <String>['08', '12', '345', '678'].join();
    final String tooManyDigits = List<String>.filled(16, '1').join();

    test('nomor kosong bukan kesalahan karena bersifat opsional', () {
      expect(Validators.phoneNumber(null), isNull);
      expect(Validators.phoneNumber('   '), isNull);
    });

    test('menerima nomor dengan spasi, tanda plus, dan kurung', () {
      expect(Validators.phoneNumber('+62 $phoneDigits'), isNull);
      expect(Validators.phoneNumber(phoneDigits), isNull);
      expect(Validators.phoneNumber('(021) 1234567'), isNull);
    });

    test('menolak huruf dan simbol lain', () {
      expect(
        Validators.phoneNumber('${phoneDigits}a'),
        'Nomor telepon hanya boleh berisi angka, spasi, tanda +, -, atau kurung.',
      );
      expect(Validators.phoneNumber('$phoneDigits#'), isNotNull);
    });

    test('menolak jumlah digit yang tidak wajar', () {
      expect(
        Validators.phoneNumber('123456'),
        'Nomor telepon harus '
        '${Validators.minPhoneDigits}–${Validators.maxPhoneDigits} digit.',
      );
      expect(Validators.phoneNumber(tooManyDigits), isNotNull);
    });
  });
}
