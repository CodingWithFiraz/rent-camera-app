import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/firebase/firebase_bootstrap.dart';
import 'package:rent_camera_app/core/firebase/firebase_providers.dart';
import 'package:rent_camera_app/features/admin/data/admin_access_repository.dart';
import 'package:rent_camera_app/features/admin/domain/admin_access.dart';
import 'package:rent_camera_app/features/admin/presentation/admin_providers.dart';
import 'package:rent_camera_app/features/auth/domain/auth_user.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_providers.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_session_notifier.dart';

/// Test penyusunan `adminAccessNotifierProvider` di luar Firebase.
///
/// `adminAccessNotifierProvider` dibangun pada setiap perubahan rute, sehingga
/// membangunnya **tidak boleh** menyentuh `FirebaseAuth`. Test ini meniru
/// keadaan yang juga dipakai test routing: bootstrap Firebase dioverride
/// `configured`, sementara Firebase Auth sendiri belum benar-benar siap.
/// Keadaan itu harus berakhir sebagai akses ditolak, bukan exception.
void main() {
  /// Menunggu rantai pembacaan claim yang berjalan lewat microtask selesai.
  Future<void> settle() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Session notifier beserta stream palsu yang dapat didorong test.
  ({AuthSessionNotifier session, StreamController<AuthUser?> controller})
  createSession() {
    final controller = StreamController<AuthUser?>();
    final session = AuthSessionNotifier(authStateChanges: controller.stream);
    addTearDown(controller.close);
    addTearDown(session.dispose);
    return (session: session, controller: controller);
  }

  test(
    'Firebase belum dikonfigurasi: provider dibangun dan akses ditolak',
    () async {
      final container = ProviderContainer(
        overrides: <Override>[
          firebaseBootstrapProvider.overrideWithValue(
            const FirebaseBootstrapStatus.notConfigured('no-app'),
          ),
          authSessionNotifierProvider.overrideWithValue(AuthSessionNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(adminAccessNotifierProvider);
      await settle();

      expect(notifier.status, AdminAccessStatus.denied);
      expect(notifier.isGranted, isFalse);
    },
  );

  test(
    'bootstrap siap tetapi Firebase Auth belum tersedia: akses ditolak',
    () async {
      final session = createSession();
      final container = ProviderContainer(
        overrides: <Override>[
          firebaseBootstrapProvider.overrideWithValue(
            const FirebaseBootstrapStatus.configured(),
          ),
          authSessionNotifierProvider.overrideWithValue(session.session),
        ],
      );
      addTearDown(container.dispose);

      // Penyusunan provider ini pernah gagal karena `firebaseAuthProvider`
      // dibaca terlalu dini; pembacaan claim kini malas, jadi tidak melempar.
      final notifier = container.read(adminAccessNotifierProvider);
      expect(notifier.status, AdminAccessStatus.denied);

      session.controller.add(const AuthUser(uid: 'uid-1'));
      await settle();

      // Pembacaan ID token gagal (Firebase Auth belum siap): bukan admin.
      expect(notifier.status, AdminAccessStatus.denied);
    },
  );

  test(
    'claim admin true dari repository menghasilkan status granted',
    () async {
      final session = createSession();
      final container = ProviderContainer(
        overrides: <Override>[
          firebaseBootstrapProvider.overrideWithValue(
            const FirebaseBootstrapStatus.configured(),
          ),
          authSessionNotifierProvider.overrideWithValue(session.session),
          adminAccessRepositoryProvider.overrideWithValue(
            _FakeAdminAccessRepository(<String, Object?>{'admin': true}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(adminAccessNotifierProvider);
      session.controller.add(const AuthUser(uid: 'uid-admin'));
      await settle();

      expect(notifier.status, AdminAccessStatus.granted);
      expect(notifier.isGranted, isTrue);
    },
  );

  test('claim admin bertipe bukan bool tetap ditolak', () async {
    final session = createSession();
    final container = ProviderContainer(
      overrides: <Override>[
        firebaseBootstrapProvider.overrideWithValue(
          const FirebaseBootstrapStatus.configured(),
        ),
        authSessionNotifierProvider.overrideWithValue(session.session),
        adminAccessRepositoryProvider.overrideWithValue(
          _FakeAdminAccessRepository(<String, Object?>{'admin': 'true'}),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(adminAccessNotifierProvider);
    session.controller.add(const AuthUser(uid: 'uid-1'));
    await settle();

    expect(notifier.status, AdminAccessStatus.denied);
  });
}

/// Pembaca claim palsu: tidak menyentuh Firebase sama sekali.
class _FakeAdminAccessRepository implements AdminAccessRepository {
  _FakeAdminAccessRepository(this.claims);

  final Map<String, Object?> claims;

  @override
  Future<Map<String, dynamic>?> readClaims() async =>
      Map<String, dynamic>.from(claims);
}
