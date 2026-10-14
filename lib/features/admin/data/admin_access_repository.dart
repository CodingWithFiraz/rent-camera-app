import 'package:firebase_auth/firebase_auth.dart';

/// Membaca custom claim admin dari ID token Firebase Auth.
///
/// Ini satu-satunya tempat aplikasi menyentuh `FirebaseAuth` untuk keperluan
/// otorisasi, sehingga layar admin tidak perlu (dan tidak boleh) menebak status
/// admin dari dokumen Firestore atau dari nama akun.
class AdminAccessRepository {
  AdminAccessRepository(this._auth);

  final FirebaseAuth _auth;

  /// Claim dari ID token terbaru; `null` bila tidak ada sesi login.
  ///
  /// `forceRefresh: true` dipakai supaya claim yang baru diberikan pemilik
  /// (mis. lewat `scripts/grant_admin.mjs`) terbaca tanpa menunggu token lama
  /// kedaluwarsa. Kegagalan pembacaan (offline, token ditolak) dilempar apa
  /// adanya; pemanggil menanggapinya sebagai **akses ditolak**, bukan sebagai
  /// admin (fail closed).
  Future<Map<String, dynamic>?> readClaims() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    final result = await user.getIdTokenResult(true);
    return result.claims;
  }
}
