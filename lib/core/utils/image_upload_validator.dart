/// Validasi berkas gambar sebelum diunggah ke Firebase Storage.
///
/// Blueprint §10: jenis berkas dibatasi ke gambar dan ukurannya dibatasi wajar
/// (5 MB per berkas, sama dengan `firebase/storage.rules`). Validasi di sini
/// murni (tanpa plugin/platform channel), sehingga dapat diuji tanpa perangkat
/// dan dipakai ulang oleh layar edit profil maupun fase admin berikutnya.
library;

import '../constants/app_constants.dart';

abstract final class ImageUploadValidator {
  /// Ekstensi berkas gambar yang diterima.
  static const Set<String> allowedExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  /// Tipe MIME yang diterima; dipakai bila nama berkas tidak punya ekstensi
  /// yang dikenal (mis. berkas sementara dari `image_picker`).
  static const Set<String> allowedContentTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  /// Ukuran maksimum satu berkas; selaras [UploadLimits.maxImageSizeBytes].
  static const int maxSizeBytes = UploadLimits.maxImageSizeBytes;

  /// Batas ukuran dalam MB untuk ditulis pada pesan pengguna.
  static const int maxSizeMb = maxSizeBytes ~/ (1024 * 1024);

  /// Ekstensi huruf kecil dari [fileName] tanpa titik.
  ///
  /// String kosong berarti nama berkas tidak punya ekstensi. Nama dengan
  /// beberapa titik memakai bagian terakhir (`foto.besar.JPG` → `jpg`).
  static String extensionOf(String fileName) {
    final name = _baseName(fileName);
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) {
      return '';
    }
    return name.substring(dot + 1).toLowerCase();
  }

  /// Tipe MIME untuk [fileName]; `null` bila ekstensinya tidak diizinkan.
  static String? contentTypeForFileName(String fileName) {
    switch (extensionOf(fileName)) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  /// Tipe MIME dari [mimeType]; `null` bila tidak termasuk yang diizinkan.
  static String? contentTypeForMimeType(String? mimeType) {
    final normalized = mimeType?.trim().toLowerCase() ?? '';
    return allowedContentTypes.contains(normalized) ? normalized : null;
  }

  /// Hasil pemeriksaan satu berkas gambar.
  static ImageUploadValidation validate({
    required String fileName,
    required int sizeBytes,
    String? mimeType,
  }) {
    if (sizeBytes <= 0) {
      return const ImageUploadValidation.invalid(
        'Berkas foto tidak berisi data. Pilih berkas lain.',
      );
    }
    if (sizeBytes > maxSizeBytes) {
      final megabytes = (sizeBytes / (1024 * 1024)).ceil();
      return ImageUploadValidation.invalid(
        'Ukuran foto ±$megabytes MB melebihi batas $maxSizeMb MB.',
      );
    }

    final contentType =
        contentTypeForFileName(fileName) ?? contentTypeForMimeType(mimeType);
    if (contentType == null) {
      return const ImageUploadValidation.invalid(
        'Format foto harus JPG, PNG, atau WEBP.',
      );
    }
    return ImageUploadValidation.valid(contentType);
  }

  /// Nama berkas tanpa komponen folder, supaya nilai dari pemilih berkas tidak
  /// dapat menunjuk folder lain pada Storage (`../../`).
  static String _baseName(String fileName) {
    final normalized = fileName.replaceAll('\\', '/');
    final slash = normalized.lastIndexOf('/');
    return slash < 0 ? normalized : normalized.substring(slash + 1);
  }
}

/// Hasil validasi satu berkas gambar.
class ImageUploadValidation {
  /// Berkas lolos validasi; [contentType] dipakai saat mengunggah.
  const ImageUploadValidation.valid(String this.contentType)
    : isValid = true,
      errorMessage = null;

  /// Berkas ditolak; [errorMessage] siap ditampilkan ke pengguna.
  const ImageUploadValidation.invalid(String this.errorMessage)
    : isValid = false,
      contentType = null;

  final bool isValid;

  /// Pesan penolakan; `null` bila berkas valid.
  final String? errorMessage;

  /// Tipe MIME unggahan; `null` bila berkas tidak valid.
  final String? contentType;
}
