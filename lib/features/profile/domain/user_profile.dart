import '../../../core/constants/app_constants.dart';
import '../../../core/utils/firestore_document_reader.dart';

/// Model dokumen `users/{uid}` (`docs/BLUEPRINT_APLIKASI.md` §6.3).
///
/// Dokumen ini **tidak** memuat otoritas admin. Role admin hanya berasal dari
/// custom claim Firebase Auth (`{admin: true}`); field seperti `role` pada
/// dokumen profil diabaikan (lihat [containsNonAuthoritativeRoleField]).
class UserProfile {
  const UserProfile({
    required this.uid,
    this.displayName = '',
    this.email = '',
    this.phoneNumber = '',
    this.photoUrl = '',
    this.createdAt,
    this.updatedAt,
  });

  /// UID Firebase Auth, sekaligus document ID pada `users`.
  final String uid;

  final String displayName;
  final String email;
  final String phoneNumber;

  /// URL foto profil; string kosong berarti belum diunggah.
  final String photoUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Nama yang aman ditampilkan: nama, lalu email, terakhir UID.
  String get preferredName {
    if (displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    if (email.trim().isNotEmpty) {
      return email.trim();
    }
    return uid;
  }

  /// `true` bila foto profil sudah diisi.
  bool get hasPhoto => photoUrl.trim().isNotEmpty;

  /// `true` bila nomor telepon sudah diisi.
  bool get hasPhoneNumber => phoneNumber.trim().isNotEmpty;

  /// `true` bila dokumen memuat field yang mengaku sebagai role/claim.
  ///
  /// Hasilnya hanya untuk audit/diagnostik: aplikasi tetap tidak memakai field
  /// tersebut sebagai otoritas. Admin ditentukan dari custom claim.
  static bool containsNonAuthoritativeRoleField(Map<String, dynamic> data) {
    for (final field in UserProfileFields.nonAuthoritativeRoleFields) {
      if (data.containsKey(field)) {
        return true;
      }
    }
    return false;
  }

  /// Field dokumen profil yang boleh ditulis aplikasi.
  ///
  /// Dipakai repository agar perubahan dari klien tidak pernah menyentuh
  /// role/claim atau field tak dikenal.
  static const Set<String> writableFields = <String>{
    UserProfileFields.displayName,
    UserProfileFields.phoneNumber,
    UserProfileFields.photoUrl,
  };

  /// Membaca dokumen Firestore dengan validasi field.
  ///
  /// Seluruh field bersifat opsional (dokumen dibuat saat register), tetapi
  /// tipe yang salah tetap ditolak agar UI tidak menampilkan data tak valid.
  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    final reader = FirestoreDocumentReader(
      documentPath: '${FirestoreCollections.users}/$uid',
      data: data,
    );
    return UserProfile(
      uid: uid,
      displayName: reader.optionalString(UserProfileFields.displayName),
      email: reader.optionalString(UserProfileFields.email),
      phoneNumber: reader.optionalString(UserProfileFields.phoneNumber),
      photoUrl: reader.optionalString(UserProfileFields.photoUrl),
      createdAt: reader.optionalDateTime(UserProfileFields.createdAt),
      updatedAt: reader.optionalDateTime(UserProfileFields.updatedAt),
    );
  }

  @override
  String toString() => 'UserProfile($uid)';
}
