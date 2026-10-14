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
    // Definisi Warna
    const Color charcoal = Color(0xFF262626);
    const Color shutterGray = Color(0xFF8C8C8C);
    const Color studioOrange = Color(0xFFFF6B00);
    const Color offWhite = Color(0xFFF5F5F5);

    final authState = ref.watch(authControllerProvider);
    final isSubmitting = authState.isSubmitting;
    final errorMessage = authState.errorMessage;

    // Scaffold dengan latar belakang paling luar berwarna Putih
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            // Kotak Hitam (Charcoal) di tengah dengan Efek Bayangan (Shadow)
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: charcoal,
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
                  // Judul & Subjudul Rata Tengah
                  const Text(
                    'Rent Camera App',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: studioOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masuk',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: offWhite,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masuk untuk melihat katalog alat dan mengirim permintaan sewa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: shutterGray, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  if (errorMessage != null) ...[
                    AppFormBanner.error(errorMessage),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Form Input
                  Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: studioOrange,
                              ),
                            ),
                            child: AppTextField(
                              controller: _identifierController,
                              label: 'Email',
                              enabled: !isSubmitting,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const <String>[
                                AutofillHints.email,
                              ],
                              validator: (value) => Validators.loginIdentifier(
                                value,
                                adminAlias: AppConfig.adminLoginAlias,
                                isAdminAliasConfigured:
                                    AppConfig.isAdminAliasConfigured,
                              ),
                              helperText: AppConfig.isAdminAliasConfigured
                                  ? 'Email akun, atau alias "${AppConfig.adminLoginAlias}".'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.fieldGap),
                          Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: studioOrange,
                              ),
                            ),
                            child: AppTextField(
                              controller: _passwordController,
                              label: 'Kata sandi',
                              obscureText: true,
                              enabled: !isSubmitting,
                              textInputAction: TextInputAction.done,
                              autofillHints: const <String>[
                                AutofillHints.password,
                              ],
                              validator: Validators.password,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Tombol Masuk Utama
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: studioOrange,
                      foregroundColor: offWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isSubmitting ? null : _submit,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: offWhite,
                            ),
                          )
                        : const Text(
                            'Masuk',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Tombol Google Sign In
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: offWhite,
                      side: const BorderSide(color: shutterGray),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isSubmitting ? null : _submitWithGoogle,
                    icon: const Icon(
                      Icons.account_circle_outlined,
                      size: 18,
                      color: studioOrange,
                    ),
                    label: const Text('Masuk dengan Google'),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Tautan Bawah (Lupa kata sandi & Buat akun)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => context.go(AppRoutes.forgotPassword),
                        child: const Text(
                          'Lupa kata sandi?',
                          style: TextStyle(color: studioOrange),
                        ),
                      ),
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => context.go(AppRoutes.register),
                        child: const Text(
                          'Buat akun',
                          style: TextStyle(color: studioOrange),
                        ),
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
