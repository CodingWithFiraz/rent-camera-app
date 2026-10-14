import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/features/cart/domain/cart_checkout.dart';
import 'package:rent_camera_app/features/cart/domain/cart_item.dart';
import 'package:rent_camera_app/features/catalog/domain/price_unit.dart';
import 'package:rent_camera_app/features/catalog/domain/product.dart';

const String _productId = 'kamera-lumix-g85';
const String _missingProductId = 'lensa-50mm';

Product _product({
  String id = _productId,
  String name = 'Lumix G85',
  String brand = 'Panasonic',
  int price = 150000,
  PriceUnit priceUnit = PriceUnit.perDay,
  int stockQuantity = 3,
  bool isActive = true,
}) => Product(
  id: id,
  name: name,
  categoryId: 'kamera',
  brand: brand,
  price: price,
  priceUnit: priceUnit,
  stockQuantity: stockQuantity,
  imageUrls: const <String>['https://example.com/sample/lumix.jpg'],
  isActive: isActive,
);

CartItem _item({
  String productId = _productId,
  String name = 'Lumix G85',
  String brand = 'Panasonic',
  String imageUrl = 'https://example.com/sample/snapshot-lama.jpg',
  int unitPrice = 150000,
  PriceUnit priceUnit = PriceUnit.perDay,
  int quantity = 1,
}) => CartItem(
  productId: productId,
  productNameSnapshot: name,
  brandSnapshot: brand,
  imageUrlSnapshot: imageUrl,
  unitPriceSnapshot: unitPrice,
  priceUnitSnapshot: priceUnit,
  quantity: quantity,
);

CartCheckoutValidation _validate(
  List<CartItem> items,
  List<Product> products,
) => CartCheckoutValidation.validate(
  items: items,
  products: <String, Product>{
    for (final product in products) product.id: product,
  },
);

void main() {
  group('CartCheckoutValidation.validate', () {
    test('memakai data dokumen terbaru, bukan snapshot keranjang', () {
      final validation = _validate(
        <CartItem>[_item(quantity: 2)],
        <Product>[_product()],
      );
      final line = validation.lines.single;

      expect(line.productId, _productId);
      expect(line.quantity, 2);
      // Nama, brand, dan foto selalu dari dokumen produk terbaru.
      expect(line.name, 'Lumix G85');
      expect(line.brand, 'Panasonic');
      expect(line.imageUrl, 'https://example.com/sample/lumix.jpg');
      expect(line.unitPrice, 150000);
      expect(line.priceUnit, PriceUnit.perDay);
      expect(line.periodLabel, '/hari');
      expect(line.periodWord, 'hari');
      expect(line.unitPriceText, 'Rp150.000');
      expect(line.subtotal, 300000);
      expect(line.availableStock, 3);
      expect(line.selectableMaxQuantity, 3);
      expect(line.recommendedQuantityForStock, 3);
      expect(line.canChangeQuantity, isTrue);
      expect(line.issue, isNull);
      expect(line.isUsable, isTrue);
      expect(validation.isEmpty, isFalse);
      expect(validation.hasLines, isTrue);
      expect(validation.hasIssues, isFalse);
      expect(validation.blockedLineCount, 0);
      expect(validation.isReady, isTrue);
      expect(validation.total, 300000);
      expect(validation.totalText, 'Rp300.000 / hari');
    });

    test('produk yang hilang dari katalog ditandai, bukan dibuang', () {
      final validation = _validate(<CartItem>[
        _item(quantity: 2),
      ], const <Product>[]);
      final line = validation.lines.single;

      expect(line.issue?.kind, CartCheckoutIssueKind.productMissing);
      expect(line.issue?.message, contains('sudah tidak ada di katalog'));
      // Yang tersisa hanya snapshot keranjang.
      expect(line.name, 'Lumix G85');
      expect(line.unitPrice, 150000);
      // Stok tidak dapat dipastikan, jadi dibiarkan `null` bukan dianggap 0.
      expect(line.availableStock, isNull);
      expect(line.selectableMaxQuantity, isNull);
      expect(line.recommendedQuantityForStock, isNull);
      expect(line.canChangeQuantity, isFalse);
      expect(line.isUsable, isFalse);
      expect(validation.usableLines, isEmpty);
      expect(validation.blockedLineCount, 1);
      expect(validation.hasIssues, isTrue);
      expect(validation.isReady, isFalse);
      // Baris bermasalah tidak dijumlahkan ke total.
      expect(validation.total, 0);
      expect(validation.totalText, 'Rp0');
    });

    test('produk yang diarsipkan admin tidak dapat dipesan', () {
      final validation = _validate(
        <CartItem>[_item()],
        <Product>[_product(isActive: false)],
      );
      final line = validation.lines.single;

      expect(line.issue?.kind, CartCheckoutIssueKind.productInactive);
      expect(line.issue?.message, contains('sudah tidak dipasarkan'));
      expect(line.isUsable, isFalse);
      expect(validation.isReady, isFalse);
    });

    test('harga yang belum diisi admin bukan berarti sewa gratis', () {
      final validation = _validate(
        <CartItem>[_item(quantity: 3)],
        <Product>[_product(price: 0)],
      );
      final line = validation.lines.single;

      expect(line.issue?.kind, CartCheckoutIssueKind.priceNotConfigured);
      expect(line.issue?.message, contains('Admin belum mengisi harga'));
      // Harga 0 tidak pernah ditampilkan sebagai angka Rupiah.
      expect(line.unitPriceText, 'Harga belum diisi');
      expect(line.subtotal, 0);
      expect(validation.total, 0);
      expect(validation.isReady, isFalse);
    });

    test('harga berubah menampilkan harga terbaru dan menahan checkout', () {
      final validation = _validate(
        <CartItem>[_item(unitPrice: 150000, quantity: 2)],
        <Product>[_product(price: 200000)],
      );
      final line = validation.lines.single;

      expect(line.issue?.kind, CartCheckoutIssueKind.priceChanged);
      expect(line.unitPrice, 200000);
      expect(line.unitPriceText, 'Rp200.000');
      expect(line.subtotal, 400000);
      expect(line.issue?.message, contains('Rp150.000/hari'));
      expect(line.issue?.message, contains('Rp200.000/hari'));
      expect(line.issue?.message, contains('Perbarui harga di keranjang'));
      expect(validation.total, 0);
      expect(validation.isReady, isFalse);
    });

    test('perubahan satuan periode juga menahan checkout', () {
      final validation = _validate(
        <CartItem>[_item(unitPrice: 150000, priceUnit: PriceUnit.perDay)],
        <Product>[_product(price: 150000, priceUnit: PriceUnit.perSession)],
      );
      final line = validation.lines.single;

      expect(line.issue?.kind, CartCheckoutIssueKind.priceUnitChanged);
      expect(line.priceUnit, PriceUnit.perSession);
      expect(line.periodLabel, '/sesi');
      expect(line.issue?.message, contains('Satuan harga berubah'));
      expect(validation.isReady, isFalse);
    });

    test('jumlah yang melebihi stok dapat diturunkan tanpa hapus baris', () {
      final validation = _validate(
        <CartItem>[_item(quantity: 5)],
        <Product>[_product(stockQuantity: 3)],
      );
      final line = validation.lines.single;

      expect(line.issue?.kind, CartCheckoutIssueKind.insufficientStock);
      expect(line.issue?.message, contains('Stok terbaru hanya 3'));
      expect(line.issue?.message, contains('meminta 5'));
      expect(line.availableStock, 3);
      expect(line.selectableMaxQuantity, 3);
      expect(line.recommendedQuantityForStock, 3);
      // Menurunkan jumlah adalah perbaikan yang sah, jadi baris tidak dikunci.
      expect(line.canChangeQuantity, isTrue);
      expect(line.isUsable, isFalse);
      expect(validation.isReady, isFalse);
    });

    test('stok habis hanya dapat diperbaiki dengan menghapus baris', () {
      final validation = _validate(
        <CartItem>[_item(quantity: 2)],
        <Product>[_product(stockQuantity: 0)],
      );
      final line = validation.lines.single;

      expect(line.issue?.kind, CartCheckoutIssueKind.insufficientStock);
      expect(line.issue?.message, contains('sedang habis'));
      expect(line.availableStock, 0);
      expect(line.selectableMaxQuantity, isNull);
      expect(line.recommendedQuantityForStock, isNull);
      expect(line.canChangeQuantity, isFalse);
      expect(validation.isReady, isFalse);
    });

    test('batas jumlah mengikuti batas maksimum keranjang', () {
      final validation = _validate(
        <CartItem>[_item()],
        <Product>[_product(stockQuantity: CartItem.maxQuantity + 50)],
      );

      expect(
        validation.lines.single.selectableMaxQuantity,
        CartItem.maxQuantity,
      );
    });

    test('satuan periode yang belum ditetapkan tidak dikarang', () {
      final validation = _validate(
        <CartItem>[_item(priceUnit: PriceUnit.unspecified, quantity: 2)],
        <Product>[_product(priceUnit: PriceUnit.unspecified, stockQuantity: 5)],
      );
      final line = validation.lines.single;

      expect(line.periodLabel, isNull);
      expect(line.periodWord, isNull);
      expect(line.unitPriceText, 'Rp150.000');
      expect(validation.isReady, isTrue);
      // Tanpa satuan yang ditetapkan, total tidak menempelkan periode apa pun.
      expect(validation.totalText, 'Rp300.000');
      expect(validation.toWhatsAppLines().single.periodLabel, isNull);
    });
  });

  group('CartCheckoutValidation tanpa baris', () {
    test('keranjang kosong bukan keranjang siap checkout', () {
      expect(CartCheckoutValidation.empty.isEmpty, isTrue);
      expect(CartCheckoutValidation.empty.hasLines, isFalse);
      expect(CartCheckoutValidation.empty.usableLines, isEmpty);
      expect(CartCheckoutValidation.empty.blockedLineCount, 0);
      expect(CartCheckoutValidation.empty.hasIssues, isFalse);
      expect(CartCheckoutValidation.empty.isReady, isFalse);
      expect(CartCheckoutValidation.empty.total, 0);
      expect(CartCheckoutValidation.empty.totalText, 'Rp0');
      expect(CartCheckoutValidation.empty.toWhatsAppLines(), isEmpty);
    });

    test('hasil validasi keranjang kosong sama dengan empty', () {
      final validation = CartCheckoutValidation.validate(
        items: const <CartItem>[],
        products: const <String, Product>{},
      );

      expect(validation.isEmpty, isTrue);
      expect(validation.isReady, isFalse);
      expect(validation.hasIssues, isFalse);
      expect(validation.blockedLineCount, 0);
    });
  });

  group('CartCheckoutValidation pesan checkout', () {
    test('pesan dibangun hanya dari baris yang siap dipesan', () {
      final validation = _validate(
        <CartItem>[
          _item(quantity: 1),
          _item(
            productId: _missingProductId,
            name: 'Nama Snapshot Lama',
            quantity: 2,
          ),
        ],
        <Product>[_product()],
      );

      expect(validation.blockedLineCount, 1);
      expect(validation.usableLines, hasLength(1));

      final message = validation.buildWhatsAppMessage(customerName: 'Nama Uji');

      expect(message, contains('1. Lumix G85 — Panasonic'));
      // Baris yang produknya hilang tidak pernah masuk pesan.
      expect(message, isNot(contains('Nama Snapshot Lama')));
      expect(message, contains('TOTAL ESTIMASI: Rp150.000 / hari'));
      expect(message, endsWith('Nama: Nama Uji'));
    });

    test('baris bermasalah menahan pembangunan pesan checkout', () {
      final validation = _validate(
        <CartItem>[_item(unitPrice: 100000)],
        <Product>[_product(price: 150000)],
      );

      expect(validation.isReady, isFalse);
      expect(() => validation.buildWhatsAppMessage(), throwsArgumentError);
    });

    test('keranjang kosong menahan pembangunan pesan checkout', () {
      expect(
        () => CartCheckoutValidation.empty.buildWhatsAppMessage(),
        throwsArgumentError,
      );
    });

    test('daftar baris tidak dapat diubah dari luar', () {
      final validation = _validate(<CartItem>[_item()], <Product>[_product()]);

      expect(
        () => validation.lines.add(validation.lines.single),
        throwsUnsupportedError,
      );
      expect(
        () => validation.usableLines.add(validation.lines.single),
        throwsUnsupportedError,
      );
    });
  });
}
