import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/utils/whatsapp_checkout_link.dart';

/// Potongan nomor uji: tidak ada satu literal nomor telepon lengkap di test.
const String _code = '62';
const String _op = '812';
const String _mid = '3456';
const String _tail = '7890';

/// Nomor format internasional tanpa `+` (13 digit).
final String _international = '$_code$_op$_mid$_tail';

/// Nomor yang sama seperti ditulis pengguna, lengkap dengan pemisah.
final String _spaced = '+$_code ($_op) $_mid.$_tail';

/// Nomor format nasional (awalan `0`) yang tidak berlaku pada `wa.me`.
final String _national = '0$_op$_mid$_tail';

/// Deretan digit netral untuk menguji batas panjang nomor.
String _digitRun(int length) => List<String>.filled(length, '9').join();

void main() {
  group('WhatsAppCheckoutLink.normalizeNumber', () {
    test('membuang pemisah yang lazim ditulis pengguna', () {
      expect(WhatsAppCheckoutLink.normalizeNumber(_spaced), _international);
      expect(
        WhatsAppCheckoutLink.normalizeNumber(' $_international '),
        _international,
      );
    });

    test('menolak nomor kosong atau yang memuat karakter lain', () {
      expect(WhatsAppCheckoutLink.normalizeNumber(null), '');
      expect(WhatsAppCheckoutLink.normalizeNumber('   '), '');
      // Huruf, skema, atau pemisah tak lazim tidak ditebak menjadi nomor:
      // hasilnya kosong, bukan potongan digit yang menunjuk nomor lain.
      expect(WhatsAppCheckoutLink.normalizeNumber('$_code${_op}abc'), '');
      expect(WhatsAppCheckoutLink.normalizeNumber('wa: $_international'), '');
      expect(
        WhatsAppCheckoutLink.normalizeNumber('$_code/$_op-$_mid-$_tail'),
        '',
      );
    });
  });

  group('WhatsAppCheckoutLink.isUsableNumber', () {
    test('menerima nomor 8-15 digit tanpa awalan nasional', () {
      expect(WhatsAppCheckoutLink.isUsableNumber(_international), isTrue);
      expect(WhatsAppCheckoutLink.isUsableNumber(_spaced), isTrue);
      expect(WhatsAppCheckoutLink.isUsableNumber(_digitRun(8)), isTrue);
      expect(WhatsAppCheckoutLink.isUsableNumber(_digitRun(15)), isTrue);
    });

    test('menolak nomor yang belum dikonfigurasi atau tidak sah', () {
      expect(WhatsAppCheckoutLink.isUsableNumber(null), isFalse);
      expect(WhatsAppCheckoutLink.isUsableNumber(''), isFalse);
      expect(WhatsAppCheckoutLink.isUsableNumber('   '), isFalse);
      // Awalan nasional seperti `08...` tidak berlaku pada wa.me.
      expect(WhatsAppCheckoutLink.isUsableNumber(_national), isFalse);
      expect(WhatsAppCheckoutLink.isUsableNumber(_digitRun(7)), isFalse);
      expect(WhatsAppCheckoutLink.isUsableNumber(_digitRun(16)), isFalse);
    });
  });

  group('WhatsAppCheckoutLink.tryBuildUri', () {
    test('menyusun tautan wa.me dari nomor tanpa mengubah digitnya', () {
      final uri = WhatsAppCheckoutLink.tryBuildUri(
        number: _spaced,
        message: 'Halo, saya ingin menanyakan penyewaan alat berikut:',
      );

      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/$_international');
      expect(uri.fragment, '');
      expect(
        uri.queryParameters['text'],
        'Halo, saya ingin menanyakan penyewaan alat berikut:',
      );
      expect(uri.toString(), startsWith('https://wa.me/$_international?text='));
      expect(uri.toString(), isNot(contains(' ')));
      expect(uri.toString(), contains('%20'));
    });

    test('meng-encode baris baru dan karakter khusus pada pesan', () {
      final uri = WhatsAppCheckoutLink.tryBuildUri(
        number: _international,
        message: 'Baris 1\nRp150.000 & total #1 + selesai',
      )!;
      final raw = uri.toString();

      expect(
        uri.queryParameters['text'],
        'Baris 1\nRp150.000 & total #1 + selesai',
      );
      expect(raw, contains('%0A'));
      expect(raw, contains('%26'));
      expect(raw, contains('%23'));
      expect(raw, contains('%2B'));
      // `#` mentah memotong query menjadi fragment, sehingga pesan tidak pernah
      // boleh memuatnya.
      expect(raw, isNot(contains('#')));
    });

    test(
      'mengembalikan null bila nomor belum dikonfigurasi atau tidak sah',
      () {
        expect(
          WhatsAppCheckoutLink.tryBuildUri(number: '', message: 'Halo'),
          isNull,
        );
        expect(
          WhatsAppCheckoutLink.tryBuildUri(number: null, message: 'Halo'),
          isNull,
        );
        expect(
          WhatsAppCheckoutLink.tryBuildUri(number: _national, message: 'Halo'),
          isNull,
        );
        expect(
          WhatsAppCheckoutLink.tryBuildUri(
            number: '${_code}abc',
            message: 'Halo',
          ),
          isNull,
        );
      },
    );
  });
}
