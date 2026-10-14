import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/errors/firestore_data_exception.dart';
import 'package:rent_camera_app/features/catalog/domain/price_unit.dart';
import 'package:rent_camera_app/features/catalog/domain/product.dart';

/// Nama field ditulis sebagai literal (bukan konstanta aplikasi) supaya
/// perubahan nama field pada schema terdeteksi sebagai kegagalan test, bukan
/// ikut berubah diam-diam.
Map<String, dynamic> productData() => <String, dynamic>{
  'name': 'Kamera Uji',
  'description': 'Deskripsi contoh.',
  'categoryId': 'kamera',
  'brand': 'Merek Uji',
  'price': 150000,
  'priceUnit': 'per_day',
  'stockQuantity': 3,
  'imageUrls': <String>['https://contoh.test/kamera.jpg'],
  'isActive': true,
  'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
};

void main() {
  group('Product.fromFirestore', () {
    test('memetakan dokumen lengkap', () {
      final product = Product.fromFirestore('sony-a7', productData());

      expect(product.id, 'sony-a7');
      expect(product.name, 'Kamera Uji');
      expect(product.description, 'Deskripsi contoh.');
      expect(product.categoryId, 'kamera');
      expect(product.brand, 'Merek Uji');
      expect(product.price, 150000);
      expect(product.priceUnit, PriceUnit.perDay);
      expect(product.hasConfiguredPriceUnit, isTrue);
      expect(product.stockQuantity, 3);
      expect(product.imageUrls, <String>['https://contoh.test/kamera.jpg']);
      expect(product.primaryImageUrl, 'https://contoh.test/kamera.jpg');
      expect(product.isActive, isTrue);
      // `Timestamp.toDate()` mengembalikan waktu lokal, jadi dibandingkan dalam UTC.
      expect(product.createdAt?.toUtc(), DateTime.utc(2026, 1, 2));
      expect(product.isInStock, isTrue);
      expect(product.maxOrderableQuantity, 3);
    });

    test('memakai nilai fallback terdokumentasi untuk field opsional', () {
      final product = Product.fromFirestore('produk-baru', <String, dynamic>{
        'name': 'Produk Baru',
        'categoryId': 'kamera',
        'brand': 'Merek',
        'price': 1000,
        'stockQuantity': 0,
      });

      expect(product.description, '');
      expect(product.priceUnit, PriceUnit.unspecified);
      expect(product.hasConfiguredPriceUnit, isFalse);
      expect(product.imageUrls, isEmpty);
      expect(product.primaryImageUrl, isNull);
      expect(product.isActive, isTrue);
      expect(product.isInStock, isFalse);
      expect(product.createdAt, isNull);
    });

    test('menolak field wajib yang hilang', () {
      for (final field in <String>[
        'name',
        'categoryId',
        'brand',
        'price',
        'stockQuantity',
      ]) {
        final data = productData()..remove(field);
        expect(
          () => Product.fromFirestore('p1', data),
          throwsA(
            isA<FirestoreDataException>().having(
              (error) => error.field,
              'field',
              field,
            ),
          ),
          reason: 'field $field harus ditolak saat hilang',
        );
      }
    });

    test('menolak harga yang bukan integer Rupiah', () {
      expect(
        () => Product.fromFirestore('p1', productData()..['price'] = 150000.0),
        throwsA(isA<FirestoreDataException>()),
      );
      expect(
        () => Product.fromFirestore('p1', productData()..['price'] = '150000'),
        throwsA(isA<FirestoreDataException>()),
      );
      expect(
        () => Product.fromFirestore('p1', productData()..['price'] = -1),
        throwsA(isA<FirestoreDataException>()),
      );
    });

    test('menolak stok dan status yang bertipe salah', () {
      expect(
        () =>
            Product.fromFirestore('p1', productData()..['stockQuantity'] = -1),
        throwsA(isA<FirestoreDataException>()),
      );
      expect(
        () =>
            Product.fromFirestore('p1', productData()..['stockQuantity'] = 2.5),
        throwsA(isA<FirestoreDataException>()),
      );
      expect(
        () => Product.fromFirestore('p1', productData()..['isActive'] = 'ya'),
        throwsA(isA<FirestoreDataException>()),
      );
    });

    test('menolak daftar foto yang memuat bukan teks', () {
      expect(
        () => Product.fromFirestore(
          'p1',
          productData()
            ..['imageUrls'] = <Object>[1, 'https://contoh.test/a.jpg'],
        ),
        throwsA(isA<FirestoreDataException>()),
      );
    });

    test('menolak teks nama yang kosong', () {
      expect(
        () => Product.fromFirestore('p1', productData()..['name'] = '   '),
        throwsA(isA<FirestoreDataException>()),
      );
    });
  });
}
