import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/routing/auth_guard.dart';
import 'package:rent_camera_app/features/auth/domain/auth_user.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_session_notifier.dart';

/// Alamat email uji dibentuk dari potongan string supaya tidak ditulis sebagai
/// satu literal panjang.
String _emailAddress(String local, String domain) => '$local@$domain';

void main() {
  group('AuthSessionNotifier', () {
    test('mulai dari status unknown sebelum ada kabar dari stream', () {
      final controller = StreamController<AuthUser?>();
      addTearDown(controller.close);
      final notifier = AuthSessionNotifier(authStateChanges: controller.stream);
      addTearDown(notifier.dispose);

      expect(notifier.status, AuthSessionStatus.unknown);
      expect(notifier.user, isNull);
      expect(notifier.isSignedIn, isFalse);
    });

    test(
      'tanpa stream (Firebase belum dikonfigurasi) berlansung signedOut',
      () {
        final notifier = AuthSessionNotifier();
        addTearDown(notifier.dispose);

        expect(notifier.status, AuthSessionStatus.signedOut);
        expect(notifier.isSignedIn, isFalse);
      },
    );

    test('menandai signedIn lalu signedOut mengikuti stream sesi', () async {
      final controller = StreamController<AuthUser?>();
      addTearDown(controller.close);
      final notifier = AuthSessionNotifier(authStateChanges: controller.stream);
      addTearDown(notifier.dispose);

      int notifications = 0;
      notifier.addListener(() => notifications++);

      controller.add(const AuthUser(uid: 'uid-1', displayName: 'Nama Uji'));
      await pumpEventQueue();
      expect(notifier.status, AuthSessionStatus.signedIn);
      expect(notifier.isSignedIn, isTrue);
      expect(notifier.user?.uid, 'uid-1');
      expect(notifier.user?.preferredName, 'Nama Uji');

      controller.add(null);
      await pumpEventQueue();
      expect(notifier.status, AuthSessionStatus.signedOut);
      expect(notifier.user, isNull);
      expect(notifications, 2);
    });

    test('error pada stream diperlakukan sebagai signedOut', () async {
      final controller = StreamController<AuthUser?>();
      addTearDown(controller.close);
      final notifier = AuthSessionNotifier(authStateChanges: controller.stream);
      addTearDown(notifier.dispose);

      controller.addError(StateError('gagal membaca sesi'));
      await pumpEventQueue();

      expect(notifier.status, AuthSessionStatus.signedOut);
    });
  });

  group('AuthUser.preferredName', () {
    final String validEmail = _emailAddress('pengguna', 'contoh.test');

    test('memakai displayName, lalu email, lalu uid', () {
      expect(
        const AuthUser(uid: 'uid-1', displayName: 'Nama').preferredName,
        'Nama',
      );
      expect(
        AuthUser(uid: 'uid-1', email: validEmail).preferredName,
        validEmail,
      );
      expect(const AuthUser(uid: 'uid-1').preferredName, 'uid-1');
    });
  });
}
