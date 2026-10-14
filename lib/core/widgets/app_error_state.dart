import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// State error yang dapat dipakai ulang.
///
/// Menampilkan pesan yang sudah dipetakan (bukan exception mentah) dan tombol
/// coba lagi bila pemanggil menyediakan [onRetry].
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Coba lagi',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onRetryCallback = onRetry;
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 32, color: theme.colorScheme.error),
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
            if (onRetryCallback != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: onRetryCallback,
                child: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
