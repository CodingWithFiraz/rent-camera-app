import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/routing/auth_guard.dart';
import '../domain/auth_user.dart';

/// Melacak sesi Firebase Auth untuk route guard.
///
/// Tipe Firebase tidak dipakai di sini: repository sudah memetakan `User`
/// menjadi [AuthUser], sehingga kelas ini dapat diuji dengan stream palsu.
class AuthSessionNotifier extends ChangeNotifier {
  AuthSessionNotifier({Stream<AuthUser?>? authStateChanges}) {
    if (authStateChanges == null) {
      // Firebase belum dikonfigurasi: tidak ada sesi untuk diamati.
      _status = AuthSessionStatus.signedOut;
      return;
    }
    _subscription = authStateChanges.listen(
      _onAuthStateChanged,
      onError: (Object _) => _setSignedOut(),
    );
  }

  AuthSessionStatus _status = AuthSessionStatus.unknown;
  AuthUser? _user;
  StreamSubscription<AuthUser?>? _subscription;

  AuthSessionStatus get status => _status;
  AuthUser? get user => _user;
  bool get isSignedIn => _status == AuthSessionStatus.signedIn;

  void _onAuthStateChanged(AuthUser? user) {
    _user = user;
    _status = user == null
        ? AuthSessionStatus.signedOut
        : AuthSessionStatus.signedIn;
    notifyListeners();
  }

  void _setSignedOut() {
    _user = null;
    _status = AuthSessionStatus.signedOut;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
