import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Foto produk yang dipilih admin dari galeri, beserta metadata validasinya.
class PickedProductImage {
  const PickedProductImage({
    required this.bytes,
    required this.fileName,
    this.mimeType,
    this.contentType,
  });

  final Uint8List bytes;

  /// Nama berkas seperti dilaporkan perangkat; dipakai memeriksa ekstensi.
  final String fileName;

  /// Tipe MIME dari pemilih berkas; `null` bila platform tidak melaporkannya.
  final String? mimeType;

  /// Tipe MIME final hasil validasi; `null` selama berkas belum divalidasi.
  final String? contentType;

  /// Ukuran berkas dalam byte.
  int get sizeBytes => bytes.length;

  /// Salinan dengan [contentType] hasil validasi.
  PickedProductImage withContentType(String contentType) => PickedProductImage(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    contentType: contentType,
  );
}

/// Kontrak pemilih foto produk dari galeri.
///
/// Form produk bergantung pada interface ini, sehingga test dapat memakai
/// pemilih palsu tanpa memanggil platform channel `image_picker`.
abstract interface class AdminProductImagePicker {
  /// Mengembalikan foto terpilih (boleh lebih dari satu).
  ///
  /// Daftar kosong berarti admin membatalkan pemilihan — bukan kegagalan.
  Future<List<PickedProductImage>> pickImages();
}

/// Implementasi `image_picker` untuk memilih beberapa foto sekaligus.
///
/// Ukuran dibatasi saat pemilihan (maks. 1600 px, kualitas 85%) supaya berkas
/// tetap di bawah batas 5 MB yang dipakai Storage Rules; validasi ukuran dan
/// format tetap dilakukan ulang secara eksplisit sebelum mengunggah.
class ImagePickerAdminProductImagePicker implements AdminProductImagePicker {
  ImagePickerAdminProductImagePicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<PickedProductImage>> pickImages() async {
    final files = await _picker.pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    final images = <PickedProductImage>[];
    for (final file in files) {
      images.add(
        PickedProductImage(
          bytes: await file.readAsBytes(),
          fileName: file.name,
          mimeType: file.mimeType,
        ),
      );
    }
    return images;
  }
}
