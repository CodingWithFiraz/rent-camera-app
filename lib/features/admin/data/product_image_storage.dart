import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/storage_error_mapper.dart';

/// Hasil satu unggahan foto produk.
class UploadedProductImage {
  const UploadedProductImage({
    required this.downloadUrl,
    required this.storagePath,
  });

  /// URL unduhan yang disimpan ke `products/{productId}.imageUrls`.
  final String downloadUrl;

  /// Path objek pada Storage, mis. `products/{productId}/foto-….jpg`.
  ///
  /// Disimpan supaya unggahan yang batal dipakai (mis. penulisan Firestore
  /// gagal) dapat dibersihkan kembali.
  final String storagePath;
}

/// Pelaporan kemajuan unggah berkas (0.0–1.0).
typedef UploadProgressCallback = void Function(double progress);

/// Kontrak penyimpanan foto produk.
///
/// UI bergantung pada interface ini supaya form produk dapat diuji tanpa
/// menyentuh Firebase Storage.
abstract interface class ProductImageStorage {
  /// Mengunggah [bytes] ke `products/{productId}/**` dan mengembalikan URL.
  ///
  /// [onProgress] dipanggil dengan kemajuan nyata dari Storage
  /// (`bytesTransferred / totalBytes`), bukan animasi dekoratif.
  Future<UploadedProductImage> upload({
    required String productId,
    required Uint8List bytes,
    required String contentType,
    UploadProgressCallback? onProgress,
  });

  /// Menghapus berkas pada [storagePath] (best-effort).
  Future<void> deletePath(String storagePath);

  /// Menghapus berkas dari URL foto (best-effort).
  ///
  /// Hanya dipanggil untuk foto yang benar-benar sudah tidak dipakai lagi dan
  /// **setelah** penyimpanan berhasil.
  Future<void> deleteByUrl(String downloadUrl);
}

/// Implementasi Firebase Storage untuk `products/{productId}/{fileName}`
/// (blueprint §9 bagian Storage dan §10).
class FirebaseProductImageStorage implements ProductImageStorage {
  FirebaseProductImageStorage(this._storage);

  final FirebaseStorage _storage;

  static const String _entityLabel = 'foto produk';

  static final Random _random = Random();

  @override
  Future<UploadedProductImage> upload({
    required String productId,
    required Uint8List bytes,
    required String contentType,
    UploadProgressCallback? onProgress,
  }) async {
    final id = productId.trim();
    if (id.isEmpty) {
      throw const AppException(
        'Produk belum memiliki ID, sehingga foto tidak dapat diunggah.',
      );
    }
    final extension = _extensionFor(contentType);
    if (extension == null) {
      throw const AppException(
        'Format foto tidak didukung. Gunakan JPG, PNG, atau WEBP.',
      );
    }

    // Nama berkas dibuat aplikasi (bukan nama asli dari perangkat) supaya path
    // tidak memuat karakter aneh. Bagian acak mencegah dua foto yang dipilih
    // pada milidetik yang sama saling menimpa.
    final fileName =
        'foto-${DateTime.now().millisecondsSinceEpoch}-'
        '${_randomSuffix()}.$extension';
    final path = StoragePaths.productImage(id, fileName);

    try {
      final reference = _storage.ref(path);
      final task = reference.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      if (onProgress != null) {
        task.snapshotEvents.listen(
          (TaskSnapshot snapshot) {
            final total = snapshot.totalBytes;
            if (total <= 0) {
              return;
            }
            onProgress((snapshot.bytesTransferred / total).clamp(0.0, 1.0));
          },
          // Kegagalan sudah dilaporkan lewat `await task` di bawah; error pada
          // stream kemajuan tidak boleh menjadi uncaught async error.
          onError: (Object _) {},
        );
      }
      await task.timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          task.cancel();
          throw const AppException(
            'Unggahan foto memakan waktu terlalu lama. Pastikan Firebase Storage sudah diaktifkan di Firebase Console (console.firebase.google.com) atau simpan tanpa foto.',
          );
        },
      );
      final downloadUrl = await reference.getDownloadURL();
      onProgress?.call(1);
      return UploadedProductImage(downloadUrl: downloadUrl, storagePath: path);
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
      // kegagalan penyimpanan produk yang sudah berhasil.
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
      // URL bisa menunjuk berkas milik penyedia lain (mis. foto contoh) atau
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

  static String _randomSuffix() =>
      _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
}
