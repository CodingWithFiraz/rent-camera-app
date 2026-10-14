import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/product_image.dart';
import '../../data/admin_product_image_picker.dart';

/// Bagian foto pada form produk: pratinjau, progress unggah, dan penandaan foto
/// lama yang akan dibuang.
///
/// Pratinjau memakai byte berkas yang dipilih (bukan path) supaya juga tampil
/// pada web. Foto baru hanya menjadi pratinjau sampai produk disimpan: bila
/// unggahan gagal, daftar foto lama tidak berubah (blueprint §10).
class AdminProductImageField extends StatelessWidget {
  const AdminProductImageField({
    super.key,
    required this.existingImageUrls,
    required this.removedImageUrls,
    required this.pendingImages,
    required this.isBusy,
    required this.isUploading,
    required this.uploadedImageCount,
    required this.uploadTotal,
    required this.uploadProgress,
    required this.onPick,
    required this.onRemovePending,
    required this.onToggleExisting,
  });

  /// URL foto yang sudah tersimpan pada dokumen produk.
  final List<String> existingImageUrls;

  /// URL foto lama yang ditandai akan dibuang saat penyimpanan berhasil.
  final Set<String> removedImageUrls;

  /// Foto baru yang sudah divalidasi tetapi belum diunggah.
  final List<PickedProductImage> pendingImages;

  final bool isBusy;
  final bool isUploading;
  final int uploadedImageCount;
  final int uploadTotal;
  final double uploadProgress;

  final VoidCallback onPick;
  final void Function(int index) onRemovePending;
  final void Function(String imageUrl) onToggleExisting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAnyImage =
        existingImageUrls.isNotEmpty || pendingImages.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Foto produk', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            hasAnyImage
                ? 'Foto pertama dipakai sebagai foto utama di katalog. Foto baru '
                      'diunggah saat produk disimpan; bila unggahan gagal, daftar '
                      'foto lama tidak berubah.'
                : 'Belum ada foto. Produk tetap dapat disimpan, tetapi kartu di '
                      'katalog menampilkan bidang "Foto belum diisi".',
            style: theme.textTheme.bodySmall,
          ),
          if (hasAnyImage) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: <Widget>[
                for (final url in existingImageUrls)
                  _Thumb(
                    caption: removedImageUrls.contains(url)
                        ? 'Akan dihapus saat disimpan'
                        : 'Foto tersimpan',
                    actionLabel: removedImageUrls.contains(url)
                        ? 'Batalkan'
                        : 'Buang',
                    onAction: isBusy ? null : () => onToggleExisting(url),
                    child: Opacity(
                      opacity: removedImageUrls.contains(url) ? 0.4 : 1,
                      child: ProductImage(
                        imageUrl: url,
                        semanticLabel: 'Foto produk tersimpan',
                      ),
                    ),
                  ),
                for (var index = 0; index < pendingImages.length; index++)
                  _Thumb(
                    caption: 'Foto baru (belum diunggah)',
                    actionLabel: 'Batalkan',
                    onAction: isBusy ? null : () => onRemovePending(index),
                    child: Image.memory(
                      pendingImages[index].bytes,
                      fit: BoxFit.cover,
                      semanticLabel: 'Pratinjau foto baru',
                    ),
                  ),
              ],
            ),
          ],
          if (isUploading) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(value: uploadProgress),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Mengunggah foto ${uploadedImageCount + 1} dari $uploadTotal — '
              '${(uploadProgress * 100).round()}%',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onPick,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(pendingImages.isEmpty ? 'Pilih foto' : 'Tambah foto'),
          ),
        ],
      ),
    );
  }
}

/// Satu pratinjau foto beserta keterangan dan aksinya.
class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.caption,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  final String caption;
  final String actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: SizedBox(width: 108, height: 108, child: child),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          SizedBox(
            height: AppSpacing.minTapTarget,
            child: TextButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}
