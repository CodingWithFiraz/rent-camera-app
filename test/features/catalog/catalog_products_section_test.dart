import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/errors/app_exception.dart';
import 'package:rent_camera_app/core/theme/app_theme.dart';
import 'package:rent_camera_app/features/catalog/domain/catalog_filter.dart';
import 'package:rent_camera_app/features/catalog/domain/price_unit.dart';
import 'package:rent_camera_app/features/catalog/domain/product.dart';
import 'package:rent_camera_app/features/catalog/presentation/catalog_providers.dart';
import 'package:rent_camera_app/features/catalog/presentation/widgets/catalog_products_section.dart';
import 'package:rent_camera_app/features/catalog/presentation/widgets/product_card.dart';

/// Notifier filter palsu yang sudah membawa kata kunci, untuk menguji keadaan
/// "hasil pencarian kosong" tanpa menyentuh Firestore.
class _FilteringNotifier extends CatalogFilterNotifier {
  @override
  CatalogFilter build() => const CatalogFilter(query: 'kamera');
}

Product _product(String id, String name) => Product(
  id: id,
  name: name,
  categoryId: 'kamera',
  brand: 'Panasonic',
  price: 150000,
  priceUnit: PriceUnit.perDay,
  stockQuantity: 2,
);

Future<void> _pump(
  WidgetTester tester,
  AsyncValue<List<Product>> products, {
  ValueChanged<Product>? onOpenProduct,
  VoidCallback? onResetFilters,
  bool filtering = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogProductsProvider.overrideWithValue(products),
        if (filtering)
          catalogFilterProvider.overrideWith(_FilteringNotifier.new),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: CatalogProductsSection(
              onOpenProduct: onOpenProduct ?? (Product product) {},
              onResetFilters: onResetFilters ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('menampilkan indikator memuat selama data belum tersedia', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const AsyncValue<List<Product>>.loading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);
  });

  testWidgets(
    'menampilkan pesan error yang sudah dipetakan dan tombol ulangi',
    (WidgetTester tester) async {
      await _pump(
        tester,
        AsyncValue<List<Product>>.error(
          const AppException('Tidak dapat menghubungi layanan data.'),
          StackTrace.empty,
        ),
      );

      expect(find.text('Katalog belum dapat dimuat'), findsOneWidget);
      expect(
        find.text('Tidak dapat menghubungi layanan data.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Coba lagi'), findsOneWidget);
    },
  );

  testWidgets('katalog kosong dibedakan dari hasil pencarian kosong', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const AsyncValue<List<Product>>.data(<Product>[]));

    expect(find.text('Katalog masih kosong'), findsOneWidget);
    expect(find.text('Hapus filter'), findsNothing);
  });

  testWidgets('hasil pencarian kosong menawarkan penghapusan filter', (
    WidgetTester tester,
  ) async {
    var resetCount = 0;
    await _pump(
      tester,
      const AsyncValue<List<Product>>.data(<Product>[]),
      filtering: true,
      onResetFilters: () => resetCount += 1,
    );

    expect(find.text('Tidak ada produk yang cocok'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Hapus filter'));
    await tester.pump();

    expect(resetCount, 1);
  });

  testWidgets('menampilkan kartu produk dan meneruskan aksi buka detail', (
    WidgetTester tester,
  ) async {
    final opened = <String>[];
    await _pump(
      tester,
      AsyncValue<List<Product>>.data(<Product>[
        _product('p1', 'Lumix G85'),
        _product('p2', 'Sony A7 III'),
      ]),
      onOpenProduct: (Product product) => opened.add(product.id),
    );

    expect(find.byType(ProductCard), findsNWidgets(2));

    await tester.tap(find.byType(ProductCard).first);
    await tester.pump();

    expect(opened, <String>['p1']);
  });

  testWidgets('jumlah kolom grid mengikuti lebar yang tersedia', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.reset);

    Future<int> columnsAt(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await _pump(
        tester,
        AsyncValue<List<Product>>.data(<Product>[_product('p1', 'Lumix G85')]),
      );
      final delegate = tester
          .widget<GridView>(find.byType(GridView))
          .gridDelegate;
      return (delegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount;
    }

    expect(await columnsAt(const Size(360, 800)), 2);
    expect(await columnsAt(const Size(800, 800)), 3);
    expect(await columnsAt(const Size(1200, 800)), 4);
    expect(tester.takeException(), isNull);
  });
}
