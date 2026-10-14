import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/features/catalog/domain/catalog_filter.dart';
import 'package:rent_camera_app/features/catalog/domain/product.dart';

/// Produk uji: filter bekerja pada data yang sudah dimuat, jadi test ini tidak
/// menyentuh Firestore.
Product _product({
  required String id,
  required String name,
  String categoryId = 'kamera',
  String brand = 'Panasonic',
  String description = '',
}) => Product(
  id: id,
  name: name,
  categoryId: categoryId,
  brand: brand,
  price: 150000,
  stockQuantity: 2,
  description: description,
);

List<String> _ids(List<Product> products) =>
    products.map((Product product) => product.id).toList();

void main() {
  final products = <Product>[
    _product(id: 'p1', name: 'Lumix G85', brand: 'Panasonic'),
    _product(id: 'p2', name: 'Sony A7 III', brand: 'Sony'),
    _product(
      id: 'p3',
      name: 'Lensa 50mm',
      categoryId: 'lensa',
      brand: 'Canon',
      description: 'Lensa serbaguna untuk potret',
    ),
  ];

  test('kriteria kosong menampilkan semua produk, terurut nama', () {
    expect(_ids(CatalogFilter.none.apply(products)), <String>[
      'p3',
      'p1',
      'p2',
    ]);
    expect(CatalogFilter.none.isFiltering, isFalse);
  });

  test('pencarian digabung dengan kategori dan brand (AND)', () {
    // "son" cocok dengan brand "Panasonic" dan "Sony", jadi pencarian saja
    // menghasilkan dua produk sebelum dipersempit kategori/brand.
    expect(_ids(const CatalogFilter(query: 'son').apply(products)), <String>[
      'p1',
      'p2',
    ]);

    const cocok = CatalogFilter(
      query: 'son',
      categoryId: 'kamera',
      brand: 'Sony',
    );
    const brandSalah = CatalogFilter(
      query: 'son',
      categoryId: 'kamera',
      brand: 'Canon',
    );
    const kategoriSalah = CatalogFilter(
      query: 'a7',
      categoryId: 'lensa',
      brand: 'Sony',
    );

    expect(_ids(cocok.apply(products)), <String>['p2']);
    expect(brandSalah.apply(products), isEmpty);
    expect(kategoriSalah.apply(products), isEmpty);
  });

  test('pencarian mengabaikan besar/kecil huruf dan spasi tepi', () {
    expect(
      _ids(const CatalogFilter(query: '  LUMIX  ').apply(products)),
      <String>['p1'],
    );
  });

  test('pencarian juga mencocokkan brand dan deskripsi', () {
    expect(_ids(const CatalogFilter(query: 'canon').apply(products)), <String>[
      'p3',
    ]);
    expect(_ids(const CatalogFilter(query: 'potret').apply(products)), <String>[
      'p3',
    ]);
  });

  test('pencarian tidak mencocokkan kategori', () {
    // "kamera" punya filter tersendiri; mengetiknya tidak boleh menampilkan
    // seluruh isi kategori kamera.
    final withCategoryNameOnly = <Product>[
      ...products,
      _product(id: 'p4', name: 'Tripod', categoryId: 'kamera'),
    ];

    expect(
      _ids(const CatalogFilter(query: 'kamera').apply(withCategoryNameOnly)),
      isEmpty,
    );
  });

  test('filter brand tidak membedakan besar/kecil huruf', () {
    expect(_ids(const CatalogFilter(brand: 'sony').apply(products)), <String>[
      'p2',
    ]);
  });

  test('copyWith dapat mengosongkan kategori dan brand', () {
    const filter = CatalogFilter(
      query: 'son',
      categoryId: 'kamera',
      brand: 'Sony',
    );
    final dikosongkan = filter.copyWith(clearCategory: true, clearBrand: true);

    expect(dikosongkan.query, 'son');
    expect(dikosongkan.categoryId, isNull);
    expect(dikosongkan.brand, isNull);
    expect(dikosongkan.hasCategory, isFalse);
    expect(dikosongkan.hasBrand, isFalse);
    expect(dikosongkan.hasQuery, isTrue);
    expect(dikosongkan.isFiltering, isTrue);
  });

  test('copyWith tanpa nilai baru mempertahankan kriteria lain', () {
    const filter = CatalogFilter(categoryId: 'kamera', brand: 'Sony');
    final bergantiQuery = filter.copyWith(query: 'a7');

    expect(bergantiQuery.query, 'a7');
    expect(bergantiQuery.categoryId, 'kamera');
    expect(bergantiQuery.brand, 'Sony');
  });

  test('hasil apply tidak dapat diubah pemanggil', () {
    final hasil = CatalogFilter.none.apply(products);

    expect(() => hasil.add(products.first), throwsUnsupportedError);
  });
}
