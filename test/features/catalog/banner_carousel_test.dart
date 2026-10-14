import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/theme/app_theme.dart';
import 'package:rent_camera_app/features/catalog/domain/banner.dart';
import 'package:rent_camera_app/features/catalog/presentation/widgets/banner_carousel.dart';

Banner _portfolioBanner() => const Banner(
  id: 'b1',
  title: 'Portofolio',
  targetType: BannerTargetType.portfolio,
);

Banner _categoryBanner() => const Banner(
  id: 'b2',
  title: 'Kategori Kamera',
  targetType: BannerTargetType.category,
  targetValue: 'kamera',
);

Future<void> _pumpCarousel(
  WidgetTester tester,
  List<Banner> slides,
  List<String> tapped, {
  Duration? autoPlayInterval = const Duration(seconds: 1),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: BannerCarousel(
          slides: slides,
          autoPlayInterval: autoPlayInterval,
          onSlideTap: (Banner banner) => tapped.add(banner.id),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('slide dengan tujuan valid memanggil onSlideTap', (
    WidgetTester tester,
  ) async {
    final tapped = <String>[];
    await _pumpCarousel(tester, <Banner>[_portfolioBanner()], tapped);

    await tester.tap(find.text('Portofolio'));
    await tester.pump();

    expect(tapped, <String>['b1']);
  });

  testWidgets('slide tanpa tujuan navigasi tidak dapat ditekan', (
    WidgetTester tester,
  ) async {
    final tapped = <String>[];
    await _pumpCarousel(tester, const <Banner>[
      Banner(id: 'b1', title: 'Belum diatur'),
    ], tapped);

    await tester.tap(find.text('Belum diatur'), warnIfMissed: false);
    await tester.pump();

    expect(tapped, isEmpty);
  });

  testWidgets('auto-play memindahkan slide saat lebih dari satu banner', (
    WidgetTester tester,
  ) async {
    await _pumpCarousel(tester, <Banner>[
      _portfolioBanner(),
      _categoryBanner(),
    ], <String>[]);

    expect(find.text('Portofolio'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Kategori Kamera'), findsOneWidget);
  });

  testWidgets('auto-play tidak berjalan bila dimatikan', (
    WidgetTester tester,
  ) async {
    await _pumpCarousel(
      tester,
      <Banner>[_portfolioBanner(), _categoryBanner()],
      <String>[],
      autoPlayInterval: null,
    );

    await tester.pump(const Duration(seconds: 9));

    expect(find.text('Portofolio'), findsOneWidget);
    expect(find.text('Kategori Kamera'), findsNothing);
  });

  testWidgets('satu banner tidak diputar otomatis dan tanpa indikator', (
    WidgetTester tester,
  ) async {
    await _pumpCarousel(tester, <Banner>[_portfolioBanner()], <String>[]);

    await tester.pump(const Duration(seconds: 3));

    expect(tester.takeException(), isNull);
    expect(find.text('Portofolio'), findsOneWidget);
  });
}
