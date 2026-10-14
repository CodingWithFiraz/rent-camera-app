import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';

/// Akses dokumen `users/{uid}` (`docs/BLUEPRINT_APLIKASI.md` §6.3).
///
/// Fase ini hanya membuat/memperbarui dokumen profil saat register atau login.
/// Edit profil dan upload foto dikerjakan pada fase profil.
class UserProfileRepository {
  UserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Membuat dokumen profil bila belum ada, atau memperbarui field yang
  /// diketahui tanpa menghapus field profil lain.
  ///
  /// Memakai `set(..., merge: true)` supaya nomor telepon, foto, atau data lain
  /// yang sudah ada tidak ikut terhapus. Dokumen ini **tidak pernah** menulis
  /// role/claim admin: role hanya berasal dari custom claim Firebase Auth.
  Future<void> ensureProfileDocument({
    required String uid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    final document = _firestore.collection(FirestoreCollections.users).doc(uid);
    final snapshot = await document.get();

    final Map<String, dynamic> data = <String, dynamic>{
      UserProfileFields.updatedAt: FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      data[UserProfileFields.createdAt] = FieldValue.serverTimestamp();
      // Nilai awal kosong agar bentuk dokumen konsisten; diisi pengguna pada
      // fase profil.
      data[UserProfileFields.phoneNumber] = '';
    }

    final normalizedEmail = email?.trim();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      data[UserProfileFields.email] = normalizedEmail;
    }

    final normalizedName = displayName?.trim();
    if (normalizedName != null && normalizedName.isNotEmpty) {
      data[UserProfileFields.displayName] = normalizedName;
    }

    final normalizedPhotoUrl = photoUrl?.trim();
    if (normalizedPhotoUrl != null && normalizedPhotoUrl.isNotEmpty) {
      data[UserProfileFields.photoUrl] = normalizedPhotoUrl;
    }

    await document.set(data, SetOptions(merge: true));
  }
}
