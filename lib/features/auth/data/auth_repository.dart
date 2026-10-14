import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/auth_error_mapper.dart';
import '../../profile/data/user_profile_repository.dart';
import '../domain/auth_user.dart';

/// Hasil satu operasi autentikasi.
///
/// [profileSyncWarning] diisi bila login/registrasi berhasil tetapi dokumen
/// `users/{uid}` gagal disinkronkan (misalnya Firestore Security Rules belum
/// dideploy). Kondisi ini tidak boleh disembunyikan sebagai sukses penuh.
class AuthResult {
  const AuthResult({required this.user, this.profileSyncWarning});

  final AuthUser user;
  final String? profileSyncWarning;
}

/// Mengubah identitas yang diketik pada form login menjadi email untuk
/// Firebase Auth.
///
/// Alias admin (mis. `admin`) hanya dipetakan bila email admin benar-benar
/// dikonfigurasi pemilik project lewat `--dart-define=ADMIN_EMAIL=...`. Alias
/// bukan bypass autentikasi: password tetap divalidasi Firebase Auth.
String resolveSignInEmail(
  String identifier, {
  String adminAlias = '',
  String adminEmail = '',
}) {
  final text = identifier.trim();
  if (text.isEmpty) {
    throw const AppException('Email wajib diisi.');
  }
  if (text.contains('@')) {
    return text.toLowerCase();
  }
  final configuredEmail = adminEmail.trim();
  final configuredAlias = adminAlias.trim();
  if (configuredEmail.isNotEmpty &&
      configuredAlias.isNotEmpty &&
      text.toLowerCase() == configuredAlias.toLowerCase()) {
    return configuredEmail.toLowerCase();
  }
  throw const AppException('Masukkan alamat email yang valid.');
}

/// Kontrak akses autentikasi.
///
/// UI hanya bergantung pada interface ini sehingga dapat diuji dengan
/// implementasi palsu tanpa kredensial Firebase.
abstract interface class AuthRepository {
  /// Stream sesi: `null` berarti belum login.
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  Future<AuthResult> signInWithEmail({
    required String identifier,
    required String password,
  });

  Future<AuthResult> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Login Google native: credential dari Google dikirim ke Firebase Auth.
  Future<AuthResult> signInWithGoogle();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();
}

/// Implementasi Firebase Auth (email/password + Google Sign-In).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth auth,
    required UserProfileRepository profileRepository,
    GoogleSignIn? googleSignIn,
  }) : this._(auth, profileRepository, googleSignIn ?? GoogleSignIn.instance);

  FirebaseAuthRepository._(
    this._auth,
    this._profileRepository,
    this._googleSignIn,
  );

  final FirebaseAuth _auth;
  final UserProfileRepository _profileRepository;
  final GoogleSignIn _googleSignIn;

  bool _isGoogleSignInInitialized = false;

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(
    (user) => user == null ? null : AuthUser.fromFirebaseUser(user),
  );

  @override
  AuthUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : AuthUser.fromFirebaseUser(user);
  }

  @override
  Future<AuthResult> signInWithEmail({
    required String identifier,
    required String password,
  }) async {
    final email = resolveSignInEmail(
      identifier,
      adminAlias: AppConfig.adminLoginAlias,
      adminEmail: AppConfig.adminEmail,
    );
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _completeSignIn(credential);
  }

  @override
  Future<AuthResult> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const AppException('Akun tidak dapat dibuat. Coba lagi.');
    }

    // Nama pada profil Firebase Auth sifatnya best-effort: kegagalannya tidak
    // membatalkan registrasi karena nama tetap disimpan ke Firestore.
    try {
      await user.updateDisplayName(trimmedName);
    } catch (_) {
      // Diabaikan dengan sengaja; lihat komentar di atas.
    }

    final warning = await _syncProfile(user, fallbackDisplayName: trimmedName);
    return AuthResult(
      user: AuthUser.fromFirebaseUser(user),
      profileSyncWarning: warning,
    );
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    if (!_googleSignIn.supportsAuthenticate()) {
      throw const AppException(
        'Login Google tidak didukung pada platform ini.',
      );
    }
    await _ensureGoogleSignInInitialized();

    final GoogleSignInAccount account = await _googleSignIn.authenticate();
    final String? dataFromGoogle = _googleAuthData(account);
    if (dataFromGoogle == null || dataFromGoogle.isEmpty) {
      throw const AppException(
        'Google tidak mengembalikan ID token. Periksa konfigurasi Google '
        'Sign-In (server client ID) lalu coba lagi.',
      );
    }

    final OAuthCredential credential = _googleCredential(dataFromGoogle);
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw const AppException(
        'Sesi login Google tidak dapat dibuat. Coba lagi.',
      );
    }

    final warning = await _syncProfile(user);
    return AuthResult(
      user: AuthUser.fromFirebaseUser(user),
      profileSyncWarning: warning,
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  @override
  Future<void> signOut() async {
    // Keluar dari Google lebih dulu agar akun tidak otomatis terpilih lagi;
    // kegagalannya tidak boleh menghalangi sign out Firebase.
    try {
      if (_isGoogleSignInInitialized && _googleSignIn.supportsAuthenticate()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // Diabaikan dengan sengaja; lihat komentar di atas.
    }
    await _auth.signOut();
  }

  Future<AuthResult> _completeSignIn(UserCredential credential) async {
    final user = credential.user;
    if (user == null) {
      throw const AppException('Sesi login tidak dapat dibuat. Coba lagi.');
    }
    final warning = await _syncProfile(user);
    return AuthResult(
      user: AuthUser.fromFirebaseUser(user),
      profileSyncWarning: warning,
    );
  }

  /// Menyinkronkan dokumen `users/{uid}` dan mengembalikan pesan peringatan
  /// bila gagal, tanpa menampilkan exception mentah ke pengguna.
  Future<String?> _syncProfile(User user, {String? fallbackDisplayName}) async {
    try {
      await _profileRepository.ensureProfileDocument(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName ?? fallbackDisplayName,
        photoUrl: user.photoURL,
      );
      return null;
    } catch (error) {
      return firestoreErrorMessageFor(error);
    }
  }

  /// Nilai dari Google Sign-In yang dipakai untuk membuat credential Firebase.
  /// Nilainya tidak pernah ditampilkan ke pengguna atau ditulis ke log.
  String? _googleAuthData(GoogleSignInAccount account) =>
      account.authentication.idToken;

  /// Membuat credential Firebase dari hasil Google Sign-In.
  OAuthCredential _googleCredential(String value) =>
      GoogleAuthProvider.credential(idToken: value);

  /// `google_sign_in` 7.x mewajibkan `initialize()` sekali sebelum method lain.
  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) {
      return;
    }
    await _googleSignIn.initialize(
      clientId: AppConfig.isGoogleIosClientIdConfigured
          ? AppConfig.googleIosClientId
          : null,
      serverClientId: AppConfig.isGoogleServerClientIdConfigured
          ? AppConfig.googleServerClientId
          : null,
    );
    _isGoogleSignInInitialized = true;
  }
}
