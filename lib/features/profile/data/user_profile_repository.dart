import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/repository_error_mapper.dart';
import '../domain/user_profile.dart';

/// Akses dokumen `users/{uid}` (`docs/BLUEPRINT_APLIKASI.md` bagian 6.3).
///
/// Tanggung jawab: membuat/memperbarui dokumen profil saat register atau login,
/// serta membaca profil (sekali dan realtime). Edit profil dan upload foto
/// dikerjakan pada fase profil.
class UserProfileRepository {
  UserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _entityLabel = 'profil';

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      _firestore.collection(FirestoreCollections.users).doc(uid);

  /// Stream dokumen profil milik [uid].
  ///
  /// `null` berarti dokumen belum ada atau [uid] kosong (belum login). Error
  /// Firestore dan kesalahan parsing dipetakan menjadi `AppException` lewat
  /// `guardRepositoryStream` supaya UI tidak menerima exception mentah.
  Stream<UserProfile?> watchProfile(String uid) {
    final id = uid.trim();
    if (id.isEmpty) {
      return Stream<UserProfile?>.value(null);
    }
    return guardRepositoryStream(
      _document(id).snapshots().map((snapshot) {
        final data = snapshot.data();
        if (!snapshot.exists || data == null) {
          return null;
        }
        return UserProfile.fromFirestore(id, data);
      }),
      entityLabel: _entityLabel,
    );
  }

  /// Versi sekali-baca dari [watchProfile]; `null` bila dokumen belum ada.
  Future<UserProfile?> fetchProfile(String uid) async {
    final id = uid.trim();
    if (id.isEmpty) {
      return null;
    }
    try {
      final snapshot = await _document(id).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return UserProfile.fromFirestore(id, data);
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

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
    final document = _document(uid);
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
