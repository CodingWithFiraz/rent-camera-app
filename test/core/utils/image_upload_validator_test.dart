import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/utils/image_upload_validator.dart';

void main() {
  group('ImageUploadValidator.validate', () {
    test('menerima ekstensi gambar yang didukung', () {
      final Map<String, String> expected = <String, String>{
        'foto.jpg': 'image/jpeg',
        'foto.jpeg': 'image/jpeg',
        'foto.PNG': 'image/png',
        'foto.webp': 'image/webp',
        'foto.besar.JPG': 'image/jpeg',
      };
      for (final MapEntry<String, String> entry in expected.entries) {
        final result = ImageUploadValidator.validate(
          fileName: entry.key,
          sizeBytes: 1024,
        );
        expect(result.isValid, isTrue, reason: '${entry.key} harus diterima');
        expect(result.contentType, entry.value);
        expect(result.errorMessage, isNull);
      }
    });

    test('menerima tipe MIME bila nama berkas tanpa ekstensi dikenal', () {
      final result = ImageUploadValidator.validate(
        fileName: 'image_picker_sementara',
        sizeBytes: 2048,
        mimeType: 'image/jpeg',
      );

      expect(result.isValid, isTrue);
      expect(result.contentType, 'image/jpeg');
    });

    test('menolak format yang tidak didukung', () {
      for (final String name in <String>[
        'dokumen.pdf',
        'gambar.gif',
        'arsip.zip',
        'tanpaekstensi',
      ]) {
        final result = ImageUploadValidator.validate(
          fileName: name,
          sizeBytes: 1024,
        );
        expect(result.isValid, isFalse, reason: '$name harus ditolak');
        expect(result.errorMessage, 'Format foto harus JPG, PNG, atau WEBP.');
        expect(result.contentType, isNull);
      }
    });

    test('menolak berkas yang tidak berisi data', () {
      final result = ImageUploadValidator.validate(
        fileName: 'foto.jpg',
        sizeBytes: 0,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('tidak berisi data'));
    });

    test('menolak berkas yang melebihi batas ukuran', () {
      final result = ImageUploadValidator.validate(
        fileName: 'foto.jpg',
        sizeBytes: ImageUploadValidator.maxSizeBytes + 1,
      );

      expect(result.isValid, isFalse);
      expect(
        result.errorMessage,
        contains('${ImageUploadValidator.maxSizeMb} MB'),
      );
    });

    test('menerima berkas tepat pada batas ukuran', () {
      final result = ImageUploadValidator.validate(
        fileName: 'foto.jpg',
        sizeBytes: ImageUploadValidator.maxSizeBytes,
      );

      expect(result.isValid, isTrue);
    });

    test(
      'tipe MIME yang tidak didukung ditolak walau namanya tanpa ekstensi',
      () {
        final result = ImageUploadValidator.validate(
          fileName: 'gambar',
          sizeBytes: 1024,
          mimeType: 'application/pdf',
        );

        expect(result.isValid, isFalse);
      },
    );
  });

  group('ImageUploadValidator.extensionOf', () {
    test('mengambil ekstensi dari nama berkas tanpa memakai folder', () {
      expect(ImageUploadValidator.extensionOf('/tmp/kamera/foto.1.JPG'), 'jpg');
      expect(ImageUploadValidator.extensionOf(r'..\..\rahasia.txt'), 'txt');
      expect(ImageUploadValidator.extensionOf('foto.'), '');
      expect(ImageUploadValidator.extensionOf('.hidden'), '');
      expect(ImageUploadValidator.extensionOf('FOTO'), '');
    });
  });

  group('ImageUploadValidator.contentTypeForMimeType', () {
    test('menormalkan huruf besar dan spasi', () {
      expect(
        ImageUploadValidator.contentTypeForMimeType(' ImAge/PNG '),
        'image/png',
      );
      expect(ImageUploadValidator.contentTypeForMimeType(null), isNull);
      expect(ImageUploadValidator.contentTypeForMimeType('image/gif'), isNull);
    });
  });
}
