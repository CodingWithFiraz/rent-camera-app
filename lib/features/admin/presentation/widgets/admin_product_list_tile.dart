import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../catalog/domain/price_display.dart';
import '../../../catalog/domain/product.dart';

/// Satu baris produk pada daftar dashboard admin.
///
/// Widget ini presentasional: seluruh aksi diteruskan pemanggil, sehingga tidak
/// ada akses Firestore di dalamnya.
class AdminProductListTile extends StatelessWidget {
  const AdminProductListTile({
    super.key,
    required this.product,
    required this.categoryName,
    required this.isBusy,
    required this.onEdit,
    required this.onToggleActive,
  });

  final Product product;

  /// Nama kategori dari stream `categories`; `null` bila kategori tidak ada pada
  /// daftar aktif (kategori dihapus/nonaktif), sehingga ID dokumennya ditampilkan
  /// apa adanya alih-alih nama yang ditebak.
  final String? categoryName;

  /// `true` selama produk ini sedang diproses (arsip/pulihkan).
  final bool isBusy;

  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = PriceDisplay.forProduct(product);
    final categoryLabel = categoryName ?? product.categoryId;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: SizedBox(
              width: 72,
              height: 72,
              child: ProductImage(
                imageUrl: product.primaryImageUrl,
                semanticLabel: 'Foto ${product.name}',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${product.brand} • $categoryLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(price.text, style: theme.textTheme.bodyMedium),
                Text(
                  'Stok: ${product.stockQuantity}',
                  style: theme.textTheme.bodySmall,
                ),
                if (!product.isActive) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Diarsipkan — tidak tampil di katalog',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: isBusy ? null : onToggleActive,
                      icon: isBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              product.isActive
                                  ? Icons.archive_outlined
                                  : Icons.unarchive_outlined,
                              size: 18,
                            ),
                      label: Text(product.isActive ? 'Arsipkan' : 'Pulihkan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
