import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// State data kosong yang dapat dipakai ulang.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Aksi opsional (misalnya tombol keluar atau muat ulang).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionWidget = action;
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 32, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (actionWidget != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              actionWidget,
            ],
          ],
        ),
      ),
    );
  }
}
