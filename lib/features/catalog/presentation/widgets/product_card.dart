import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/product_image.dart';
import '../../domain/price_display.dart';
import '../../domain/product.dart';

/// Kartu produk pada grid katalog.
///
/// Menampilkan foto, nama, brand, harga + periode eksplisit, dan indikator
/// stok. Deskripsi penuh sengaja tidak ditampilkan (hanya di halaman detail),
/// supaya informasi bisa dipindai cepat dan tinggi kartu tetap seragam.
///
/// Semua teks dibatasi `maxLines` + ellipsis dan foto berada di dalam `Expanded`
/// sehingga kartu tidak meluap pada layar sempit maupun saat teks panjang.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;

  /// Membuka halaman detail produk.
  final VoidCallback onTap;

  /// Keterangan stok yang tidak menyesatkan.
  ///
  /// Produk yang sudah diarsipkan atau stoknya nol tidak pernah ditulis
  /// "tersedia".
  String get _stockLabel {
    if (!product.isActive) {
      return 'Tidak tersedia';
    }
    if (product.stockQuantity <= 0) {
      return 'Stok habis';
    }
    return 'Stok ${product.stockQuantity}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = PriceDisplay.forProduct(product);
    final brand = product.brand.trim();
    final isSoldOut = !product.isInStock;

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ProductImage(
                imageUrl: product.primaryImageUrl,
                semanticLabel: 'Foto ${product.name}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (brand.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    price.amountText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                  if (price.hasPeriodLabel)
                    Text(
                      price.periodLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    _stockLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSoldOut
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
