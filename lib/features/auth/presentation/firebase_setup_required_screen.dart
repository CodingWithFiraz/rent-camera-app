import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_form_banner.dart';

/// Layar yang muncul bila konfigurasi Firebase belum tersedia.
///
/// Ditampilkan sebagai ganti form login supaya aplikasi tidak pernah
/// mengklaim autentikasi berjalan padahal `Firebase.initializeApp()` gagal.
class FirebaseSetupRequiredScreen extends ConsumerWidget {
  const FirebaseSetupRequiredScreen({super.key});

  static const List<String> _steps = <String>[
    'Jalankan `flutterfire configure` di root project agar '
        '`lib/firebase_options.dart` (dipakai web/desktop) serta berkas native '
        '`google-services.json`/`GoogleService-Info.plist` ter-generate atau '
        'terbarui untuk platform yang dipakai.',
    'Aktifkan provider Email/Password dan Google di Firebase Authentication.',
    'Daftarkan SHA-1/SHA-256 build Android agar Google Sign-In dapat '
        'mengembalikan ID token.',
    'Untuk web, pastikan domain yang dipakai sudah terdaftar di Authentication '
        '→ Settings → Authorized domains (`localhost` sudah diizinkan secara '
        'default).',
    'Isi `--dart-define` untuk nilai milik project (mis. ADMIN_EMAIL, '
        'GOOGLE_SERVER_CLIENT_ID) bila diperlukan.',
    'Jalankan ulang aplikasi (hot restart) setelah konfigurasi selesai.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = ref.watch(firebaseBootstrapProvider);
    final diagnostic = status.diagnosticCode;
    final configurationSource = status.configurationSource;

    return Scaffold(
      appBar: AppBar(title: Text(AppConfig.appName)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screen,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxFormWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Firebase belum dikonfigurasi',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Konfigurasi Firebase belum dapat dipakai pada platform '
                    'ini, sehingga login email/password dan Google Sign-In '
                    'belum dapat dijalankan. Aplikasi memakai opsi dari '
                    '`lib/firebase_options.dart` (hasil `flutterfire '
                    'configure`) untuk web/desktop, dan berkas konfigurasi '
                    'native untuk Android/iOS.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (int index = 0; index < _steps.length; index++) ...[
                    _SetupStep(number: index + 1, text: _steps[index]),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Langkah lengkap ada di SETUP.md.',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (configurationSource != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Sumber konfigurasi untuk platform ini: '
                      '$configurationSource.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (diagnostic != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.lg),
                    AppFormBanner.notice('Diagnostik: $diagnostic'),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$number.', style: theme.textTheme.labelLarge),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
