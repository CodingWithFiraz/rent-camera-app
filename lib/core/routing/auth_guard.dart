import 'app_routes.dart';

/// Status sesi Firebase Auth seperti yang dibaca route guard.
enum AuthSessionStatus {
  /// Belum ada kabar dari `authStateChanges()`; UI harus menampilkan loading.
  unknown,
  signedIn,
  signedOut,
}

/// Menentukan lokasi tujuan berdasarkan status sesi dan konfigurasi Firebase.
///
/// Fungsi ini murni (tanpa Firebase/go_router) supaya keputusan navigasi bisa
/// diuji tanpa kredensial:
/// - Firebase belum dikonfigurasi → hanya `/setup-required` yang boleh dibuka.
/// - Sesi belum diketahui → `/splash`.
/// - Belum login → hanya route publik auth yang boleh, sisanya `/login`.
/// - Sudah login → route auth publik dialihkan ke `/catalog`.
///
/// Route apa pun yang bukan route publik auth dianggap terproteksi
/// (default-deny), sehingga menambah route baru tidak membuka akses tanpa
/// autentikasi.
String? resolveAuthRedirect({
  required String location,
  required bool isFirebaseConfigured,
  required AuthSessionStatus sessionStatus,
}) {
  if (!isFirebaseConfigured) {
    return location == AppRoutes.setupRequired ? null : AppRoutes.setupRequired;
  }

  if (location == AppRoutes.setupRequired) {
    return sessionStatus == AuthSessionStatus.signedIn
        ? AppRoutes.catalog
        : AppRoutes.login;
  }

  switch (sessionStatus) {
    case AuthSessionStatus.unknown:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case AuthSessionStatus.signedOut:
      return isPublicAuthRoute(location) ? null : AppRoutes.login;
    case AuthSessionStatus.signedIn:
      return isPublicAuthRoute(location) || location == AppRoutes.splash
          ? AppRoutes.catalog
          : null;
  }
}

/// Route yang boleh dibuka tanpa sesi login.
bool isPublicAuthRoute(String location) =>
    location == AppRoutes.login ||
    location == AppRoutes.register ||
    location == AppRoutes.forgotPassword;

/// Route yang membutuhkan sesi login.
bool isProtectedRoute(String location) =>
    !isPublicAuthRoute(location) &&
    location != AppRoutes.splash &&
    location != AppRoutes.setupRequired;
