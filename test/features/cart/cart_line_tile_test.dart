import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/theme/app_theme.dart';
import 'package:rent_camera_app/features/cart/presentation/widgets/cart_line_tile.dart';

/// Menampilkan satu baris keranjang di dalam layar sederhana.
///
/// `CartLineTile` tidak menyentuh Firestore maupun provider: seluruh data dan
/// aksi datang dari pemanggil, sehingga cukup diuji sebagai widget mandiri.
Future<void> _pumpTile(
  WidgetTester tester,
  Widget tile, {
  Size size = const Size(400, 700),
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: tile,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Indikator proses berputar terus, jadi `pumpAndSettle` tidak akan selesai.
    await tester.pump();
  }
}

/// Tombol ikon berdasarkan tooltip-nya.
///
/// `find.byTooltip` mengembalikan widget tooltip, bukan `IconButton`, jadi
/// pemanggil perlu menelusuri ke atas sampai widget [IconButton] yang memilikinya.
IconButton _iconButton(WidgetTester tester, String tooltip) =>
    tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(tooltip),
        matching: find.byType(IconButton),
      ),
    );

void main() {
  testWidgets('menampilkan identitas, harga, jumlah, dan subtotal baris', (
    WidgetTester tester,
  ) async {
    await _pumpTile(
      tester,
      const CartLineTile(
        name: 'Lumix G85',
        brand: 'Panasonic',
        quantity: 2,
        unitPriceText: 'Rp150.000',
        periodLabel: '/hari',
        subtotalText: 'Rp300.000',
        stockNote: 'Stok terverifikasi: 3',
        quantityNote: 'Jumlah maksimum: 3',
      ),
    );

    expect(find.text('Lumix G85'), findsOneWidget);
    expect(find.text('Panasonic'), findsOneWidget);
    expect(find.text('Rp150.000/hari'), findsOneWidget);
    expect(find.text('Subtotal: Rp300.000'), findsOneWidget);
    expect(find.text('Jumlah'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Stok terverifikasi: 3'), findsOneWidget);
    expect(find.text('Jumlah maksimum: 3'), findsOneWidget);
  });

  testWidgets('harga yang belum diisi tidak ditulis sebagai Rp0', (
    WidgetTester tester,
  ) async {
    await _pumpTile(
      tester,
      const CartLineTile(
        name: 'Lumix G85',
        quantity: 1,
        unitPriceText: 'Harga belum diisi',
        subtotalText: 'Belum dapat dihitung (harga belum diisi)',
      ),
    );

    expect(find.text('Harga belum diisi'), findsOneWidget);
    expect(
      find.text('Subtotal: Belum dapat dihitung (harga belum diisi)'),
      findsOneWidget,
    );
    expect(find.textContaining('Rp0'), findsNothing);
    expect(find.textContaining('/'), findsNothing);
  });

  testWidgets('meneruskan aksi jumlah, hapus, dan perbaikan apa adanya', (
    WidgetTester tester,
  ) async {
    var increased = 0;
    var decreased = 0;
    var removed = 0;
    var repaired = 0;

    await _pumpTile(
      tester,
      CartLineTile(
        name: 'Lumix G85',
        brand: 'Panasonic',
        quantity: 2,
        unitPriceText: 'Rp150.000',
        periodLabel: '/hari',
        subtotalText: 'Rp300.000',
        stockNote: 'Stok terverifikasi: 3',
        issueMessage: 'Harga berubah dari Rp150.000 menjadi Rp175.000.',
        issueActionLabel: 'Perbarui harga',
        onIssueAction: () => repaired++,
        onIncrease: () => increased++,
        onDecrease: () => decreased++,
        onRemove: () => removed++,
      ),
    );

    await tester.tap(find.byTooltip('Tambah jumlah'));
    await tester.pump();
    await tester.tap(find.byTooltip('Kurangi jumlah'));
    await tester.pump();
    await tester.tap(find.byTooltip('Hapus dari keranjang'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Perbarui harga'));
    await tester.pump();

    expect(increased, 1);
    expect(decreased, 1);
    expect(removed, 1);
    expect(repaired, 1);
  });

  testWidgets('kontrol tanpa aksi tampil nonaktif, bukan diam-diam mati', (
    WidgetTester tester,
  ) async {
    await _pumpTile(
      tester,
      const CartLineTile(
        name: 'Lumix G85',
        quantity: 4,
        unitPriceText: 'Rp150.000',
        periodLabel: '/hari',
        subtotalText: 'Rp600.000',
        quantityNote:
            'Jumlah belum dapat diubah sampai masalah di baris ini '
            'diselesaikan.',
        issueMessage:
            'Alat ini sudah tidak ada di katalog, sehingga tidak dapat '
            'dipesan. Hapus dari keranjang untuk melanjutkan.',
      ),
    );

    expect(_iconButton(tester, 'Tambah jumlah').onPressed, isNull);
    expect(_iconButton(tester, 'Kurangi jumlah').onPressed, isNull);
    expect(_iconButton(tester, 'Hapus dari keranjang').onPressed, isNull);
    expect(
      find.byType(TextButton),
      findsNothing,
      reason:
          'tanpa callback perbaikan, tidak boleh ada tombol yang '
          'tampak bekerja',
    );
  });

  testWidgets('baris yang sedang menyimpan menyembunyikan kontrol jumlah', (
    WidgetTester tester,
  ) async {
    await _pumpTile(
      tester,
      const CartLineTile(
        name: 'Lumix G85',
        quantity: 2,
        unitPriceText: 'Rp150.000',
        subtotalText: 'Rp300.000',
        isBusy: true,
      ),
      settle: false,
    );

    expect(find.text('Menyimpan perubahan…'), findsOneWidget);
    expect(find.byTooltip('Tambah jumlah'), findsNothing);
    expect(find.byTooltip('Hapus dari keranjang'), findsNothing);
  });

  testWidgets('aman pada layar sempit dengan nama dan pesan panjang', (
    WidgetTester tester,
  ) async {
    await _pumpTile(
      tester,
      const CartLineTile(
        name:
            'Kamera mirrorless dengan nama sangat panjang sampai dua baris '
            'penuh',
        brand: 'Panasonic Lumix Professional Imaging',
        quantity: 99,
        unitPriceText: 'Rp1.000.000',
        periodLabel: '/hari',
        subtotalText: 'Rp99.000.000',
        stockNote: 'Stok terverifikasi: 99',
        quantityNote: 'Jumlah maksimum: 99',
        issueMessage:
            'Stok terbaru hanya 3, sedangkan keranjang meminta 99. Turunkan '
            'jumlah atau hapus baris ini.',
      ),
      size: const Size(320, 600),
    );

    final issue = find.textContaining('Stok terbaru hanya 3');
    await tester.scrollUntilVisible(
      issue,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(issue, findsOneWidget);
    expect(find.text('Jumlah maksimum: 99'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
