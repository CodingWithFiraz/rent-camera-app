import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_form_banner.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_controller.dart';

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
    // Definisi Warna yang disamakan dengan Login & Lupa Kata Sandi
    const Color limeGreenBox = Color(0xFFBCEE46);
    const Color charcoalText = Color(0xFF1E1E1E);
    const Color mutedGray = Color(0xFF4A4A4A);
    const Color customOrangeButton = Color.fromARGB(255, 255, 94, 0);

    // Definisi Warna yang disamakan dengan Login & Lupa Kata Sandi
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
                    color: Colors.black.withValues(alpha: 0.15),
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
                    'Buat akun',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: charcoalText,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Akun dipakai untuk menyimpan keranjang dan permintaan sewa Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: mutedGray, fontSize: 14),
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
                              colorScheme: const ColorScheme.light(
                                primary: customOrangeButton,
                              ),
                            ),
                            child: AppTextField(
                              controller: _nameController,
                              label: 'Nama',
                              enabled: !isSubmitting,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const <String>[AutofillHints.name],
                              validator: Validators.displayName,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.fieldGap),
                          Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: customOrangeButton,
                              ),
                            ),
                            child: AppTextField(
                              controller: _emailController,
                              label: 'Email',
                              enabled: !isSubmitting,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const <String>[
                                AutofillHints.email,
                              ],
                              validator: Validators.email,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.fieldGap),
                          Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: customOrangeButton,
                              ),
                            ),
                            child: AppTextField(
                              controller: _passwordController,
                              label: 'Kata sandi',
                              obscureText: true,
                              enabled: !isSubmitting,
                              textInputAction: TextInputAction.next,
                              autofillHints: const <String>[
                                AutofillHints.newPassword,
                              ],
                              validator: Validators.password,
                              helperText:
                                  'Minimal ${Validators.minPasswordLength} karakter.',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.fieldGap),
                          Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: customOrangeButton,
                              ),
                            ),
                            child: AppTextField(
                              controller: _confirmationController,
                              label: 'Ulangi kata sandi',
                              obscureText: true,
                              enabled: !isSubmitting,
                              textInputAction: TextInputAction.done,
                              validator: (value) =>
                                  Validators.passwordConfirmation(
                                    value,
                                    _passwordController.text,
                                  ),
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Tombol Utama Daftar (Oranye dengan teks gelap)
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
                            'Daftar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Tautan Bawah
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Sudah punya akun?',
                        style: TextStyle(color: mutedGray),
                      ),
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => context.go(AppRoutes.login),
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            color: charcoalText,
                            fontWeight: FontWeight.bold,
                          ),
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