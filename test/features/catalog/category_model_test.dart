import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/constants/app_constants.dart';
import 'package:rent_camera_app/core/errors/firestore_data_exception.dart';
import 'package:rent_camera_app/features/catalog/domain/category.dart';

void main() {
  group('Category.fromFirestore', () {
    test('memetakan dokumen lengkap', () {
      final category = Category.fromFirestore('kamera', <String, dynamic>{
        'name': 'Kamera',
        'slug': 'kamera',
        'description': 'Kamera mirrorless dan DSLR.',
        'iconKey': 'camera',
        'sortOrder': 2,
        'isActive': false,
      });

      expect(category.id, 'kamera');
      expect(category.name, 'Kamera');
      expect(category.slug, 'kamera');
      expect(category.description, 'Kamera mirrorless dan DSLR.');
      expect(category.iconKey, 'camera');
      expect(category.resolvedIconKey, CategoryIconKeys.camera);
      expect(category.sortOrder, 2);
      expect(category.isActive, isFalse);
    });

    test('memakai nilai default terdokumentasi untuk field opsional', () {
      final category = Category.fromFirestore('lensa', <String, dynamic>{
        'name': 'Lensa',
        'slug': 'lensa',
      });

      expect(category.description, '');
      expect(category.iconKey, CategoryIconKeys.defaultKey);
      expect(category.resolvedIconKey, CategoryIconKeys.defaultKey);
      expect(category.sortOrder, 0);
      expect(category.isActive, isTrue);
      expect(category.createdAt, isNull);
    });

    test('iconKey tak dikenal jatuh ke ikon default', () {
      final category = Category.fromFirestore('lain', <String, dynamic>{
        'name': 'Lain-lain',
        'slug': 'lain-lain',
        'iconKey': 'ikon-yang-tidak-dikenal',
      });

      expect(category.iconKey, 'ikon-yang-tidak-dikenal');
      expect(category.resolvedIconKey, CategoryIconKeys.defaultKey);
    });

    test('menolak field wajib yang hilang atau kosong', () {
      for (final field in <String>['name', 'slug']) {
        expect(
          () => Category.fromFirestore(
            'lensa',
            <String, dynamic>{'name': 'Lensa', 'slug': 'lensa'}..remove(field),
          ),
          throwsA(
            isA<FirestoreDataException>().having(
              (error) => error.field,
              'field',
              field,
            ),
          ),
          reason: 'field $field harus ditolak saat hilang',
        );
      }

      expect(
        () => Category.fromFirestore('lensa', <String, dynamic>{
          'name': 'Lensa',
          'slug': '   ',
        }),
        throwsA(isA<FirestoreDataException>()),
      );
    });

    test('menolak sortOrder negatif atau bukan integer', () {
      expect(
        () => Category.fromFirestore('lensa', <String, dynamic>{
          'name': 'Lensa',
          'slug': 'lensa',
          'sortOrder': -1,
        }),
        throwsA(isA<FirestoreDataException>()),
      );
      expect(
        () => Category.fromFirestore('lensa', <String, dynamic>{
          'name': 'Lensa',
          'slug': 'lensa',
          'sortOrder': '1',
        }),
        throwsA(isA<FirestoreDataException>()),
      );
    });
  });
}
