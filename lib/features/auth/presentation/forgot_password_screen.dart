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

/// Layar lupa kata sandi: mengirim email reset melalui Firebase Auth.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

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
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(email: _emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isSubmitting = authState.isSubmitting;
    final errorMessage = authState.errorMessage;
    final noticeMessage = authState.noticeMessage;

    return AuthFormLayout(
      showBackButton: true,
      title: 'Lupa kata sandi',
      subtitle:
          'Masukkan email akun Anda. Kami akan mengirim tautan untuk membuat '
          'kata sandi baru.',
      children: <Widget>[
        if (errorMessage != null) ...<Widget>[
          AppFormBanner.error(errorMessage),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (noticeMessage != null) ...<Widget>[
          AppFormBanner.notice(noticeMessage),
          const SizedBox(height: AppSpacing.lg),
        ],
        Form(
          key: _formKey,
          child: AppTextField(
            controller: _emailController,
            label: 'Email',
            enabled: !isSubmitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.email],
            validator: Validators.email,
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppPrimaryButton(
          label: 'Kirim tautan reset',
          onPressed: _submit,
          isLoading: isSubmitting,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          children: <Widget>[
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => context.go(AppRoutes.login),
              child: const Text('Kembali ke halaman masuk'),
            ),
          ],
        ),
      ],
    );
  }
}