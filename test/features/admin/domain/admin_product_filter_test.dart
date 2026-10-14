import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/features/admin/domain/admin_product_filter.dart';
import 'package:rent_camera_app/features/catalog/domain/product.dart';

/// Test pencarian/filter daftar produk admin.
///
/// Dashboard memfilter hasil query Firestore di klien supaya tidak membutuhkan
/// composite index; perilaku ini diuji tanpa Firestore.
/// Pembuat produk uji dengan nilai default yang mudah ditimpa.
Product _product({
  required String id,
  required String name,
  String brand = 'Sony',
  String categoryId = 'kamera',
  bool isActive = true,
}) => Product(
  id: id,
  name: name,
  categoryId: categoryId,
  brand: brand,
  price: 100000,
  stockQuantity: 2,
  isActive: isActive,
);

void main() {
  final products = <Product>[
    _product(id: 'p1', name: 'Sony A7 III'),
    _product(id: 'p2', name: 'Canon EOS R6', brand: 'Canon'),
    _product(id: 'p3', name: 'Sony FX3 Arsip', isActive: false),
    _product(
      id: 'p4',
      name: 'Lensa Sigma 24-70',
      brand: 'Sigma',
      categoryId: 'lensa',
    ),
  ];

  test('keadaan tanpa kriteria tidak menyaring apa pun', () {
    const filter = AdminProductFilter.none;
    expect(filter.isFiltering, isFalse);
    expect(filter.apply(products), products);
  });

  test('pencarian mencocokkan nama, brand, dan ID kategori', () {
    expect(const AdminProductFilter(query: 'sony').apply(products), <Product>[
      products[0],
      products[2],
    ]);
    expect(const AdminProductFilter(query: 'CANON').apply(products), <Product>[
      products[1],
    ]);
    expect(const AdminProductFilter(query: 'lensa').apply(products), <Product>[
      products[3],
    ]);
    expect(
      const AdminProductFilter(query: 'tidak ada').apply(products),
      isEmpty,
    );
  });

  test('filter status memisahkan produk aktif dan arsip', () {
    expect(
      const AdminProductFilter(visibility: AdminProductVisibility.active)
          .apply(products)
          .map((Product p) => p.id),
      <String>['p1', 'p2', 'p4'],
    );
    expect(
      const AdminProductFilter(visibility: AdminProductVisibility.archived)
          .apply(products)
          .map((Product p) => p.id),
      <String>['p3'],
    );
  });

  test('pencarian dan filter status digabungkan', () {
    const filter = AdminProductFilter(
      query: 'sony',
      visibility: AdminProductVisibility.active,
    );
    expect(filter.isFiltering, isTrue);
    expect(filter.apply(products).map((Product p) => p.id), <String>['p1']);
  });

  test('copyWith tidak mengubah field yang tidak diberikan', () {
    const filter = AdminProductFilter(query: 'sony');
    final updated = filter.copyWith(
      visibility: AdminProductVisibility.archived,
    );
    expect(updated.query, 'sony');
    expect(updated.visibility, AdminProductVisibility.archived);
  });

  test('ringkasan menghitung total, aktif, dan arsip dari data nyata', () {
    final summary = AdminProductSummary.fromProducts(products);
    expect(summary.total, 4);
    expect(summary.active, 3);
    expect(summary.archived, 1);
    expect(const AdminProductSummary.empty().total, 0);
  });
}
