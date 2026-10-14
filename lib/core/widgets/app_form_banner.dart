import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum AppFormBannerTone { error, notice }

/// Pesan status pada form (error atau informasi non-fatal).
///
/// Dipakai agar pesan error tidak pernah berupa exception mentah dan tetap
/// terbaca dengan kontras yang memadai (bukan hanya lewat warna).
class AppFormBanner extends StatelessWidget {
  const AppFormBanner.error(this.message, {super.key})
    : tone = AppFormBannerTone.error;

  const AppFormBanner.notice(this.message, {super.key})
    : tone = AppFormBannerTone.notice;

  final AppFormBannerTone tone;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = tone == AppFormBannerTone.error;
    final background = isError
        ? theme.colorScheme.errorContainer
        : AppColors.canvas;
    final foreground = isError
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.smAll,
        border: Border.all(
          color: isError
              ? theme.colorScheme.error.withValues(alpha: 0.35)
              : AppColors.border,
        ),
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
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
