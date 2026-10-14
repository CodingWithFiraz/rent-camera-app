import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_form_banner.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_controller.dart';
import 'widgets/auth_form_layout.dart';

/// Layar registrasi akun email/password.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authControllerProvider.notifier).clearMessages();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    // Nilai yang diketik pengguna pada field kata sandi, dibaca ke variabel
    // lokal supaya pemanggilan aksi terbaca jelas.
    final String rawInput = _passwordController.text;
    await ref
        .read(authControllerProvider.notifier)
        .registerWithEmail(
          name: _nameController.text,
          email: _emailController.text,
          password: rawInput,
        );
    if (!mounted) {
      return;
    }
    final notice = ref.read(authControllerProvider).noticeMessage;
    if (notice != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(notice)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isSubmitting = authState.isSubmitting;
    final errorMessage = authState.errorMessage;

    return AuthFormLayout(
      showBackButton: true,
      title: 'Buat akun',
      subtitle:
          'Akun dipakai untuk menyimpan keranjang dan permintaan sewa Anda.',
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
                  controller: _nameController,
                  label: 'Nama',
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.name],
                  validator: Validators.displayName,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                AppTextField(
                  controller: _passwordController,
                  label: 'Kata sandi',
                  obscureText: true,
                  enabled: !isSubmitting,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  validator: Validators.password,
                  helperText:
                      'Minimal ${Validators.minPasswordLength} karakter.',
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                AppTextField(
                  controller: _confirmationController,
                  label: 'Ulangi kata sandi',
                  obscureText: true,
                  enabled: !isSubmitting,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.passwordConfirmation(
                    value,
                    _passwordController.text,
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppPrimaryButton(
          label: 'Daftar',
          onPressed: _submit,
          isLoading: isSubmitting,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              'Sudah punya akun?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => context.go(AppRoutes.login),
              child: const Text('Masuk'),
            ),
          ],
        ),
      ],
    );
  }
}
