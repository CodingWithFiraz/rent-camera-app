import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/errors/firestore_data_exception.dart';
import 'package:rent_camera_app/features/portfolio/domain/creative.dart';

void main() {
  group('Creative.fromFirestore', () {
    test('memetakan dokumen lengkap', () {
      final creative = Creative.fromFirestore('kreator-1', <String, dynamic>{
        'name': 'Kreator Uji',
        'roleTitle': 'Fotografer',
        'specialties': <String>['Foto produk', 'Foto acara'],
        'photoUrl': 'https://contoh.test/kreator-1.jpg',
        'portfolioUrl': 'https://contoh.test/portofolio-1',
        'sortOrder': 2,
        'isActive': true,
      });

      expect(creative.id, 'kreator-1');
      expect(creative.name, 'Kreator Uji');
      expect(creative.roleTitle, 'Fotografer');
      expect(creative.specialties, <String>['Foto produk', 'Foto acara']);
      expect(creative.photoUrl, 'https://contoh.test/kreator-1.jpg');
      expect(creative.hasPhoto, isTrue);
      expect(creative.portfolioUrl, 'https://contoh.test/portofolio-1');
      expect(creative.hasPortfolioUrl, isTrue);
      expect(creative.sortOrder, 2);
      expect(creative.isActive, isTrue);
    });

    test('aset yang belum diisi pemilik tetap kosong, bukan dikarang', () {
      final creative = Creative.fromFirestore('kreator-2', <String, dynamic>{
        'name': 'Kreator Dua',
      });

      expect(creative.roleTitle, '');
      expect(creative.specialties, isEmpty);
      expect(creative.photoUrl, '');
      expect(creative.hasPhoto, isFalse);
      expect(creative.portfolioUrl, '');
      expect(creative.hasPortfolioUrl, isFalse);
      expect(creative.sortOrder, 0);
      expect(creative.isActive, isTrue);
      expect(creative.createdAt, isNull);
    });

    test('menolak nama yang hilang atau kosong', () {
      expect(
        () => Creative.fromFirestore('kreator-1', <String, dynamic>{
          'roleTitle': 'Fotografer',
        }),
        throwsA(
          isA<FirestoreDataException>().having(
            (error) => error.field,
            'field',
            'name',
          ),
        ),
      );
      expect(
        () => Creative.fromFirestore('kreator-1', <String, dynamic>{
          'name': '  ',
        }),
        throwsA(isA<FirestoreDataException>()),
      );
    });

    test('menolak field bertipe salah', () {
      expect(
        () => Creative.fromFirestore('kreator-1', <String, dynamic>{
          'name': 'Kreator',
          'specialties': <Object>['Foto produk', 1],
        }),
        throwsA(isA<FirestoreDataException>()),
      );
      expect(
        () => Creative.fromFirestore('kreator-1', <String, dynamic>{
          'name': 'Kreator',
          'photoUrl': 42,
        }),
        throwsA(isA<FirestoreDataException>()),
      );
      expect(
        () => Creative.fromFirestore('kreator-1', <String, dynamic>{
          'name': 'Kreator',
          'sortOrder': -1,
        }),
        throwsA(isA<FirestoreDataException>()),
      );
    });
  });
}
