import 'package:flutter/foundation.dart';

import '../domain/admin_access.dart';

/// Pembacaan claim admin dari ID token terbaru.
///
/// `null` berarti pembacaan tidak mungkin dilakukan (Firebase belum
/// dikonfigurasi), yang diperlakukan sama seperti gagal membaca claim.
typedef AdminClaimsReader = Future<Map<String, dynamic>?> Function();

/// Melacak status akses admin untuk route guard dan entri drawer.
///
/// Kelas ini tidak menyentuh Firebase secara langsung: pembacaan claim
/// disuntikkan sebagai [AdminClaimsReader], sehingga keputusan izin dapat diuji
/// tanpa kredensial. Semua kegagalan pembacaan diperlakukan sebagai **akses
/// ditolak** (fail closed).
class AdminAccessNotifier extends ChangeNotifier {
  AdminAccessNotifier({required this.readClaims});

  /// Pembacaan claim yang disuntikkan; `null` bila Firebase belum dikonfigurasi.
  final AdminClaimsReader? readClaims;

  AdminAccessStatus _status = AdminAccessStatus.unknown;
  bool _isSignedIn = false;
  int _requestId = 0;
  bool _isDisposed = false;

  AdminAccessStatus get status => _status;

  bool get isGranted => _status == AdminAccessStatus.granted;

  /// Memperbarui status saat sesi login berubah, lalu memeriksa ulang claim.
  Future<void> onSessionChanged({required bool isSignedIn}) {
    _isSignedIn = isSignedIn;
    return refresh();
  }

  /// Membaca ulang claim dari ID token.
  ///
  /// Repository memakai `forceRefresh: true`, sehingga claim yang baru diberikan
  /// pemilik (mis. lewat `scripts/grant_admin.mjs`) terbaca tanpa menunggu token
  /// lama kedaluwarsa. Hasil pembacaan yang datang terlambat diabaikan supaya
  /// status tidak berbalik ke nilai lama.
  Future<void> refresh() async {
    final reader = readClaims;
    if (!_isSignedIn || reader == null) {
      _apply(AdminAccessStatus.denied);
      return;
    }

    // Selama pembacaan berlangsung status kembali `unknown`: layar admin
    // menampilkan keadaan memuat, bukan menganggap claim sudah terverifikasi.
    _apply(AdminAccessStatus.unknown);
    final requestId = ++_requestId;

    Map<String, dynamic>? claims;
    try {
      claims = await reader();
    } catch (_) {
      // Offline, token ditolak, atau claim tidak dapat dibaca: bukan admin.
      if (requestId == _requestId) {
        _apply(AdminAccessStatus.denied);
      }
      return;
    }

    if (requestId != _requestId) {
      return;
    }
    _apply(AdminAccess.fromClaims(claims).status);
  }

  void _apply(AdminAccessStatus status) {
    if (_status == status || _isDisposed) {
      return;
    }
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
