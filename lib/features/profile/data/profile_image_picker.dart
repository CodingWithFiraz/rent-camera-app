import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Foto yang dipilih pengguna dari galeri, beserta metadata untuk validasi.
class PickedProfileImage {
  const PickedProfileImage({
    required this.bytes,
    required this.fileName,
    this.mimeType,
    this.contentType,
  });

  final Uint8List bytes;

  /// Nama berkas seperti dilaporkan perangkat; dipakai untuk memeriksa ekstensi.
  final String fileName;

  /// Tipe MIME dari pemilih berkas; `null` bila platform tidak melaporkannya.
  final String? mimeType;

  /// Tipe MIME final hasil validasi; `null` selama berkas belum divalidasi.
  final String? contentType;

  /// Ukuran berkas dalam byte.
  int get sizeBytes => bytes.length;

  /// Salinan dengan [contentType] hasil validasi.
  PickedProfileImage withContentType(String contentType) => PickedProfileImage(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    contentType: contentType,
  );
}

/// Kontrak pemilih foto dari galeri.
///
/// Layar edit profil bergantung pada interface ini, sehingga test dapat memakai
/// pemilih palsu tanpa memanggil platform channel `image_picker`.
abstract interface class ProfileImagePicker {
  /// Mengembalikan foto terpilih, atau `null` bila pengguna membatalkan.
  Future<PickedProfileImage?> pickFromGallery();
}

/// Implementasi `image_picker` untuk galeri perangkat.
///
/// Ukuran gambar dibatasi saat pemilihan (maks. 1600 px, kualitas 85%) supaya
/// berkas tetap di bawah batas 5 MB yang dipakai Storage Rules; validasi ukuran
/// dan format tetap dilakukan ulang secara eksplisit sebelum mengunggah.
class ImagePickerProfileImagePicker implements ProfileImagePicker {
  ImagePickerProfileImagePicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedProfileImage?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null) {
      return null;
    }
    return PickedProfileImage(
      bytes: await file.readAsBytes(),
      fileName: file.name,
      mimeType: file.mimeType,
    );
  }
}
