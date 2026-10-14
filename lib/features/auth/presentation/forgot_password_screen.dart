import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_form_banner.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_controller.dart';

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
    // Definisi Warna
    const Color limeGreenBox = Color(0xFFBCEE46);
    const Color charcoalText = Color(0xFF1E1E1E);
    const Color mutedGray = Color(0xFF4A4A4A);
    const Color customOrangeButton = Color.fromARGB(255, 255, 94, 0);

    final authState = ref.watch(authControllerProvider);
    final isSubmitting = authState.isSubmitting;
    final errorMessage = authState.errorMessage;
    final noticeMessage = authState.noticeMessage;

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
                      color: Color.fromARGB(255, 255, 115, 0),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lupa kata sandi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: charcoalText,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masukkan email akun Anda. Kami akan mengirim tautan untuk membuat kata sandi baru.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedGray,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

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
                    child: Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: const ColorScheme.light(primary: customOrangeButton),
                      ),
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
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Tombol dengan Background Custom Orange dan Teks Hitam
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
                              color: const Color.fromARGB(255, 234, 15, 15),
                            ),
                          )
                        : const Text(
                            'Kirim tautan reset',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => context.go(AppRoutes.login),
                        child: const Text(
                          'Kembali ke halaman masuk',
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