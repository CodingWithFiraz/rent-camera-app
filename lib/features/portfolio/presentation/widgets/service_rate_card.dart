import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../catalog/domain/price_display.dart';
import '../../domain/service_rate.dart';

/// Kartu satu kelompok layanan beserta rate card-nya.
///
/// Harga memakai [PriceDisplay] yang sama dengan katalog, sehingga label
/// periode (`/hari`, `/sesi`) hanya muncul bila dokumen benar-benar
/// menetapkannya (blueprint §6.6: jangan mengarang rate atau periode).
/// `deliverables` kosong ditampilkan sebagai keadaan "belum diisi" alih-alih
/// janji hasil kerja yang tidak pernah disepakati.
class ServiceRateCard extends StatelessWidget {
  const ServiceRateCard({super.key, required this.rate});

  final ServiceRate rate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = PriceDisplay.fromAmount(
      rate.startingPrice ?? 0,
      rate.priceUnit,
    );
    final rateLabel = rate.rateLabel.trim();
    final description = rate.description.trim();
    final deliverables = rate.deliverables;

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
          Text(rate.title, style: theme.textTheme.titleMedium),
          if (description.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(description, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('Hasil pekerjaan', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          if (deliverables.isEmpty)
            Text(
              'Rincian hasil pekerjaan belum diisi pemilik.',
              style: theme.textTheme.bodySmall,
            )
          else
            for (final deliverable in deliverables)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        deliverable,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          const Divider(),
          Text('Rate', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(_rateText(rateLabel, price), style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  /// Teks rate: label pemilik, harga, dan satuannya bila memang diisi.
  ///
  /// Urutan prioritasnya eksplisit: label dari dokumen (mis.
  /// `CONTOH RATE — BELUM FINAL`) tidak pernah dibuang, dan harga hanya
  /// ditambahkan ketika `startingPrice` benar-benar lebih dari nol.
  static String _rateText(String rateLabel, PriceDisplay price) {
    if (rateLabel.isNotEmpty && price.hasAmount) {
      return '$rateLabel ${price.text}';
    }
    if (rateLabel.isNotEmpty) {
      return rateLabel;
    }
    if (price.hasAmount) {
      return price.text;
    }
    return 'Rate belum ditetapkan pemilik.';
  }
}
