import '../../../core/routing/app_routes.dart';
import 'admin_access.dart';

/// `true` bila [location] berada pada area dashboard admin.
///
/// Pemeriksaan memakai awalan `'/admin/'` (bukan sekadar `'/admin'`) supaya
/// route lain seperti `/administrasi` tidak pernah ikut dianggap area admin.
bool isAdminRoute(String location) {
  final path = location.trim();
  return path == AppRoutes.admin || path.startsWith('${AppRoutes.admin}/');
}

/// Lokasi tujuan untuk route admin berdasarkan [access].
///
/// Fungsi ini murni (tanpa Firebase/go_router) supaya keputusan otorisasi dapat
/// diuji tanpa kredensial:
/// - `denied` → route admin dialihkan ke katalog (fail closed). Status ini
///   mencakup claim yang tidak ada, bertipe salah, maupun **pembacaan ID token
///   yang gagal**: kegagalan verifikasi selalu berarti akses ditolak.
/// - `unknown` → **tidak** dialihkan. Status ini berarti pemeriksaan belum
///   selesai (bukan kegagalan), dan layar admin wajib menampilkan keadaan
///   memuat tanpa menjalankan aksi tulis sebelum statusnya `granted`.
/// - `granted` → tidak ada pengalihan.
/// - Route non-admin tidak pernah diubah oleh fungsi ini.
///
/// Route guard ini **bukan** pengamanan backend: Firestore Security Rules dan
/// Storage Rules tetap menolak penulisan produk oleh non-admin walaupun route
/// ini dilewati (lihat `firebase/firestore.rules`).
String? resolveAdminRedirect({
  required String location,
  required AdminAccessStatus access,
}) {
  if (access == AdminAccessStatus.denied && isAdminRoute(location)) {
    return AppRoutes.catalog;
  }
  return null;
}
