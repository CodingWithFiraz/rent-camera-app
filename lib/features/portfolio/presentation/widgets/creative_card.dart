import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/product_image.dart';
import '../../domain/creative.dart';

/// Kartu satu kreator: foto, nama, peran, spesialisasi, dan tautan portofolio.
///
/// Tombol `Lihat Portofolio` hanya aktif bila dokumen memuat URL yang valid;
/// bila belum, tombol dinonaktifkan dan alasannya ditulis apa adanya sehingga
/// tidak ada tombol yang tampak bekerja tetapi diam (blueprint §4 dan §6.7).
class CreativeCard extends StatelessWidget {
  const CreativeCard({
    super.key,
    required this.creative,
    this.onOpenPortfolio,
    this.isOpening = false,
  });

  final Creative creative;

  /// `null` berarti tautan portofolio belum valid/belum diisi.
  final VoidCallback? onOpenPortfolio;

  /// `true` selama tautan sedang diserahkan ke aplikasi lain.
  final bool isOpening;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleTitle = creative.roleTitle.trim();
    final specialties = creative.specialties
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
    final canOpen = onOpenPortfolio != null;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipOval(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: ProductImage(
                    imageUrl: creative.photoUrl,
                    semanticLabel: 'Foto ${creative.name}',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(creative.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      roleTitle.isEmpty ? 'Peran belum diisi' : roleTitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Spesialisasi', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          if (specialties.isEmpty)
            Text(
              'Spesialisasi belum diisi pemilik.',
              style: theme.textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (final specialty in specialties)
                  Chip(
                    label: Text(specialty),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: isOpening ? null : onOpenPortfolio,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(isOpening ? 'Membuka tautan…' : 'Lihat Portofolio'),
          ),
          if (!canOpen) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tautan portofolio belum dikonfigurasi pemilik.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
