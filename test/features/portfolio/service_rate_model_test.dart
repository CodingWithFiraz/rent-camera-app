import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/errors/firestore_data_exception.dart';
import 'package:rent_camera_app/features/catalog/domain/price_unit.dart';
import 'package:rent_camera_app/features/portfolio/domain/service_rate.dart';

void main() {
  group('ServiceRate.fromFirestore', () {
    test('memetakan dokumen lengkap', () {
      final rate = ServiceRate.fromFirestore('foto-produk', <String, dynamic>{
        'title': 'Foto Produk',
        'description': 'Sesi foto produk.',
        'rateLabel': 'Mulai dari',
        'startingPrice': 500000,
        'priceUnit': 'per_session',
        'deliverables': <String>['20 foto editan'],
        'sortOrder': 1,
        'isActive': true,
      });

      expect(rate.id, 'foto-produk');
      expect(rate.title, 'Foto Produk');
      expect(rate.description, 'Sesi foto produk.');
      expect(rate.rateLabel, 'Mulai dari');
      expect(rate.startingPrice, 500000);
      expect(rate.priceUnit, PriceUnit.perSession);
      expect(rate.hasConfiguredPriceUnit, isTrue);
      expect(rate.deliverables, <String>['20 foto editan']);
      expect(rate.sortOrder, 1);
      expect(rate.hasConfiguredRate, isTrue);
    });

    test('rate kosong tetap keadaan "belum dikonfigurasi"', () {
      final rate = ServiceRate.fromFirestore('video-profil', <String, dynamic>{
        'title': 'Video Profil',
        'rateLabel': '',
        'startingPrice': null,
        'priceUnit': '',
      });

      expect(rate.startingPrice, isNull);
      expect(rate.priceUnit, PriceUnit.unspecified);
      expect(rate.hasConfiguredPriceUnit, isFalse);
      expect(rate.hasConfiguredRate, isFalse);
      expect(rate.deliverables, isEmpty);
      expect(rate.sortOrder, 0);
      expect(rate.isActive, isTrue);
    });

    test('harga awal nol belum dianggap sebagai rate terkonfigurasi', () {
      final rate = ServiceRate.fromFirestore('video-profil', <String, dynamic>{
        'title': 'Video Profil',
        'startingPrice': 0,
      });

      expect(rate.startingPrice, 0);
      expect(rate.hasConfiguredRate, isFalse);
    });

    test('label rate saja sudah cukup untuk dianggap terkonfigurasi', () {
      final rate = ServiceRate.fromFirestore('video-profil', <String, dynamic>{
        'title': 'Video Profil',
        'rateLabel': 'Hubungi kami',
      });

      expect(rate.hasConfiguredRate, isTrue);
    });

    test('menolak judul yang hilang atau kosong', () {
      expect(
        () => ServiceRate.fromFirestore('s1', <String, dynamic>{
          'rateLabel': 'Mulai dari',
        }),
        throwsA(
          isA<FirestoreDataException>().having(
            (error) => error.field,
            'field',
            'title',
          ),
        ),
      );
      expect(
        () => ServiceRate.fromFirestore('s1', <String, dynamic>{'title': ' '}),
        throwsA(isA<FirestoreDataException>()),
      );
    });

    test('menolak mulai harga yang negatif atau bukan integer', () {
      expect(
        () => ServiceRate.fromFirestore('s1', <String, dynamic>{
          'title': 'Video Profil',
          'startingPrice': -1,
        }),
        throwsA(isA<FirestoreDataException>()),
      );
      expect(
        () => ServiceRate.fromFirestore('s1', <String, dynamic>{
          'title': 'Video Profil',
          'startingPrice': 1000.5,
        }),
        throwsA(isA<FirestoreDataException>()),
      );
    });

    test('menolak deliverables yang memuat bukan teks', () {
      expect(
        () => ServiceRate.fromFirestore('s1', <String, dynamic>{
          'title': 'Video Profil',
          'deliverables': <Object>['1 video', 2],
        }),
        throwsA(isA<FirestoreDataException>()),
      );
    });
  });
}
