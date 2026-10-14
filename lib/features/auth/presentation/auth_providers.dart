import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../profile/data/user_profile_repository.dart';
import '../data/auth_repository.dart';
import 'auth_session_notifier.dart';

/// Akses dokumen `users/{uid}`.
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepository(ref.watch(firebaseFirestoreProvider)),
);

/// Akses Firebase Auth (email/password + Google Sign-In native).
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    profileRepository: ref.watch(userProfileRepositoryProvider),
  ),
);

/// Sesi login yang dipantau route guard `go_router`.
///
/// Berisi `null` stream bila Firebase belum dikonfigurasi, sehingga tidak ada
/// pembacaan `FirebaseAuth.instance` pada build yang belum siap.
final authSessionNotifierProvider = Provider<AuthSessionNotifier>((ref) {
  final isFirebaseConfigured = ref
      .watch(firebaseBootstrapProvider)
      .isConfigured;
  final notifier = AuthSessionNotifier(
    authStateChanges: isFirebaseConfigured
        ? ref.watch(authRepositoryProvider).authStateChanges()
        : null,
  );
  ref.onDispose(notifier.dispose);
  return notifier;
});
