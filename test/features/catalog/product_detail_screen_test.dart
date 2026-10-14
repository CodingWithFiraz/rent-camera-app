import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/errors/app_exception.dart';
import 'package:rent_camera_app/core/theme/app_theme.dart';
import 'package:rent_camera_app/features/auth/domain/auth_user.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_providers.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_session_notifier.dart';
import 'package:rent_camera_app/features/catalog/domain/category.dart';
import 'package:rent_camera_app/features/catalog/domain/price_unit.dart';
import 'package:rent_camera_app/features/catalog/domain/product.dart';
import 'package:rent_camera_app/features/catalog/presentation/catalog_providers.dart';
import 'package:rent_camera_app/features/catalog/presentation/product_detail_screen.dart';

Product _product({
  String name = 'Lumix G85',
  String description = 'Kondisi mulus, lengkap dengan baterai dan charger.',
  int price = 150000,
  PriceUnit priceUnit = PriceUnit.perDay,
  int stockQuantity = 2,
  bool isActive = true,
}) => Product(
  id: 'p1',
  name: name,
  categoryId: 'kamera',
  brand: 'Panasonic',
  price: price,
  priceUnit: priceUnit,
  stockQuantity: stockQuantity,
  isActive: isActive,
  description: description,
);

/// Menampilkan halaman detail dengan produk disuntikkan dari test sehingga
/// tidak ada permintaan Firestore.
Future<void> _pumpDetail(
  WidgetTester tester,
  FutureOr<Product?> product, {
  Size size = const Size(400, 900),
  bool settle = true,
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
          (Ref ref) => Stream<List<Category>>.value(const <Category>[
            Category(id: 'kamera', name: 'Kamera', slug: 'kamera'),
          ]),
        ),
        productByIdProvider.overrideWith(
          (Ref ref, String productId) => product,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const ProductDetailScreen(productId: 'p1'),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('menampilkan identitas, harga, satuan, dan stok alat', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(tester, _product());

    expect(find.text('Lumix G85'), findsOneWidget);
    expect(find.text('Panasonic'), findsOneWidget);
    expect(find.text('Kategori: Kamera'), findsOneWidget);
    expect(find.text('Rp150.000'), findsOneWidget);
    expect(find.text('/hari'), findsOneWidget);
    expect(find.text('Stok tersedia: 2'), findsOneWidget);
    expect(
      find.text('Kondisi mulus, lengkap dengan baterai dan charger.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Sewa'), findsOneWidget);
  });

  testWidgets('satuan periode tidak dikarang bila dokumen belum mengisinya', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(tester, _product(priceUnit: PriceUnit.unspecified));

    expect(find.text('/hari'), findsNothing);
    expect(find.text('/sesi'), findsNothing);
    expect(
      find.text('Satuan periode harga belum ditetapkan admin.'),
      findsOneWidget,
    );
  });

  testWidgets('produk yang diarsipkan admin tidak dapat disewa', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(tester, _product(isActive: false));

    expect(find.textContaining('sudah diarsipkan admin'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Sewa'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('stok habis menonaktifkan aksi sewa tanpa pemilih jumlah', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(tester, _product(stockQuantity: 0));

    expect(find.text('Stok habis'), findsOneWidget);
    expect(find.byTooltip('Tambah jumlah'), findsNothing);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Sewa'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('pemilih jumlah dibatasi stok yang tersedia', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(tester, _product(stockQuantity: 3));

    expect(find.text('maks. 3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    final tambah = find.widgetWithIcon(IconButton, Icons.add);
    await tester.ensureVisible(tambah);
    await tester.pump();
    await tester.tap(tambah);
    await tester.pump();
    await tester.tap(tambah);
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    expect(
      tester.widget<IconButton>(tambah).onPressed,
      isNull,
      reason: 'jumlah tidak boleh melebihi stok',
    );
  });

  testWidgets('kegagalan memuat data menampilkan pesan dan tombol ulangi', (
    WidgetTester tester,
  ) async {
    // Future diselesaikan setelah halaman terbuka, meniru permintaan Firestore
    // yang baru gagal kemudian — bukan error yang sudah ada sebelum didengar.
    final completer = Completer<Product?>();
    await _pumpDetail(tester, completer.future, settle: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.completeError(
      const AppException('Tidak dapat menghubungi layanan data.'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail alat belum dapat dimuat'), findsOneWidget);
    expect(find.text('Tidak dapat menghubungi layanan data.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Coba lagi'), findsOneWidget);
  });

  testWidgets('produk yang sudah tidak ada dijelaskan apa adanya', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(tester, null);

    expect(find.text('Alat tidak ditemukan'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sewa'), findsNothing);
  });

  testWidgets('aman pada layar sempit dengan teks panjang', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(
      tester,
      _product(
        name: 'Kamera mirrorless dengan nama sangat panjang sekali sampai dua baris',
        description:
            'Deskripsi panjang untuk memastikan halaman tetap dapat digulir '
            'dan tidak meluap pada layar sempit: kondisi alat, kelengkapan, '
            'dan catatan pemakaian ditulis apa adanya oleh admin.',
      ),
      size: const Size(320, 600),
    );

    // Keterangan stok berada di bawah lipatan layar sempit; digulir lebih dulu
    // supaya tata letak jenuh (overflow) tetap terperiksa.
    final stockLine = find.text('Stok tersedia: 2');
    await tester.scrollUntilVisible(
      stockLine,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(stockLine, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
