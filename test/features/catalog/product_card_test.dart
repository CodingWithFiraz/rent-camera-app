import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/theme/app_theme.dart';
import 'package:rent_camera_app/features/catalog/domain/price_unit.dart';
import 'package:rent_camera_app/features/catalog/domain/product.dart';
import 'package:rent_camera_app/features/catalog/presentation/widgets/product_card.dart';

Product _product({
  String name = 'Lumix G85',
  String brand = 'Panasonic',
  int price = 150000,
  PriceUnit priceUnit = PriceUnit.perDay,
  int stockQuantity = 2,
  bool isActive = true,
}) => Product(
  id: 'p1',
  name: name,
  categoryId: 'kamera',
  brand: brand,
  price: price,
  priceUnit: priceUnit,
  stockQuantity: stockQuantity,
  isActive: isActive,
);

/// Menempatkan kartu pada ukuran tetap, menyerupai satu sel grid pada layar
/// sempit, supaya overflow terdeteksi lebih dulu daripada di layar lebar.
Future<void> _pumpCard(
  WidgetTester tester,
  Product product, {
  double width = 180,
  double height = 260,
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: ProductCard(product: product, onTap: onTap ?? () {}),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('menampilkan nama, brand, harga, periode, dan stok', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, _product());

    expect(find.text('Lumix G85'), findsOneWidget);
    expect(find.text('Panasonic'), findsOneWidget);
    expect(find.text('Rp150.000'), findsOneWidget);
    expect(find.text('/hari'), findsOneWidget);
    expect(find.text('Stok 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('teks panjang tidak meluap pada kartu sempit', (
    WidgetTester tester,
  ) async {
    await _pumpCard(
      tester,
      _product(
        name: 'Kamera mirrorless dengan nama sangat panjang sekali sampai dua baris',
        brand: 'Brand Dengan Nama Sangat Panjang Sekali',
        price: 1234567890,
      ),
      width: 150,
      height: 240,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Rp1.234.567.890'), findsOneWidget);
  });

  testWidgets('produk tanpa foto tetap menampilkan placeholder jujur', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, _product());

    expect(find.text('Foto belum diisi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('produk habis dan produk arsip tidak ditulis tersedia', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, _product(stockQuantity: 0));
    expect(find.text('Stok habis'), findsOneWidget);

    await _pumpCard(tester, _product(isActive: false));
    expect(find.text('Tidak tersedia'), findsOneWidget);
    expect(find.textContaining('Stok '), findsNothing);
  });

  testWidgets('harga yang belum diisi tidak ditampilkan sebagai nol', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, _product(price: 0));

    expect(find.text('Harga belum diisi'), findsOneWidget);
    expect(find.text('Rp0'), findsNothing);
  });

  testWidgets('menekan kartu memanggil aksi buka detail', (
    WidgetTester tester,
  ) async {
    var tapCount = 0;
    await _pumpCard(tester, _product(), onTap: () => tapCount += 1);

    await tester.tap(find.byType(ProductCard));
    await tester.pump();

    expect(tapCount, 1);
  });
}
