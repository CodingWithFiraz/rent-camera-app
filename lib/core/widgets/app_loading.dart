import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Indikator proses terpusat dengan label opsional.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.label});

  /// Keterangan singkat, misalnya "Memuat sesi…".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final labelText = label;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          if (labelText != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Text(
              labelText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
