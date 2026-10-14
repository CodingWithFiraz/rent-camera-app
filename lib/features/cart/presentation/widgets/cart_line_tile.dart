import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../catalog/presentation/widgets/catalog_section_notice.dart';

/// Satu baris keranjang: foto mini, identitas alat, harga, jumlah, dan subtotal.
///
/// Widget ini hanya menampilkan data yang diberikan pemanggil dan meneruskan
/// aksi lewat callback: tidak ada perhitungan harga, penulisan Firestore, atau
/// pembacaan stok di sini. Saat [isBusy] seluruh kontrol dinonaktifkan supaya
/// satu baris tidak mengirim dua perubahan sekaligus.
class CartLineTile extends StatelessWidget {
  const CartLineTile({
    super.key,
    required this.name,
    required this.quantity,
    required this.unitPriceText,
    required this.subtotalText,
    this.brand = '',
    this.imageUrl = '',
    this.periodLabel,
    this.stockNote,
    this.issueMessage,
    this.quantityNote,
    this.issueActionLabel,
    this.onIssueAction,
    this.onIncrease,
    this.onDecrease,
    this.onRemove,
    this.isBusy = false,
  });

  /// Nama alat seperti pada dokumen produk/keranjang.
  final String name;

  final String brand;

  /// URL foto utama; kosong berarti foto belum ada.
  final String imageUrl;

  final int quantity;

  /// Harga satuan tanpa periode, mis. `Rp150.000` atau `Harga belum diisi`.
  final String unitPriceText;

  /// Label satuan periode (`/hari`); `null` berarti belum ditetapkan dokumen.
  final String? periodLabel;

  /// Subtotal baris, mis. `Rp300.000`.
  final String subtotalText;

  /// Keterangan stok terverifikasi, mis. `Stok terbaru: 3`.
  final String? stockNote;

  /// Masalah yang membuat baris ini belum dapat dipesan; `null` berarti siap.
  final String? issueMessage;

  /// Keterangan mengapa jumlah tidak dapat diubah saat ini.
  final String? quantityNote;

  /// Label tombol perbaikan pada [issueMessage].
  final String? issueActionLabel;

  final VoidCallback? onIssueAction;

  /// `null` berarti penambahan jumlah tidak tersedia (stok terbatas atau stok
  /// belum terverifikasi), bukan tombol yang tampak aktif tetapi diam.
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;

  /// `null` menonaktifkan tombol hapus (mis. saat baris sedang menyimpan).
  final VoidCallback? onRemove;

  /// `true` saat baris sedang menyimpan perubahan.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandText = brand.trim();
    final stock = stockNote;
    final issue = issueMessage;
    final note = quantityNote;
    final actionLabel = issueActionLabel;
    final action = onIssueAction;
    final period = periodLabel;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: issue == null ? AppColors.border : AppColors.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 72,
                height: 72,
                child: ProductImage(
                  imageUrl: imageUrl,
                  borderRadius: AppRadius.smAll,
                  semanticLabel: 'Foto $name',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (brandText.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(brandText, style: theme.textTheme.bodySmall),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      period == null ? unitPriceText : '$unitPriceText$period',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Subtotal: $subtotalText',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (isBusy)
            const AppLoading(label: 'Menyimpan perubahan…')
          else
            Row(
              children: <Widget>[
                Text('Jumlah', style: theme.textTheme.labelMedium),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  tooltip: 'Kurangi jumlah',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDecrease,
                  icon: const Icon(Icons.remove),
                ),
                Text('$quantity', style: theme.textTheme.titleMedium),
                IconButton(
                  tooltip: 'Tambah jumlah',
                  visualDensity: VisualDensity.compact,
                  onPressed: onIncrease,
                  icon: const Icon(Icons.add),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Hapus dari keranjang',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          if (stock != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(stock, style: theme.textTheme.bodySmall),
          ],
          if (note != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(note, style: theme.textTheme.bodySmall),
          ],
          if (issue != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            CatalogSectionNotice(
              message: issue,
              isError: true,
              onRetry: action,
              retryLabel: actionLabel ?? 'Perbaiki',
            ),
          ],
        ],
      ),
    );
  }
}
