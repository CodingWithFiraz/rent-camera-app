import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/errors/app_exception.dart';
import 'package:rent_camera_app/core/theme/app_theme.dart';
import 'package:rent_camera_app/core/utils/external_launcher.dart';
import 'package:rent_camera_app/features/auth/domain/auth_user.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_providers.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_session_notifier.dart';
import 'package:rent_camera_app/features/cart/domain/cart_item.dart';
import 'package:rent_camera_app/features/cart/presentation/cart_providers.dart';
import 'package:rent_camera_app/features/catalog/domain/price_unit.dart';
import 'package:rent_camera_app/features/portfolio/domain/creative.dart';
import 'package:rent_camera_app/features/portfolio/domain/service_rate.dart';
import 'package:rent_camera_app/features/portfolio/presentation/portfolio_providers.dart';
import 'package:rent_camera_app/features/portfolio/presentation/portfolio_screen.dart';

ServiceRate _rate({
  String id = 'commercial_social_media_video',
  String title = 'Commercial / Social Media Video',
  String description = 'Produksi video komersial.',
  String rateLabel = 'CONTOH RATE — BELUM FINAL',
  int? startingPrice,
  PriceUnit priceUnit = PriceUnit.unspecified,
  List<String> deliverables = const <String>[],
}) => ServiceRate(
  id: id,
  title: title,
  description: description,
  rateLabel: rateLabel,
  startingPrice: startingPrice,
  priceUnit: priceUnit,
  deliverables: deliverables,
);

Creative _creative({
  String id = 'kreator-1',
  String name = 'Kreator Uji',
  String roleTitle = 'Fotografer',
  List<String> specialties = const <String>['Foto produk'],
  String portfolioUrl = 'https://contoh.test/portofolio-1',
}) => Creative(
  id: id,
  name: name,
  roleTitle: roleTitle,
  specialties: specialties,
  portfolioUrl: portfolioUrl,
);

/// URI yang diserahkan ke aplikasi lain dan teks yang disalin ke clipboard.
class _Harness {
  _Harness({required this.launched, required this.copied});

  final List<Uri> launched;
  final List<String> copied;
}

/// Menampilkan halaman portofolio dengan seluruh sumber data disuntikkan test.
///
/// Tidak ada Firestore maupun `url_launcher` sungguhan yang disentuh: stream
/// rate card/kreator dan pembuka tautan diganti sehingga hasilnya deterministik.
Future<_Harness> _pumpPortfolio(
  WidgetTester tester, {
  required AsyncValue<List<ServiceRate>> rates,
  required AsyncValue<List<Creative>> creatives,
  bool openSucceeds = true,
}) async {
  tester.view.physicalSize = const Size(420, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = StreamController<AuthUser?>();
  addTearDown(controller.close);
  final session = AuthSessionNotifier(authStateChanges: controller.stream);
  addTearDown(session.dispose);
  controller.add(const AuthUser(uid: 'uid-1', displayName: 'Nama Uji'));

  final launched = <Uri>[];
  final copied = <String>[];

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        authSessionNotifierProvider.overrideWithValue(session),
        // Keranjang tidak sedang diuji: badge app bar dibuat kosong tanpa
        // menyentuh Firestore.
        cartItemsProvider.overrideWith(
          (Ref ref, String uid) =>
              Stream<List<CartItem>>.value(const <CartItem>[]),
        ),
        activeServiceRatesProvider.overrideWithValue(rates),
        activeCreativesProvider.overrideWithValue(creatives),
        externalLauncherProvider.overrideWithValue(
          ExternalLauncher(
            opener: (Uri uri) async {
              launched.add(uri);
              return openSucceeds;
            },
            clipboardWriter: (String text) async => copied.add(text),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const PortfolioScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(launched: launched, copied: copied);
}

void main() {
  testWidgets('menampilkan rate card dan kreator dari dokumen', (
    WidgetTester tester,
  ) async {
    await _pumpPortfolio(
      tester,
      rates: AsyncValue<List<ServiceRate>>.data(<ServiceRate>[
        _rate(deliverables: <String>['Aset video siap unggah']),
      ]),
      creatives: AsyncValue<List<Creative>>.data(<Creative>[_creative()]),
    );

    expect(find.text('Commercial / Social Media Video'), findsOneWidget);
    expect(find.text('Aset video siap unggah'), findsOneWidget);
    expect(find.text('CONTOH RATE — BELUM FINAL'), findsOneWidget);
    expect(find.text('Kreator Uji'), findsOneWidget);
    expect(find.text('Fotografer'), findsOneWidget);
    expect(find.text('Foto produk'), findsOneWidget);
    // Jumlah dokumen yang belum sesuai blueprint dijelaskan apa adanya.
    expect(find.textContaining('1 kelompok layanan aktif'), findsOneWidget);
    expect(find.textContaining('1 kreator aktif'), findsOneWidget);
  });

  testWidgets('harga dan satuan hanya tampil bila dokumen mengisinya', (
    WidgetTester tester,
  ) async {
    await _pumpPortfolio(
      tester,
      rates: AsyncValue<List<ServiceRate>>.data(<ServiceRate>[
        _rate(
          id: 'dengan-satuan',
          title: 'Dengan satuan',
          startingPrice: 500000,
          priceUnit: PriceUnit.perSession,
        ),
        _rate(id: 'tanpa-satuan', title: 'Tanpa satuan', startingPrice: 250000),
        _rate(id: 'belum-diisi', title: 'Belum diisi', rateLabel: ''),
      ]),
      creatives: const AsyncValue<List<Creative>>.data(<Creative>[]),
    );

    expect(
      find.text('CONTOH RATE — BELUM FINAL Rp500.000/sesi'),
      findsOneWidget,
    );
    // Tanpa `priceUnit` dokumen, label periode tidak boleh dikarang.
    expect(find.text('CONTOH RATE — BELUM FINAL Rp250.000'), findsOneWidget);
    expect(find.text('Rp250.000/hari'), findsNothing);
    expect(find.text('Rate belum ditetapkan pemilik.'), findsOneWidget);
  });

  testWidgets('rate dan kreator yang belum diisi memakai keadaan kosong', (
    WidgetTester tester,
  ) async {
    await _pumpPortfolio(
      tester,
      rates: const AsyncValue<List<ServiceRate>>.data(<ServiceRate>[]),
      creatives: const AsyncValue<List<Creative>>.data(<Creative>[]),
    );

    expect(find.text('Rate card belum dikonfigurasi'), findsOneWidget);
    expect(find.text('Kreator belum dikonfigurasi'), findsOneWidget);
    expect(find.text('Lihat Portofolio'), findsNothing);
  });

  testWidgets('kegagalan pemuatan dijelaskan beserta tombol coba lagi', (
    WidgetTester tester,
  ) async {
    await _pumpPortfolio(
      tester,
      rates: AsyncValue<List<ServiceRate>>.error(
        const AppException('Akses ditolak untuk rate card.'),
        StackTrace.empty,
      ),
      creatives: AsyncValue<List<Creative>>.error(
        const AppException('Akses ditolak untuk kreator.'),
        StackTrace.empty,
      ),
    );

    expect(find.text('Rate card belum dapat dimuat'), findsOneWidget);
    expect(find.text('Data kreator belum dapat dimuat'), findsOneWidget);
    expect(find.text('Akses ditolak untuk rate card.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNWidgets(2));
  });

  testWidgets('CTA membuka URL portofolio yang sudah tervalidasi', (
    WidgetTester tester,
  ) async {
    final harness = await _pumpPortfolio(
      tester,
      rates: const AsyncValue<List<ServiceRate>>.data(<ServiceRate>[]),
      creatives: AsyncValue<List<Creative>>.data(<Creative>[_creative()]),
    );

    await tester.tap(find.text('Lihat Portofolio'));
    await tester.pumpAndSettle();

    expect(harness.launched.map((Uri uri) => uri.toString()), <String>[
      'https://contoh.test/portofolio-1',
    ]);
    expect(
      find.textContaining('Portofolio Kreator Uji dibuka'),
      findsOneWidget,
    );
  });

  testWidgets('tautan yang gagal dibuka disalin, bukan diklaim berhasil', (
    WidgetTester tester,
  ) async {
    final harness = await _pumpPortfolio(
      tester,
      rates: const AsyncValue<List<ServiceRate>>.data(<ServiceRate>[]),
      creatives: AsyncValue<List<Creative>>.data(<Creative>[_creative()]),
      openSucceeds: false,
    );

    await tester.tap(find.text('Lihat Portofolio'));
    await tester.pumpAndSettle();

    expect(harness.copied, <String>['https://contoh.test/portofolio-1']);
    expect(find.textContaining('disalin ke clipboard'), findsOneWidget);
  });

  testWidgets('CTA nonaktif selama tautan portofolio belum diisi', (
    WidgetTester tester,
  ) async {
    final harness = await _pumpPortfolio(
      tester,
      rates: const AsyncValue<List<ServiceRate>>.data(<ServiceRate>[]),
      creatives: AsyncValue<List<Creative>>.data(<Creative>[
        _creative(portfolioUrl: ''),
      ]),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(
      find.text('Tautan portofolio belum dikonfigurasi pemilik.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Lihat Portofolio'));
    await tester.pumpAndSettle();
    expect(harness.launched, isEmpty);
  });

  testWidgets('CTA nonaktif bila skema URL tidak diizinkan', (
    WidgetTester tester,
  ) async {
    final harness = await _pumpPortfolio(
      tester,
      rates: const AsyncValue<List<ServiceRate>>.data(<ServiceRate>[]),
      creatives: AsyncValue<List<Creative>>.data(<Creative>[
        _creative(portfolioUrl: 'javascript:alert(1)'),
      ]),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.text('Lihat Portofolio'));
    await tester.pumpAndSettle();
    expect(harness.launched, isEmpty);
  });
}
