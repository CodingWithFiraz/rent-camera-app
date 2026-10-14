import 'dart:async';

import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/theme/app_theme.dart';
import 'package:rent_camera_app/features/auth/domain/auth_user.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_providers.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_session_notifier.dart';
import 'package:rent_camera_app/features/catalog/domain/banner.dart';
import 'package:rent_camera_app/features/catalog/domain/banner_selection.dart';
import 'package:rent_camera_app/features/catalog/domain/category.dart';
import 'package:rent_camera_app/features/catalog/domain/price_unit.dart';
import 'package:rent_camera_app/features/catalog/domain/product.dart';
import 'package:rent_camera_app/features/catalog/presentation/catalog_providers.dart';
import 'package:rent_camera_app/features/catalog/presentation/catalog_screen.dart';
import 'package:rent_camera_app/features/catalog/presentation/widgets/product_card.dart';

Category _category() =>
    const Category(id: 'kamera', name: 'Kamera', slug: 'kamera');

Banner _banner(
  String id,
  String title,
  BannerTargetType targetType, {
  String targetValue = '',
}) => Banner(
  id: id,
  title: title,
  targetType: targetType,
  targetValue: targetValue,
);

Product _product(String id, String name) => Product(
  id: id,
  name: name,
  categoryId: 'kamera',
  brand: 'Panasonic',
  price: 150000,
  priceUnit: PriceUnit.perDay,
  stockQuantity: 2,
);

/// Menampilkan halaman katalog pada ukuran layar tertentu dengan data katalog
/// disuntikkan lewat override provider (tanpa Firestore).
Future<void> _pumpCatalog(
  WidgetTester tester, {
  required Size size,
  required List<Product> products,
  BannerSelection? banners,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = StreamController<AuthUser?>();
  addTearDown(controller.close);
  final session = AuthSessionNotifier(authStateChanges: controller.stream);
  addTearDown(session.dispose);
  controller.add(const AuthUser(uid: 'uid-1', displayName: 'Nama Uji'));

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        authSessionNotifierProvider.overrideWithValue(session),
        activeCategoriesProvider.overrideWith(
          (Ref ref) => Stream<List<Category>>.value(<Category>[_category()]),
        ),
        catalogBannerSelectionProvider.overrideWithValue(
          AsyncValue<BannerSelection>.data(
            banners ??
                BannerSelection.from(<Banner>[
                  _banner('b1', 'Portofolio kami', BannerTargetType.portfolio),
                ]),
          ),
        ),
        catalogProductsProvider.overrideWithValue(
          AsyncValue<List<Product>>.data(products),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const CatalogScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('aman pada layar sempit dengan teks produk panjang', (
    WidgetTester tester,
  ) async {
    await _pumpCatalog(
      tester,
      size: const Size(320, 640),
      products: <Product>[
        _product('p1', 'Kamera mirrorless dengan nama sangat panjang sekali'),
        _product('p2', 'Lensa 50mm f/1.8'),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ProductCard), findsNWidgets(2));
    expect(find.text('Portofolio kami'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('pencarian dan filter tampil di atas daftar produk', (
    WidgetTester tester,
  ) async {
    await _pumpCatalog(
      tester,
      size: const Size(360, 720),
      products: <Product>[_product('p1', 'Lumix G85')],
    );

    expect(find.text('Cari nama alat, brand, atau kata kunci'), findsOneWidget);
    expect(find.text('Katalog alat'), findsOneWidget);
    expect(find.byType(ProductCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'banner yang belum lengkap dilaporkan tanpa menyembunyikan data',
    (WidgetTester tester) async {
      await _pumpCatalog(
        tester,
        size: const Size(400, 720),
        products: <Product>[_product('p1', 'Lumix G85')],
        banners: BannerSelection.from(<Banner>[
          _banner(
            'b1',
            'Kategori kamera',
            BannerTargetType.category,
            targetValue: 'kamera',
          ),
          const Banner(id: 'b2', title: 'Belum diatur'),
        ]),
      );

      expect(find.textContaining('belum punya tujuan'), findsOneWidget);
      expect(
        find.textContaining('Belum ada banner yang menuju'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
