import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/storage_error_mapper.dart';

/// Hasil satu unggahan foto profil.
class UploadedProfilePhoto {
  const UploadedProfilePhoto({
    required this.downloadUrl,
    required this.storagePath,
  });

  /// URL unduhan yang disimpan ke `users/{uid}.photoUrl`.
  final String downloadUrl;

  /// Path objek pada Storage, mis. `profiles/{uid}/photo-….jpg`.
  ///
  /// Disimpan supaya unggahan yang batal dipakai (mis. penulisan Firestore
  /// gagal) dapat dibersihkan kembali.
  final String storagePath;
}

/// Kontrak penyimpanan foto profil.
///
/// UI bergantung pada interface ini sehingga layar edit profil dapat diuji
/// tanpa menyentuh Firebase Storage.
abstract interface class ProfilePhotoStorage {
  /// Mengunggah [bytes] ke `profiles/{uid}/**` dan mengembalikan URL unduhan.
  Future<UploadedProfilePhoto> upload({
    required String uid,
    required Uint8List bytes,
    required String contentType,
  });

  /// Menghapus berkas pada [storagePath] (best-effort).
  Future<void> deletePath(String storagePath);

  /// Menghapus berkas dari URL foto lama (best-effort).
  ///
  /// Hanya dipanggil **setelah** penyimpanan berhasil, supaya penggantian foto
  /// yang gagal tidak pernah menghapus foto lama (blueprint §10).
  Future<void> deleteByUrl(String downloadUrl);
}

/// Implementasi Firebase Storage untuk `profiles/{uid}/{fileName}`
/// (blueprint §9 bagian Storage dan §10).
class FirebaseProfilePhotoStorage implements ProfilePhotoStorage {
  FirebaseProfilePhotoStorage(this._storage);

  final FirebaseStorage _storage;

  static const String _entityLabel = 'foto profil';

  @override
  Future<UploadedProfilePhoto> upload({
    required String uid,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final id = uid.trim();
    if (id.isEmpty) {
      throw const AppException(
        'Sesi login tidak ditemukan, sehingga foto tidak dapat diunggah.',
      );
    }
    final extension = _extensionFor(contentType);
    if (extension == null) {
      throw const AppException(
        'Format foto tidak didukung. Gunakan JPG, PNG, atau WEBP.',
      );
    }

    // Nama berkas dibuat aplikasi (bukan nama asli dari perangkat) supaya path
    // tidak memuat karakter aneh dan setiap penggantian foto menghasilkan objek
    // baru, bukan menimpa berkas yang mungkin masih di-cache.
    final fileName =
        'photo-${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = StoragePaths.profilePhoto(id, fileName);

    try {
      final reference = _storage.ref(path);
      await reference.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      final downloadUrl = await reference.getDownloadURL();
      return UploadedProfilePhoto(downloadUrl: downloadUrl, storagePath: path);
    } catch (error) {
      throw mapStorageError(error, entityLabel: _entityLabel);
    }
  }

  @override
  Future<void> deletePath(String storagePath) async {
    final path = storagePath.trim();
    if (path.isEmpty) {
      return;
    }
    try {
      await _storage.ref(path).delete();
    } catch (_) {
      // Best-effort: kegagalan pembersihan tidak boleh dilaporkan sebagai
      // kegagalan penyimpanan profil yang sudah berhasil.
    }
  }

  @override
  Future<void> deleteByUrl(String downloadUrl) async {
    final url = downloadUrl.trim();
    if (url.isEmpty) {
      return;
    }
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // URL bisa menunjuk foto dari penyedia lain (mis. foto akun Google) atau
      // berkas sudah tidak ada; keduanya bukan kegagalan yang perlu dilaporkan.
    }
  }

  /// Ekstensi berkas untuk [contentType] yang sudah tervalidasi.
  static String? _extensionFor(String contentType) {
    switch (contentType) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      default:
        return null;
    }
  }
}
