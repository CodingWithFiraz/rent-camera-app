import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Pemberitahuan ringkas untuk satu bagian halaman katalog.
///
/// Dipakai saat hanya sebagian data gagal dimuat atau belum dikonfigurasi
/// (banner, kategori) sehingga bagian lain — pencarian, filter, dan daftar
/// produk — tetap dapat dipakai. Bukan state error seluruh halaman: pesan di
/// sini selalu berasal dari hasil pemetaan error atau penjelasan konfigurasi,
/// tanpa detail internal.
class CatalogSectionNotice extends StatelessWidget {
  const CatalogSectionNotice({
    super.key,
    required this.message,
    this.isError = false,
    this.onRetry,
    this.retryLabel = 'Coba lagi',
  });

  final String message;

  /// Menandai pesan sebagai kegagalan pemuatan (ikon/warna error).
  final bool isError;

  /// Aksi pemulihan; `null` berarti pesan hanya bersifat informasi.
  final VoidCallback? onRetry;

  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final retry = onRetry;
    final foreground = isError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorContainer : AppColors.surface,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: isError ? AppColors.error : AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            size: 18,
            color: foreground,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
          if (retry != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: retry,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: Text(retryLabel),
            ),
          ],
        ],
      ),
    );
  }
}
