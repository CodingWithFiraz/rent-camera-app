import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_form_banner.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_controller.dart';

/// Layar login: email + kata sandi, atau Google Sign-In.
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
    // Definisi Warna yang disamakan dengan Lupa Kata Sandi
    const Color limeGreenBox = Color(0xFFBCEE46);
    const Color charcoalText = Color(0xFF1E1E1E);
    const Color mutedGray = Color(0xFF4A4A4A);
    const Color customOrangeButton = Color.fromARGB(255, 255, 94, 0);

    final authState = ref.watch(authControllerProvider);
    final isSubmitting = authState.isSubmitting;
    final errorMessage = authState.errorMessage;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: limeGreenBox,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Rent Camera App',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: customOrangeButton,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masuk',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: charcoalText,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masuk untuk melihat katalog alat dan mengirim permintaan sewa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedGray,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (errorMessage != null) ...[
                    AppFormBanner.error(errorMessage),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(primary: customOrangeButton),
                            ),
                            child: AppTextField(
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
                          ),
                          const SizedBox(height: AppSpacing.fieldGap),
                          Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(primary: customOrangeButton),
                            ),
                            child: AppTextField(
                              controller: _passwordController,
                              label: 'Kata sandi',
                              obscureText: true,
                              enabled: !isSubmitting,
                              textInputAction: TextInputAction.done,
                              autofillHints: const <String>[AutofillHints.password],
                              validator: Validators.password,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Tombol Utama Masuk (Oranye dengan teks hitam)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customOrangeButton,
                      foregroundColor: charcoalText,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isSubmitting ? null : _submit,
                    child: isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: charcoalText,
                            ),
                          )
                        : const Text(
                            'Masuk',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color.fromARGB(255, 254, 253, 253)),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Tombol Masuk dengan Google
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: charcoalText,
                      side: const BorderSide(color: charcoalText),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isSubmitting ? null : _submitWithGoogle,
                    icon: const Icon(Icons.account_circle_outlined, size: 18, color: charcoalText),
                    label: const Text('Masuk dengan Google'),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Tautan Bawah
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => context.go(AppRoutes.forgotPassword),
                        child: const Text('Lupa kata sandi?', style: TextStyle(color: charcoalText, fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => context.go(AppRoutes.register),
                        child: const Text('Buat akun', style: TextStyle(color: charcoalText, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}