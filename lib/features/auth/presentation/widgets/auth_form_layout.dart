import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_spacing.dart';

/// Kerangka bersama layar autentikasi (login, register, lupa kata sandi).
///
/// Menangani safe area, keyboard (viewInsets), lebar maksimum kolom form, dan
/// urutan judul → keterangan → isi form secara konsisten.
class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBackButton = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Menampilkan tombol kembali (untuk layar yang dibuka dari halaman login).
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: showBackButton ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxFormWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(AppConfig.appName, style: theme.textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
