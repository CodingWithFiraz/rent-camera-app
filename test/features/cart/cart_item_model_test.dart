import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/errors/firestore_data_exception.dart';
import 'package:rent_camera_app/features/cart/domain/cart_item.dart';
import 'package:rent_camera_app/features/catalog/domain/price_unit.dart';
import 'package:rent_camera_app/features/catalog/domain/product.dart';

/// Nama field ditulis sebagai literal supaya perubahan schema terdeteksi.
Map<String, dynamic> cartItemData() => <String, dynamic>{
  'productId': 'sony-a7',
  'productNameSnapshot': 'Kamera Uji',
  'brandSnapshot': 'Merek Uji',
  'imageUrlSnapshot': 'https://example.com/sample/kamera.jpg',
  'unitPriceSnapshot': 150000,
  'priceUnitSnapshot': 'per_day',
  'quantity': 2,
};

Matcher throwsField(String field) => throwsA(
  isA<FirestoreDataException>().having((error) => error.field, 'field', field),
);

void main() {
  group('CartItem.fromFirestore', () {
    test('memetakan dokumen lengkap', () {
      final item = CartItem.fromFirestore('sony-a7', cartItemData());

      expect(item.productId, 'sony-a7');
      expect(item.productNameSnapshot, 'Kamera Uji');
      expect(item.brandSnapshot, 'Merek Uji');
      expect(item.imageUrlSnapshot, 'https://example.com/sample/kamera.jpg');
      expect(item.unitPriceSnapshot, 150000);
      expect(item.priceUnitSnapshot, PriceUnit.perDay);
      expect(item.hasConfiguredPriceUnit, isTrue);
      expect(item.quantity, 2);
      expect(item.hasValidQuantity, isTrue);
      expect(item.subtotal, 300000);
    });

    test('memakai snapshot kosong bila field opsional hilang', () {
      final item = CartItem.fromFirestore('sony-a7', <String, dynamic>{
        'unitPriceSnapshot': 1000,
        'quantity': 1,
      });

      expect(item.productNameSnapshot, '');
      expect(item.brandSnapshot, '');
      expect(item.imageUrlSnapshot, '');
      expect(item.priceUnitSnapshot, PriceUnit.unspecified);
      expect(item.hasConfiguredPriceUnit, isFalse);
      expect(item.updatedAt, isNull);
    });

    test('menolak quantity yang hilang, pecahan, atau kurang dari 1', () {
      expect(
        () => CartItem.fromFirestore(
          'sony-a7',
          cartItemData()..remove('quantity'),
        ),
        throwsField('quantity'),
      );
      expect(
        () => CartItem.fromFirestore(
          'sony-a7',
          cartItemData()..['quantity'] = 1.5,
        ),
        throwsA(isA<FirestoreDataException>()),
      );
      expect(
        () =>
            CartItem.fromFirestore('sony-a7', cartItemData()..['quantity'] = 0),
        throwsA(isA<FirestoreDataException>()),
      );
      expect(
        () => CartItem.fromFirestore(
          'sony-a7',
          cartItemData()..['quantity'] = -3,
        ),
        throwsA(isA<FirestoreDataException>()),
      );
    });

    test('menolak harga satuan yang bertipe salah', () {
      expect(
        () => CartItem.fromFirestore(
          'sony-a7',
          cartItemData()..remove('unitPriceSnapshot'),
        ),
        throwsA(isA<FirestoreDataException>()),
      );
      expect(
        () => CartItem.fromFirestore(
          'sony-a7',
          cartItemData()..['unitPriceSnapshot'] = 150000.0,
        ),
        throwsA(isA<FirestoreDataException>()),
      );
      expect(
        () => CartItem.fromFirestore(
          'sony-a7',
          cartItemData()..['unitPriceSnapshot'] = -1,
        ),
        throwsA(isA<FirestoreDataException>()),
      );
    });

    test('menolak productId yang tidak cocok dengan document ID', () {
      expect(
        () => CartItem.fromFirestore(
          'canon-r6',
          cartItemData()..['productId'] = 'sony-a7',
        ),
        throwsField('productId'),
      );
    });

    test('menerima productId kosong karena document ID sudah menentukan', () {
      final item = CartItem.fromFirestore(
        'sony-a7',
        cartItemData()..['productId'] = '  ',
      );

      expect(item.productId, 'sony-a7');
    });
  });

  group('CartItem.fromProduct', () {
    const product = Product(
      id: 'sony-a7',
      name: 'Kamera Uji',
      categoryId: 'kamera',
      brand: 'Merek Uji',
      price: 150000,
      priceUnit: PriceUnit.perDay,
      stockQuantity: 3,
      imageUrls: <String>['https://example.com/sample/kamera.jpg'],
    );

    test('mengambil snapshot dari produk, bukan dari input pengguna', () {
      final item = CartItem.fromProduct(product, quantity: 2);

      expect(item.productId, 'sony-a7');
      expect(item.productNameSnapshot, 'Kamera Uji');
      expect(item.brandSnapshot, 'Merek Uji');
      expect(item.imageUrlSnapshot, 'https://example.com/sample/kamera.jpg');
      expect(item.unitPriceSnapshot, 150000);
      expect(item.priceUnitSnapshot, PriceUnit.perDay);
      expect(item.quantity, 2);
      expect(item.subtotal, 300000);
    });

    test('produk tanpa foto memberi snapshot gambar kosong', () {
      const tanpaFoto = Product(
        id: 'lensa-50mm',
        name: 'Lensa Uji',
        categoryId: 'lensa',
        brand: 'Merek Uji',
        price: 50000,
        stockQuantity: 1,
      );

      expect(CartItem.fromProduct(tanpaFoto).imageUrlSnapshot, '');
    });
  });

  group('CartItem.copyWith', () {
    CartItem item() => CartItem.fromProduct(
      const Product(
        id: 'sony-a7',
        name: 'Kamera Uji',
        categoryId: 'kamera',
        brand: 'Merek Uji',
        price: 150000,
        stockQuantity: 5,
      ),
    );

    test('mengubah quantity tanpa menyentuh snapshot', () {
      final updated = item().copyWith(quantity: 3);

      expect(updated.quantity, 3);
      expect(updated.productId, 'sony-a7');
      expect(updated.unitPriceSnapshot, 150000);
      expect(updated.subtotal, 450000);
    });

    test('menandai quantity di luar rentang sebagai tidak valid', () {
      expect(item().copyWith(quantity: 0).hasValidQuantity, isFalse);
      expect(
        item().copyWith(quantity: CartItem.maxQuantity + 1).hasValidQuantity,
        isFalse,
      );
      expect(
        item().copyWith(quantity: CartItem.maxQuantity).hasValidQuantity,
        isTrue,
      );
    });
  });
}
