import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/errors/firestore_data_exception.dart';
import 'package:rent_camera_app/features/catalog/domain/banner.dart';

void main() {
  group('BannerTargetType.fromStorage', () {
    test('memetakan nilai yang dikenal', () {
      expect(
        BannerTargetType.fromStorage('portfolio'),
        BannerTargetType.portfolio,
      );
      expect(
        BannerTargetType.fromStorage('category'),
        BannerTargetType.category,
      );
      expect(
        BannerTargetType.fromStorage('externalUrl'),
        BannerTargetType.externalUrl,
      );
    });

    test('nilai kosong, bukan teks, atau tak dikenal menjadi unknown', () {
      expect(BannerTargetType.fromStorage(null), BannerTargetType.unknown);
      expect(BannerTargetType.fromStorage(''), BannerTargetType.unknown);
      expect(BannerTargetType.fromStorage(7), BannerTargetType.unknown);
      expect(
        BannerTargetType.fromStorage('keranjang'),
        BannerTargetType.unknown,
      );
    });
  });

  group('Banner.fromFirestore', () {
    test('memetakan dokumen lengkap', () {
      final banner = Banner.fromFirestore('banner-promo', <String, dynamic>{
        'title': 'Sewa Kamera',
        'imageUrl': 'https://contoh.test/banner-1.jpg',
        'targetType': 'category',
        'targetValue': 'kamera',
        'sortOrder': 1,
        'isActive': true,
      });

      expect(banner.id, 'banner-promo');
      expect(banner.title, 'Sewa Kamera');
      expect(banner.imageUrl, 'https://contoh.test/banner-1.jpg');
      expect(banner.targetType, BannerTargetType.category);
      expect(banner.targetValue, 'kamera');
      expect(banner.sortOrder, 1);
      expect(banner.isActive, isTrue);
      expect(banner.hasNavigableTarget, isTrue);
    });

    test('memakai nilai default terdokumentasi untuk field opsional', () {
      final banner = Banner.fromFirestore('banner-kosong', <String, dynamic>{
        'title': 'Belum Diisi',
      });

      expect(banner.imageUrl, '');
      expect(banner.targetType, BannerTargetType.unknown);
      expect(banner.targetValue, '');
      expect(banner.sortOrder, 0);
      expect(banner.isActive, isTrue);
      expect(banner.hasNavigableTarget, isFalse);
    });

    test('banner portfolio selalu dapat dinavigasikan', () {
      final banner = Banner.fromFirestore(
        'banner-portofolio',
        <String, dynamic>{'title': 'Portofolio', 'targetType': 'portfolio'},
      );

      expect(banner.targetType, BannerTargetType.portfolio);
      expect(banner.targetValue, '');
      expect(banner.hasNavigableTarget, isTrue);
    });

    test('banner tanpa targetValue tidak dianggap dapat dinavigasikan', () {
      final categoryBanner = Banner.fromFirestore('b1', <String, dynamic>{
        'title': 'Kategori',
        'targetType': 'category',
      });
      final urlBanner = Banner.fromFirestore('b2', <String, dynamic>{
        'title': 'Tautan',
        'targetType': 'externalUrl',
      });
      final urlTerisi = Banner.fromFirestore('b3', <String, dynamic>{
        'title': 'Tautan',
        'targetType': 'externalUrl',
        'targetValue': 'https://contoh.test/promo',
      });

      expect(categoryBanner.hasNavigableTarget, isFalse);
      expect(urlBanner.hasNavigableTarget, isFalse);
      expect(urlTerisi.hasNavigableTarget, isTrue);
    });

    test('menolak judul yang hilang atau kosong', () {
      expect(
        () => Banner.fromFirestore('b1', <String, dynamic>{'imageUrl': 'x'}),
        throwsA(
          isA<FirestoreDataException>().having(
            (error) => error.field,
            'field',
            'title',
          ),
        ),
      );
      expect(
        () => Banner.fromFirestore('b1', <String, dynamic>{'title': '  '}),
        throwsA(isA<FirestoreDataException>()),
      );
    });

    test('menolak tipe field yang salah', () {
      expect(
        () => Banner.fromFirestore('b1', <String, dynamic>{
          'title': 'Banner',
          'sortOrder': -2,
        }),
        throwsA(isA<FirestoreDataException>()),
      );
      expect(
        () => Banner.fromFirestore('b1', <String, dynamic>{
          'title': 'Banner',
          'isActive': 'aktif',
        }),
        throwsA(isA<FirestoreDataException>()),
      );
      expect(
        () => Banner.fromFirestore('b1', <String, dynamic>{
          'title': 'Banner',
          'targetValue': 12,
        }),
        throwsA(isA<FirestoreDataException>()),
      );
    });
  });
}
