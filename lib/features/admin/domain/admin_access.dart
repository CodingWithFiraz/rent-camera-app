/// Nama custom claim penanda admin pada ID token Firebase Authentication.
///
/// Nilai ini harus sama dengan pemeriksaan pada `firebase/firestore.rules` dan
/// `firebase/storage.rules` (`request.auth.token.admin == true`).
const String adminClaimKey = 'admin';

/// Status akses dashboard admin seperti yang dibaca route guard dan drawer.
enum AdminAccessStatus {
  /// Claim belum selesai diperiksa (aplikasi baru dibuka/token sedang dimuat).
  ///
  /// Status ini **bukan** kegagalan, tetapi juga bukan izin: layar admin wajib
  /// menampilkan keadaan memuat dan belum menjalankan aksi tulis apa pun.
  unknown,

  /// Claim `admin: true` terbaca dari ID token.
  granted,

  /// Claim tidak ada atau bukan `true`, pembacaan token gagal, atau tidak ada
  /// sesi login. Semua keadaan itu diperlakukan sama: akses ditolak.
  denied,
}

/// Hasil pembacaan custom claim admin dari ID token.
class AdminAccess {
  const AdminAccess._(this.status);

  /// Claim `admin: true` terverifikasi.
  const AdminAccess.granted() : this._(AdminAccessStatus.granted);

  /// Akses ditolak (fail closed).
  const AdminAccess.denied() : this._(AdminAccessStatus.denied);

  /// Belum diperiksa.
  const AdminAccess.unknown() : this._(AdminAccessStatus.unknown);

  /// Membaca claim admin dari isi ID token.
  ///
  /// `claims == null` (tidak ada sesi login) menghasilkan [AdminAccessStatus.denied].
  factory AdminAccess.fromClaims(Map<String, dynamic>? claims) {
    if (claims == null) {
      return const AdminAccess.denied();
    }
    return AdminAccess._(
      isAdminClaim(claims[adminClaimKey])
          ? AdminAccessStatus.granted
          : AdminAccessStatus.denied,
    );
  }

  final AdminAccessStatus status;

  bool get isGranted => status == AdminAccessStatus.granted;

  bool get isDenied => status == AdminAccessStatus.denied;

  /// `true` hanya bila [value] bertipe `bool` dan bernilai `true`.
  ///
  /// Nilai seperti `'true'`, `'1'`, atau `1` **ditolak**. Perbandingan pada
  /// Security Rules memakai boolean murni, sehingga memaksa konversi di aplikasi
  /// akan membuat UI berbeda dari otorisasi backend yang sebenarnya berlaku.
  static bool isAdminClaim(Object? value) => value is bool && value;
}
