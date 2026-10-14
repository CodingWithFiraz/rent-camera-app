import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/app.dart';
import 'package:rent_camera_app/core/firebase/firebase_bootstrap.dart';
import 'package:rent_camera_app/core/firebase/firebase_providers.dart';
import 'package:rent_camera_app/features/auth/domain/auth_user.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_providers.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_session_notifier.dart';

/// Test alur aplikasi: bootstrap Firebase dan route guard autentikasi.
///
/// Test ini tidak membutuhkan kredensial: `FirebaseAuth` tidak pernah
/// diinstansiasi karena sesi disuntikkan lewat stream palsu.
void main() {
  testWidgets(
    'Firebase belum dikonfigurasi: layar setup ditampilkan, bukan form',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseBootstrapProvider.overrideWithValue(
              const FirebaseBootstrapStatus.notConfigured('no-app'),
            ),
          ],
          child: const RentCameraApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Firebase belum dikonfigurasi'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    },
  );

  testWidgets('belum login: pengguna diarahkan ke layar login', (
    WidgetTester tester,
  ) async {
    final controller = StreamController<AuthUser?>();
    addTearDown(controller.close);
    final session = AuthSessionNotifier(authStateChanges: controller.stream);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseBootstrapProvider.overrideWithValue(
            const FirebaseBootstrapStatus.configured(),
          ),
          authSessionNotifierProvider.overrideWithValue(session),
        ],
        child: const RentCameraApp(),
      ),
    );

    controller.add(null);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
    expect(find.text('Katalog belum dibangun'), findsNothing);
  });

  testWidgets('sudah login: pengguna diarahkan ke route katalog', (
    WidgetTester tester,
  ) async {
    final controller = StreamController<AuthUser?>();
    addTearDown(controller.close);
    final session = AuthSessionNotifier(authStateChanges: controller.stream);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseBootstrapProvider.overrideWithValue(
            const FirebaseBootstrapStatus.configured(),
          ),
          authSessionNotifierProvider.overrideWithValue(session),
        ],
        child: const RentCameraApp(),
      ),
    );

    controller.add(const AuthUser(uid: 'uid-1', displayName: 'Nama Uji'));
    await tester.pumpAndSettle();

    expect(find.text('Katalog belum dibangun'), findsOneWidget);
    expect(find.text('Nama Uji'), findsOneWidget);
  });
}
