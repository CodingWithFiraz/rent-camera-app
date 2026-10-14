/// Nama collection Firestore yang dipakai aplikasi.
///
/// Sumber: `docs/BLUEPRINT_APLIKASI.md` §6. Collection lain ditambahkan pada
/// fase yang memperkenalkan repository-nya, supaya tidak ada nama collection
/// yang tersebar sebagai string literal di widget.
abstract final class FirestoreCollections {
  /// `users/{uid}`
  static const String users = 'users';
}

/// Nama field dokumen `users/{uid}` (`docs/BLUEPRINT_APLIKASI.md` §6.3).
///
/// Field role/claim admin **tidak** ada di sini dengan sengaja: role admin
/// hanya berasal dari custom claim Firebase Authentication.
abstract final class UserProfileFields {
  static const String displayName = 'displayName';
  static const String email = 'email';
  static const String phoneNumber = 'phoneNumber';
  static const String photoUrl = 'photoUrl';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}
