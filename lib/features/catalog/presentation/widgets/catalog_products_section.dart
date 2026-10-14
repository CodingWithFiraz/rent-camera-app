import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/repository_error_mapper.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/catalog_filter.dart';
import '../../domain/product.dart';
import '../catalog_providers.dart';
import 'product_card.dart';

/// Bagian daftar produk katalog beserta keadaan memuat, gagal, dan kosong.
///
/// Sumber datanya `catalogProductsProvider` (stream produk aktif dari
/// repository yang sudah disaring pencarian/filter), sehingga keadaan yang
/// ditampilkan selalu berasal dari data Firestore — tidak ada daftar contoh
/// pengganti saat data belum ada.
class CatalogProductsSection extends ConsumerWidget {
  const CatalogProductsSection({
    super.key,
    required this.onOpenProduct,
    required this.onResetFilters,
  });

  /// Membuka halaman detail produk yang dipilih.
  final ValueChanged<Product> onOpenProduct;

  /// Mengembalikan katalog ke keadaan tanpa kriteria pencarian/filter.
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(catalogProductsProvider);
    final filter = ref.watch(catalogFilterProvider);

    return productsAsync.when(
      loading: () => const AppLoading(label: 'Memuat produk…'),
      error: (Object error, StackTrace stackTrace) => AppErrorState(
        title: 'Katalog belum dapat dimuat',
        message: repositoryErrorMessageFor(error, entityLabel: 'produk'),
        onRetry: () =>
            ref.invalidate(activeProductsProvider(filter.categoryId)),
      ),
      data: (List<Product> products) => products.isEmpty
          ? _CatalogEmptyState(filter: filter, onResetFilters: onResetFilters)
          : _ProductGrid(products: products, onOpenProduct: onOpenProduct),
    );
  }
}

/// Keadaan kosong: dibedakan antara katalog yang memang belum berisi produk dan
/// pencarian/filter yang tidak menemukan hasil, karena tindakan lanjutannya
/// berbeda (tunggu data admin vs ubah kriteria).
class _CatalogEmptyState extends StatelessWidget {
  const _CatalogEmptyState({
    required this.filter,
    required this.onResetFilters,
  });

  final CatalogFilter filter;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    if (!filter.isFiltering) {
      return const AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Katalog masih kosong',
        message:
            'Belum ada produk aktif yang dapat ditampilkan. Produk akan '
            'muncul di sini setelah admin menambahkannya dan menandainya aktif.',
      );
    }

    return AppEmptyState(
      icon: Icons.search_off_outlined,
      title: 'Tidak ada produk yang cocok',
      message:
          'Kata kunci atau filter yang dipakai belum menemukan produk. '
          'Ubah kriteria atau hapus filter untuk melihat semua produk.',
      action: OutlinedButton.icon(
        onPressed: onResetFilters,
        icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
        label: const Text('Hapus filter'),
      ),
    );
  }
}

/// Grid produk responsif.
///
/// Jumlah kolom mengikuti lebar yang tersedia (bukan lebar layar perangkat),
/// dan tinggi kartu ditentukan rasio tetap sehingga tidak ada ukuran piksel
/// yang membuat kartu meluap pada layar sempit maupun teks panjang.
class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products, required this.onOpenProduct});

  final List<Product> products;
  final ValueChanged<Product> onOpenProduct;

  /// Batas lebar untuk jumlah kolom; sengaja dalam satu tempat agar perubahan
  /// tata letak tidak tersebar.
  static const double _twoColumnMaxWidth = 480;
  static const double _threeColumnMaxWidth = 820;

  static int columnCountFor(double width) {
    if (width < _twoColumnMaxWidth) {
      return 2;
    }
    if (width < _threeColumnMaxWidth) {
      return 3;
    }
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final columns = columnCountFor(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (BuildContext context, int index) {
            final product = products[index];
            return ProductCard(
              product: product,
              onTap: () => onOpenProduct(product),
            );
          },
        );
      },
    );
  }
}
