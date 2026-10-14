import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/features/catalog/domain/banner.dart';
import 'package:rent_camera_app/features/catalog/domain/banner_selection.dart';

Banner _banner(
  String id, {
  BannerTargetType targetType = BannerTargetType.portfolio,
  String targetValue = '',
}) => Banner(
  id: id,
  title: 'Banner $id',
  targetType: targetType,
  targetValue: targetValue,
);

void main() {
  group('BannerSelection.from', () {
    test('membatasi slide menjadi tiga dan mencatat sisa banner', () {
      final selection = BannerSelection.from(<Banner>[
        _banner('a'),
        _banner('b'),
        _banner('c'),
        _banner('d'),
      ]);

      expect(selection.slides.length, BannerSelection.maxSlides);
      expect(selection.slides.first.id, 'a');
      expect(selection.ignoredCount, 1);
      expect(selection.isEmpty, isFalse);
    });

    test('tanpa banner aktif menghasilkan carousel kosong', () {
      final selection = BannerSelection.from(const <Banner>[]);

      expect(selection.isEmpty, isTrue);
      expect(selection.slides, isEmpty);
      expect(selection.ignoredCount, 0);
      expect(selection.isComplete, isFalse);
    });

    test('urutan dari repository dipertahankan', () {
      final selection = BannerSelection.from(<Banner>[
        _banner('pertama'),
        _banner('kedua'),
      ]);

      expect(
        selection.slides.map((Banner banner) => banner.id).toList(),
        <String>['pertama', 'kedua'],
      );
    });
  });

  group('pemeriksaan konfigurasi banner', () {
    test('mendeteksi slide yang menuju Portofolio', () {
      final selection = BannerSelection.from(<Banner>[
        _banner(
          'kategori',
          targetType: BannerTargetType.category,
          targetValue: 'kamera',
        ),
        _banner('portofolio'),
      ]);

      expect(selection.hasPortfolioSlide, isTrue);
    });

    test('banner tanpa tujuan valid dilaporkan tidak dapat ditekan', () {
      final selection = BannerSelection.from(<Banner>[
        _banner(
          'kategori',
          targetType: BannerTargetType.category,
          targetValue: 'kamera',
        ),
        _banner('belum-diatur', targetType: BannerTargetType.unknown),
      ]);

      expect(selection.hasNonNavigableSlide, isTrue);
      expect(selection.hasPortfolioSlide, isFalse);
    });

    test(
      'banner kategori/tautan tanpa targetValue juga tidak dapat ditekan',
      () {
        final selection = BannerSelection.from(<Banner>[
          _banner('kategori', targetType: BannerTargetType.category),
          _banner('tautan', targetType: BannerTargetType.externalUrl),
        ]);

        expect(selection.hasNonNavigableSlide, isTrue);
      },
    );

    test('isComplete hanya saat tiga slide dan ada Portofolio', () {
      final lengkap = BannerSelection.from(<Banner>[
        _banner('a'),
        _banner(
          'b',
          targetType: BannerTargetType.category,
          targetValue: 'kamera',
        ),
        _banner(
          'c',
          targetType: BannerTargetType.externalUrl,
          targetValue: 'https://contoh.test/promo',
        ),
      ]);
      final tanpaPortofolio = BannerSelection.from(<Banner>[
        _banner(
          'a',
          targetType: BannerTargetType.category,
          targetValue: 'kamera',
        ),
        _banner(
          'b',
          targetType: BannerTargetType.category,
          targetValue: 'lensa',
        ),
        _banner(
          'c',
          targetType: BannerTargetType.externalUrl,
          targetValue: 'https://contoh.test/promo',
        ),
      ]);
      final kurangDariTiga = BannerSelection.from(<Banner>[_banner('a')]);

      expect(lengkap.isComplete, isTrue);
      expect(lengkap.hasNonNavigableSlide, isFalse);
      expect(tanpaPortofolio.isComplete, isFalse);
      expect(tanpaPortofolio.hasPortfolioSlide, isFalse);
      expect(kurangDariTiga.isComplete, isFalse);
      expect(kurangDariTiga.hasPortfolioSlide, isTrue);
    });
  });
}
