import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Bagian foto pada form produk: pratinjau Image.network dan input link URL gambar online.
class AdminProductImageField extends StatelessWidget {
  const AdminProductImageField({
    super.key,
    required this.controller,
    required this.isBusy,
    this.existingImageUrls = const <String>[],
  });

  final TextEditingController controller;
  final bool isBusy;
  final List<String> existingImageUrls;

  List<String> get _parsedUrls => controller.text
      .split(RegExp(r'[\n,]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  void _removeUrl(int index) {
    final urls = _parsedUrls;
    if (index >= 0 && index < urls.length) {
      urls.removeAt(index);
      controller.text = urls.join(', ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urls = _parsedUrls;
    final hasImages = urls.isNotEmpty;

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
            hasImages
                ? 'Foto pertama otomatis dijadikan sampul utama di katalog. '
                    'Gambar dimuat langsung dari link URL online.'
                : 'Belum ada foto. Masukkan URL/link gambar online di bawah '
                    'agar kartu produk menampilkan foto di katalog.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasImages)
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: <Widget>[
                for (var i = 0; i < urls.length; i++)
                  _Thumb(
                    caption: i == 0 ? 'Foto utama (Katalog)' : 'Foto ${i + 1}',
                    actionLabel: 'Hapus',
                    onAction: isBusy ? null : () => _removeUrl(i),
                    child: Image.network(
                      urls[i],
                      fit: BoxFit.cover,
                      semanticLabel: 'Pratinjau foto produk ${i + 1}',
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.canvas,
                        alignment: Alignment.center,
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.textSecondary,
                                size: 24,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'URL gagal dimuat',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: AppRadius.smAll,
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.photo_outlined,
                    color: AppColors.textSecondary,
                    size: 36,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Belum ada URL gambar diinput',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: controller,
            enabled: !isBusy,
            keyboardType: TextInputType.url,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'URL / Link Foto Produk',
              hintText: 'https://images.unsplash.com/...',
              helperText:
                  'Gunakan URL gambar online (misal Unsplash, Cloudinary). '
                  'Pisahkan dengan koma atau baris baru untuk menambah lebih dari 1 foto.',
              prefixIcon: const Icon(Icons.link, size: 20),
              suffixIcon: hasImages
                  ? IconButton(
                      tooltip: 'Hapus semua URL',
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: isBusy ? null : () => controller.clear(),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu thumbnail pratinjau foto beserta keterangan dan tombol hapus.
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          SizedBox(
            height: AppSpacing.minTapTarget,
            child: TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
