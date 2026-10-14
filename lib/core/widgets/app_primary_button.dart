import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Tombol aksi utama dengan state loading dan disabled.
///
/// Saat [isLoading] bernilai true tombol dinonaktifkan dan menampilkan indikator
/// proses, sehingga pengguna tidak dapat mengirim form dua kali.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = icon;
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (iconData != null) ...<Widget>[
                  Icon(iconData, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(child: Text(label)),
              ],
            ),
    );
  }
}
