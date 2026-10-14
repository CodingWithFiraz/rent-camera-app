import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/features/admin/domain/product_draft.dart';
import 'package:rent_camera_app/features/catalog/domain/price_unit.dart';
import 'package:rent_camera_app/features/catalog/domain/product.dart';

/// Test validasi form produk admin (`docs/BLUEPRINT_APLIKASI.md` §6.2 dan §8).
///
/// Validasi ini murni (tanpa Firebase) supaya nilai yang salah ketik ditolak
/// sebelum menyentuh Firestore; repository tetap mengulang pemeriksaan sebagai
/// pertahanan terakhir.
/// Produk uji lengkap dengan seluruh field form admin terisi.
Product _product() => const Product(
  id: 'p1',
  name: 'Sony A7 III',
  description: 'Kamera mirrorless',
  categoryId: 'kamera',
  brand: 'Sony',
  price: 250000,
  priceUnit: PriceUnit.perDay,
  stockQuantity: 3,
  imageUrls: <String>['https://contoh/foto.jpg'],
  isActive: false,
);

void main() {
  group('ProductDraft.fromProduct', () {
    test('menyalin seluruh field form dari dokumen produk', () {
      final draft = ProductDraft.fromProduct(_product());
      expect(draft.name, 'Sony A7 III');
      expect(draft.description, 'Kamera mirrorless');
      expect(draft.categoryId, 'kamera');
      expect(draft.brand, 'Sony');
      expect(draft.price, 250000);
      expect(draft.priceUnit, PriceUnit.perDay);
      expect(draft.stockQuantity, 3);
      expect(draft.imageUrls, <String>['https://contoh/foto.jpg']);
      expect(draft.isActive, isFalse);
    });

    test('copyWith hanya mengubah field yang diberikan', () {
      final draft = ProductDraft.fromProduct(_product())
          .copyWith(price: 300000, isActive: true);
      expect(draft.price, 300000);
      expect(draft.isActive, isTrue);
      expect(draft.name, 'Sony A7 III');
      expect(draft.stockQuantity, 3);
    });
  });

  group('ProductDraftValidation.name', () {
    test('menolak kosong dan terlalu pendek', () {
      expect(ProductDraftValidation.name(null), isNotNull);
      expect(ProductDraftValidation.name('   '), isNotNull);
      expect(ProductDraftValidation.name('a'), isNotNull);
    });

    test('menolak nama yang terlalu panjang', () {
      final tooLong = 'a' * (ProductDraftValidation.maxNameLength + 1);
      expect(ProductDraftValidation.name(tooLong), isNotNull);
    });

    test('menerima nama yang wajar', () {
      expect(ProductDraftValidation.name('Sony A7 III'), isNull);
    });
  });

  group('ProductDraftValidation.price', () {
    test('menolak kosong, negatif, dan bukan angka', () {
      expect(ProductDraftValidation.price(''), isNotNull);
      expect(ProductDraftValidation.price('-1000'), isNotNull);
      expect(ProductDraftValidation.price('1000 rupiah'), isNotNull);
      expect(ProductDraftValidation.price('Rp1.000'), isNotNull);
    });

    test('menerima angka dengan pemisah ribuan', () {
      expect(ProductDraftValidation.price('250.000'), isNull);
    });

    test('menolak angka di atas batas wajar', () {
      final tooBig = (ProductDraftValidation.maxPrice + 1).toString();
      expect(ProductDraftValidation.price(tooBig), isNotNull);
    });
  });

  group('ProductDraftValidation.stockQuantity', () {
    test('menolak kosong dan negatif', () {
      expect(ProductDraftValidation.stockQuantity(''), isNotNull);
      expect(ProductDraftValidation.stockQuantity('-2'), isNotNull);
    });

    test('menerima nol dan menolak di atas batas', () {
      expect(ProductDraftValidation.stockQuantity('0'), isNull);
      final tooBig = (ProductDraftValidation.maxStockQuantity + 1).toString();
      expect(ProductDraftValidation.stockQuantity(tooBig), isNotNull);
    });
  });

  group('ProductDraftValidation lain', () {
    test('kategori wajib dipilih', () {
      expect(ProductDraftValidation.categoryId(null), isNotNull);
      expect(ProductDraftValidation.categoryId('  '), isNotNull);
      expect(ProductDraftValidation.categoryId('kamera'), isNull);
    });

    test('brand wajib diisi dan dibatasi panjangnya', () {
      expect(ProductDraftValidation.brand(''), isNotNull);
      expect(ProductDraftValidation.brand('Sony'), isNull);
      final tooLong = 'a' * (ProductDraftValidation.maxBrandLength + 1);
      expect(ProductDraftValidation.brand(tooLong), isNotNull);
    });

    test('deskripsi opsional tetapi dibatasi panjangnya', () {
      expect(ProductDraftValidation.description(''), isNull);
      expect(ProductDraftValidation.description(null), isNull);
      final tooLong = 'a' * (ProductDraftValidation.maxDescriptionLength + 1);
      expect(ProductDraftValidation.description(tooLong), isNotNull);
    });
  });

  group('ProductDraftValidation.tryParseInteger', () {
    test('mengabaikan pemisah ribuan', () {
      expect(ProductDraftValidation.tryParseInteger('150.000'), 150000);
      expect(ProductDraftValidation.tryParseInteger('1,500'), 1500);
      expect(ProductDraftValidation.tryParseInteger(' 250000 '), 250000);
    });

    test('mengembalikan null untuk nilai tidak sah', () {
      expect(ProductDraftValidation.tryParseInteger(null), isNull);
      expect(ProductDraftValidation.tryParseInteger(''), isNull);
      expect(ProductDraftValidation.tryParseInteger('-5'), isNull);
      expect(ProductDraftValidation.tryParseInteger('seribu'), isNull);
    });
  });
}
