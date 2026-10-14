import 'package:firebase_auth/firebase_auth.dart';

/// Representasi pengguna yang sedang login untuk lapisan UI.
///
/// Widget dan provider tidak boleh memakai `User` dari Firebase langsung, agar
/// tipe Firebase tidak menyebar ke seluruh aplikasi. Role admin tidak ada di
/// sini dengan sengaja: role berasal dari custom claim pada ID token dan baru
/// dibaca pada fase dashboard admin.
class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;

  /// Nama yang layak ditampilkan; jatuh ke email lalu `uid`.
  String get preferredName {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty) {
      return mail;
    }
    return uid;
  }

  factory AuthUser.fromFirebaseUser(User user) => AuthUser(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoURL,
    isEmailVerified: user.emailVerified,
  );
}
