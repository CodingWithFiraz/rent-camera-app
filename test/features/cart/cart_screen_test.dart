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
import 'package:rent_camera_app/features/cart/domain/cart_checkout.dart';
import 'package:rent_camera_app/features/cart/domain/cart_item.dart';
import 'package:rent_camera_app/features/cart/presentation/cart_providers.dart';
import 'package:rent_camera_app/features/cart/presentation/cart_screen.dart';
import 'package:rent_camera_app/features/catalog/domain/price_unit.dart';
import 'package:rent_camera_app/features/catalog/domain/product.dart';

/// Nomor WhatsApp uji disusun dari potongan digit supaya tidak ada nomor nyata
/// yang tertulis harfiah di dalam test (blueprint §7: nomor hanya dari
/// konfigurasi, bukan dari source code).
const List<String> _numberParts = <String>['62', '812', '345', '67'];

final String _testNumber = _numberParts.join();

Product _product({
  int price = 150000,
  PriceUnit priceUnit = PriceUnit.perDay,
  int stockQuantity = 5,
  bool isActive = true,
}) => Product(
  id: 'p1',
  name: 'Lumix G85',
  categoryId: 'kamera',
  brand: 'Panasonic',
  price: price,
  priceUnit: priceUnit,
  stockQuantity: stockQuantity,
  isActive: isActive,
);

CartItem _item({
  int quantity = 2,
  int unitPriceSnapshot = 150000,
  PriceUnit priceUnitSnapshot = PriceUnit.perDay,
}) => CartItem(
  productId: 'p1',
  productNameSnapshot: 'Lumix G85',
  brandSnapshot: 'Panasonic',
  unitPriceSnapshot: unitPriceSnapshot,
  priceUnitSnapshot: priceUnitSnapshot,
  quantity: quantity,
);

/// Keranjang satu baris yang siap dipesan.
CartCheckoutValidation _readyValidation() => CartCheckoutValidation.validate(
  items: <CartItem>[_item()],
  products: <String, Product>{'p1': _product()},
);

/// Keranjang satu baris yang jumlahnya melebihi stok terverifikasi.
CartCheckoutValidation _overStockValidation() =>
    CartCheckoutValidation.validate(
      items: <CartItem>[_item(quantity: 5)],
      products: <String, Product>{'p1': _product(stockQuantity: 3)},
    );

/// Pengganti [CartActions]: mencatat aksi tanpa menyentuh Firestore.
class _FakeCartActions extends CartActions {
  // Super parameter tidak bisa dipakai di sini: parameter superclass-nya
  // privat (`_ref`), sehingga `super._ref` tidak dapat ditulis dari library test.
  // ignore: use_super_parameters
  _FakeCartActions(Ref ref) : super(ref);

  final List<String> calls = <String>[];

  /// Hasil validasi ulang yang dikembalikan saat checkout ditekan.
  CartCheckoutValidation checkoutResult = CartCheckoutValidation.empty;

  /// Kegagalan yang dilempar aksi berikutnya; `null` berarti berhasil.
  AppException? failure;

  Future<void> _record(String call) async {
    calls.add(call);
    final error = failure;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> setQuantity({
    required String uid,
    required String productId,
    required int quantity,
  }) => _record('setQuantity:$uid:$productId:$quantity');

  @override
  Future<void> removeItem({required String uid, required String productId}) =>
      _record('removeItem:$uid:$productId');

  @override
  Future<void> refreshStoredPrice({
    required String uid,
    required String productId,
  }) => _record('refreshStoredPrice:$uid:$productId');

  @override
  Future<CartCheckoutValidation> validateForCheckout(String uid) async {
    calls.add('validateForCheckout:$uid');
    final error = failure;
    if (error != null) {
      throw error;
    }
    return checkoutResult;
  }
}

/// Hasil pengamatan satu penjalanan halaman keranjang.
class _Harness {
  _Harness({
    required this.actions,
    required this.launched,
    required this.copied,
  });

  final _FakeCartActions actions;

  /// URI yang diserahkan ke aplikasi luar (WhatsApp).
  final List<Uri> launched;

  /// Teks yang disalin ke clipboard saat aplikasi luar gagal dibuka.
  final List<String> copied;
}

/// Menampilkan [CartScreen] dengan seluruh dependensi disuntikkan test.
///
/// Tidak ada Firestore, `url_launcher`, maupun `WHATSAPP_NUMBER` sungguhan yang
/// disentuh: keranjang tervalidasi, aksi tulis, dan pembuka tautan semuanya
/// diganti sehingga hasilnya deterministik.
Future<_Harness> _pumpCart(
  WidgetTester tester, {
  required FutureOr<CartCheckoutValidation> displayed,
  CartCheckoutValidation? onCheckout,
  String? whatsappNumber,
  bool signedIn = true,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = StreamController<AuthUser?>();
  addTearDown(controller.close);
  final session = AuthSessionNotifier(authStateChanges: controller.stream);
  addTearDown(session.dispose);
  if (signedIn) {
    controller.add(const AuthUser(uid: 'uid-1', displayName: 'Nama Uji'));
  }

  final launched = <Uri>[];
  final copied = <String>[];
  late _FakeCartActions created;

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        authSessionNotifierProvider.overrideWithValue(session),
        cartCheckoutProvider.overrideWith((Ref ref, String uid) => displayed),
        cartActionsProvider.overrideWith((Ref ref) {
          created = _FakeCartActions(ref)
            ..checkoutResult = onCheckout ?? CartCheckoutValidation.empty;
          return created;
        }),
        checkoutWhatsAppNumberProvider.overrideWithValue(
          whatsappNumber ?? _testNumber,
        ),
        externalLauncherProvider.overrideWithValue(
          ExternalLauncher(
            opener: (Uri uri) async {
              launched.add(uri);
              return true;
            },
            clipboardWriter: (String text) async => copied.add(text),
          ),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const CartScreen()),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }

  // Dibaca eksplisit supaya pengganti aksi selalu dibuat, walau test belum
  // menyentuh tombol apa pun.
  final container = ProviderScope.containerOf(
    tester.element(find.byType(CartScreen)),
    listen: false,
  );
  container.read(cartActionsProvider);

  return _Harness(actions: created, launched: launched, copied: copied);
}

FilledButton _checkoutButton(WidgetTester tester) =>
    tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Checkout via WhatsApp'),
    );

Future<void> _tapCheckout(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Checkout via WhatsApp');
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('menampilkan indikator selama keranjang dibaca', (
    WidgetTester tester,
  ) async {
    final completer = Completer<CartCheckoutValidation>();
    await _pumpCart(tester, displayed: completer.future, settle: false);

    expect(find.text('Memuat keranjang…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_readyValidation());
    await tester.pumpAndSettle();

    expect(find.text('Memuat keranjang…'), findsNothing);
    expect(find.text('Lumix G85'), findsOneWidget);
  });

  testWidgets(
    'kegagalan memuat keranjang menampilkan pesan dan tombol ulangi',
    (WidgetTester tester) async {
      final completer = Completer<CartCheckoutValidation>();
      await _pumpCart(tester, displayed: completer.future, settle: false);

      completer.completeError(
        const AppException('Keranjang tidak dapat dimuat.'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Keranjang belum dapat dimuat'), findsOneWidget);
      expect(find.text('Keranjang tidak dapat dimuat.'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Coba lagi'), findsOneWidget);
    },
  );

  testWidgets('keranjang kosong menjelaskan cara menambah alat', (
    WidgetTester tester,
  ) async {
    await _pumpCart(tester, displayed: CartCheckoutValidation.empty);

    expect(find.text('Keranjang masih kosong'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Cari alat di katalog'),
      findsOneWidget,
    );
    expect(find.text('Checkout via WhatsApp'), findsNothing);
    expect(find.text('Rp0'), findsNothing);
  });

  testWidgets('pengguna yang belum login diminta masuk lebih dulu', (
    WidgetTester tester,
  ) async {
    await _pumpCart(
      tester,
      displayed: CartCheckoutValidation.empty,
      signedIn: false,
    );

    expect(find.text('Masuk untuk membuka keranjang'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Masuk'), findsOneWidget);
    expect(find.text('Keranjang masih kosong'), findsNothing);
  });

  testWidgets('baris melebihi stok dijelaskan dan checkout dinonaktifkan', (
    WidgetTester tester,
  ) async {
    await _pumpCart(
      tester,
      displayed: _overStockValidation(),
      onCheckout: _overStockValidation(),
    );

    expect(find.text('Lumix G85'), findsOneWidget);
    expect(find.text('Rp150.000/hari'), findsOneWidget);
    expect(find.text('Subtotal: Rp750.000'), findsOneWidget);
    expect(find.text('Stok terverifikasi: 3'), findsOneWidget);
    expect(
      find.text(
        'Satu baris belum dapat dipesan, sehingga tidak ikut dihitung pada '
        'total. Selesaikan masalah pada baris tersebut lebih dulu.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Stok terbaru hanya 3, sedangkan keranjang meminta 5. Turunkan jumlah '
        'atau hapus baris ini.',
      ),
      findsOneWidget,
    );
    expect(find.text('Belum dapat dihitung'), findsOneWidget);
    expect(
      find.text('Total hanya menjumlahkan baris yang siap dipesan.'),
      findsOneWidget,
    );
    expect(_checkoutButton(tester).onPressed, isNull);
  });

  testWidgets('menurunkan jumlah memakai stok terverifikasi terbaru', (
    WidgetTester tester,
  ) async {
    final harness = await _pumpCart(
      tester,
      displayed: _overStockValidation(),
      onCheckout: _overStockValidation(),
    );

    final action = find.widgetWithText(TextButton, 'Sesuaikan jumlah');
    await tester.ensureVisible(action);
    await tester.pump();
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(harness.actions.calls, <String>['setQuantity:uid-1:p1:3']);
    expect(harness.launched, isEmpty);
  });

  testWidgets('perubahan harga ditawarkan untuk diperbarui', (
    WidgetTester tester,
  ) async {
    final validation = CartCheckoutValidation.validate(
      items: <CartItem>[_item()],
      products: <String, Product>{'p1': _product(price: 175000)},
    );
    final harness = await _pumpCart(
      tester,
      displayed: validation,
      onCheckout: validation,
    );

    expect(
      find.text(
        'Harga berubah dari Rp150.000/hari menjadi Rp175.000/hari. Perbarui '
        'harga di keranjang sebelum checkout.',
      ),
      findsOneWidget,
    );

    final action = find.widgetWithText(TextButton, 'Perbarui harga');
    await tester.ensureVisible(action);
    await tester.pump();
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(harness.actions.calls, <String>['refreshStoredPrice:uid-1:p1']);
  });

  testWidgets('kegagalan aksi ditampilkan, bukan dilaporkan sebagai sukses', (
    WidgetTester tester,
  ) async {
    final harness = await _pumpCart(
      tester,
      displayed: _readyValidation(),
      onCheckout: _readyValidation(),
    );
    harness.actions.failure = const AppException(
      'Keranjang tidak dapat diperbarui.',
    );

    await tester.tap(find.byTooltip('Hapus dari keranjang'));
    await tester.pumpAndSettle();

    expect(harness.actions.calls, <String>['removeItem:uid-1:p1']);
    expect(find.text('Keranjang tidak dapat diperbarui.'), findsOneWidget);
    expect(find.text('Menyimpan perubahan…'), findsNothing);
    expect(harness.launched, isEmpty);
  });

  testWidgets('checkout membuka wa.me berisi pesan dari harga terbaru', (
    WidgetTester tester,
  ) async {
    final harness = await _pumpCart(
      tester,
      displayed: _readyValidation(),
      onCheckout: _readyValidation(),
    );

    await _tapCheckout(tester);

    expect(harness.actions.calls, <String>['validateForCheckout:uid-1']);
    expect(harness.launched, hasLength(1));

    final uri = harness.launched.single;
    expect(uri.host, 'wa.me');
    expect(uri.path, '/$_testNumber');

    final message = uri.queryParameters['text'] ?? '';
    expect(message, contains('1. Lumix G85 — Panasonic'));
    expect(message, contains('   Jumlah: 2'));
    expect(message, contains('   Harga satuan: Rp150.000 / hari'));
    expect(message, contains('   Subtotal: Rp300.000'));
    expect(message, contains('TOTAL ESTIMASI: Rp300.000 / hari'));
    expect(message, contains('Nama: Nama Uji'));

    expect(find.textContaining('WhatsApp dibuka'), findsOneWidget);
    expect(harness.copied, isEmpty);
  });

  testWidgets('checkout memakai hasil baca ulang, bukan data yang di layar', (
    WidgetTester tester,
  ) async {
    // Layar masih memakai hasil validasi lama (tombol aktif), tetapi pembacaan
    // ulang tepat sebelum menyusun pesan menemukan stok yang sudah berubah.
    final harness = await _pumpCart(
      tester,
      displayed: _readyValidation(),
      onCheckout: _overStockValidation(),
    );

    expect(_checkoutButton(tester).onPressed, isNotNull);

    await _tapCheckout(tester);

    expect(harness.launched, isEmpty);
    expect(
      find.text('Ada baris keranjang yang perlu diperbaiki sebelum checkout.'),
      findsOneWidget,
    );
  });

  testWidgets('nomor WhatsApp belum dikonfigurasi menjelaskan alasannya', (
    WidgetTester tester,
  ) async {
    await _pumpCart(
      tester,
      displayed: _readyValidation(),
      onCheckout: _readyValidation(),
      whatsappNumber: '',
    );

    expect(
      find.text(
        'Nomor WhatsApp tujuan belum dikonfigurasi, sehingga permintaan sewa '
        'belum dapat dikirim dari aplikasi. Hubungi admin untuk melengkapinya.',
      ),
      findsOneWidget,
    );
    expect(_checkoutButton(tester).onPressed, isNull);
  });

  testWidgets(
    'keranjang kosong saat checkout dijelaskan tanpa membuka tautan',
    (WidgetTester tester) async {
      // Tombol aktif karena layar belum tahu keranjang sudah kosong.
      final harness = await _pumpCart(
        tester,
        displayed: _readyValidation(),
        onCheckout: CartCheckoutValidation.empty,
      );

      await _tapCheckout(tester);

      expect(harness.launched, isEmpty);
      expect(find.text('Keranjang sudah kosong.'), findsOneWidget);
    },
  );
}
