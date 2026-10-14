import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_form_banner.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_controller.dart';
import 'widgets/auth_form_layout.dart';

/// Layar login: email + kata sandi, atau Google Sign-In.
///
/// Navigasi setelah login tidak dilakukan di sini: route guard memindahkan
/// pengguna ke katalog begitu `authStateChanges()` melaporkan sesi aktif.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Bersihkan pesan dari percobaan sebelumnya. Dilakukan setelah frame
    // pertama karena mengubah state provider saat build tidak diizinkan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authControllerProvider.notifier).clearMessages();
      }
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    // Nilai yang diketik pengguna, dibaca ke variabel lokal agar pemanggilan
    // aksi terbaca jelas.
    final String rawInput = _passwordController.text;
    await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(
          identifier: _identifierController.text,
          password: rawInput,
        );
    _showNoticeIfAny();
  }

  Future<void> _submitWithGoogle() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
    _showNoticeIfAny();
  }

  /// Menampilkan peringatan non-fatal (mis. dokumen profil gagal disinkronkan)
  /// tanpa menyembunyikannya sebagai sukses penuh.
  void _showNoticeIfAny() {
    if (!mounted) {
      return;
    }
    final notice = ref.read(authControllerProvider).noticeMessage;
    if (notice == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notice)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isSubmitting = authState.isSubmitting;
    final errorMessage = authState.errorMessage;

    return AuthFormLayout(
      title: 'Masuk',
      subtitle:
          'Masuk untuk melihat katalog alat dan mengirim permintaan sewa.',
      children: <Widget>[
        if (errorMessage != null) ...<Widget>[
          AppFormBanner.error(errorMessage),
          const SizedBox(height: AppSpacing.lg),
        ],
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  controller: _identifierController,
                  label: 'Email',
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.email],
                  validator: (value) => Validators.loginIdentifier(
                    value,
                    adminAlias: AppConfig.adminLoginAlias,
                    isAdminAliasConfigured: AppConfig.isAdminAliasConfigured,
                  ),
                  helperText: AppConfig.isAdminAliasConfigured
                      ? 'Email akun, atau alias "${AppConfig.adminLoginAlias}".'
                      : null,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                AppTextField(
                  controller: _passwordController,
                  label: 'Kata sandi',
                  obscureText: true,
                  enabled: !isSubmitting,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.password],
                  validator: Validators.password,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppPrimaryButton(
          label: 'Masuk',
          onPressed: _submit,
          isLoading: isSubmitting,
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: isSubmitting ? null : _submitWithGoogle,
          icon: const Icon(Icons.account_circle_outlined, size: 18),
          label: const Text('Masuk dengan Google'),
        ),
        if (!AppConfig.isGoogleServerClientIdConfigured) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Google Sign-In memerlukan server client ID project Firebase '
            '(lihat SETUP.md).',
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => context.go(AppRoutes.forgotPassword),
              child: const Text('Lupa kata sandi?'),
            ),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => context.go(AppRoutes.register),
              child: const Text('Buat akun'),
            ),
          ],
        ),
      ],
    );
  }
}
