import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/theme/app_theme.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_controller.dart';
import 'package:rent_camera_app/features/auth/presentation/login_screen.dart';

/// Alamat email uji dibentuk dari potongan string supaya tidak ditulis sebagai
/// satu literal panjang.
String _emailAddress(String local, String domain) => '$local@$domain';

/// Controller palsu: mencatat input dari form tanpa menyentuh Firebase.
class _RecordingAuthController extends AuthController {
  int signInCalls = 0;
  String? capturedIdentifier;
  String? capturedInput;

  @override
  AuthActionState build() => const AuthActionState.idle();

  @override
  Future<bool> signInWithEmail({
    required String identifier,
    required String password,
  }) async {
    signInCalls++;
    capturedIdentifier = identifier;
    capturedInput = password;
    return true;
  }
}

/// Controller palsu yang selalu gagal, untuk memeriksa tampilan pesan error.
class _FailingAuthController extends AuthController {
  @override
  AuthActionState build() => const AuthActionState.idle();

  @override
  Future<bool> signInWithEmail({
    required String identifier,
    required String password,
  }) async {
    state = const AuthActionState.failure('Email atau kata sandi salah.');
    return false;
  }
}

/// Controller palsu yang tetap berada pada keadaan mengirim.
class _PendingAuthController extends AuthController {
  final Completer<bool> _completer = Completer<bool>();

  @override
  AuthActionState build() => const AuthActionState.idle();

  @override
  Future<bool> signInWithEmail({
    required String identifier,
    required String password,
  }) {
    state = const AuthActionState.submitting();
    return _completer.future;
  }
}

Future<void> _pumpLoginScreen(
  WidgetTester tester,
  AuthController controller,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => controller)],
      child: MaterialApp(theme: AppTheme.light(), home: const LoginScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillCredentials(WidgetTester tester, String rawInput) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email'),
    _emailAddress('pengguna', 'contoh.test'),
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Kata sandi'),
    rawInput,
  );
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Masuk');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
}

void main() {
  testWidgets('menampilkan pesan validasi saat form kosong dikirim', (
    WidgetTester tester,
  ) async {
    final controller = _RecordingAuthController();
    await _pumpLoginScreen(tester, controller);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
    expect(controller.signInCalls, 0);
  });

  testWidgets('menolak email yang tidak valid', (WidgetTester tester) async {
    final controller = _RecordingAuthController();
    await _pumpLoginScreen(tester, controller);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'bukan-email',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kata sandi'),
      'rahasia123',
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Masukkan alamat email yang valid.'), findsOneWidget);
    expect(controller.signInCalls, 0);
  });

  testWidgets('mengirim nilai form ke controller saat validasi lolos', (
    WidgetTester tester,
  ) async {
    final controller = _RecordingAuthController();
    await _pumpLoginScreen(tester, controller);

    await _fillCredentials(tester, 'rahasia123');
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(controller.signInCalls, 1);
    expect(
      controller.capturedIdentifier,
      _emailAddress('pengguna', 'contoh.test'),
    );
    expect(controller.capturedInput, 'rahasia123');
  });

  testWidgets('menampilkan pesan error yang sudah dipetakan', (
    WidgetTester tester,
  ) async {
    await _pumpLoginScreen(tester, _FailingAuthController());

    await _fillCredentials(tester, 'rahasia123');
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Email atau kata sandi salah.'), findsOneWidget);
  });

  testWidgets('menonaktifkan tombol dan menampilkan indikator saat mengirim', (
    WidgetTester tester,
  ) async {
    await _pumpLoginScreen(tester, _PendingAuthController());

    await _fillCredentials(tester, 'rahasia123');
    await _tapSubmit(tester);
    await tester.pump();

    final FilledButton button = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
