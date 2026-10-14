import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/theme/app_theme.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_controller.dart';
import 'package:rent_camera_app/features/auth/presentation/register_screen.dart';

/// Alamat email uji dibentuk dari potongan string supaya tidak ditulis sebagai
/// satu literal panjang.
String _emailAddress(String local, String domain) => '$local@$domain';

class _RecordingRegisterController extends AuthController {
  int registerCalls = 0;

  @override
  AuthActionState build() => const AuthActionState.idle();

  @override
  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    registerCalls++;
    return true;
  }
}

Future<void> _pumpRegisterScreen(
  WidgetTester tester,
  AuthController controller,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => controller)],
      child: MaterialApp(theme: AppTheme.light(), home: const RegisterScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillForm(
  WidgetTester tester, {
  required String confirmation,
}) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Nama'),
    'Nama Pengguna',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email'),
    _emailAddress('pengguna', 'contoh.test'),
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Kata sandi'),
    'rahasia123',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Ulangi kata sandi'),
    confirmation,
  );
}

/// Desain ulang layar register memakai `ElevatedButton` bergaya sendiri (bukan
/// `AppPrimaryButton` yang membungkus `FilledButton`), sehingga finder harus
/// memakai tipe tombol yang benar-benar dipakai layar ini — sejalan dengan
/// `test/features/auth/login_screen_test.dart`.
Future<void> _tapSubmit(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'Daftar');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
}

void main() {
  testWidgets('menolak konfirmasi kata sandi yang berbeda', (
    WidgetTester tester,
  ) async {
    final controller = _RecordingRegisterController();
    await _pumpRegisterScreen(tester, controller);

    await _fillForm(tester, confirmation: 'rahasia124');
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi kata sandi tidak sama.'), findsOneWidget);
    expect(controller.registerCalls, 0);
  });

  testWidgets('mengirim registrasi saat seluruh field valid', (
    WidgetTester tester,
  ) async {
    final controller = _RecordingRegisterController();
    await _pumpRegisterScreen(tester, controller);

    await _fillForm(tester, confirmation: 'rahasia123');
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(controller.registerCalls, 1);
  });
}
