import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/repository_error_mapper.dart';
import '../../../core/utils/image_upload_validator.dart';
import '../data/admin_product_image_picker.dart';
import '../data/admin_product_repository.dart';
import '../data/product_image_storage.dart';
import '../domain/product_draft.dart';
import 'admin_providers.dart';

/// Status form tambah/edit produk.
class AdminProductFormState {
  const AdminProductFormState({
    this.isPicking = false,
    this.isSaving = false,
    this.pendingImages = const <PickedProductImage>[],
    this.removedImageUrls = const <String>[],
    this.uploadedImageCount = 0,
    this.uploadTotal = 0,
    this.uploadProgress = 0,
    this.errorMessage,
    this.noticeMessage,
  });

  /// `true` selama galeri dibuka dan berkas dibaca.
  final bool isPicking;

  /// `true` selama foto diunggah dan/atau produk ditulis ke Firestore.
  final bool isSaving;

  /// Foto baru yang sudah lolos validasi tetapi belum diunggah.
  final List<PickedProductImage> pendingImages;

  /// URL foto lama yang ditandai untuk dibuang. Berkas Storage-nya baru dihapus
  /// setelah penyimpanan berhasil, sehingga kegagalan tidak menghapus foto lama.
  final List<String> removedImageUrls;

  /// Jumlah foto yang sudah selesai diunggah pada operasi simpan berjalan.
  final int uploadedImageCount;

  /// Jumlah foto baru yang akan diunggah.
  final int uploadTotal;

  /// Kemajuan unggahan berkas yang sedang berjalan (0.0–1.0), berasal dari
  /// `bytesTransferred / totalBytes` Firebase Storage — bukan animasi hiasan.
  final double uploadProgress;

  /// Pesan kegagalan yang sudah dipetakan; `null` bila tidak ada.
  final String? errorMessage;

  /// Pesan informasi non-fatal; `null` bila tidak ada.
  final String? noticeMessage;

  /// `true` bila ada pekerjaan yang membuat form harus dinonaktifkan.
  bool get isBusy => isPicking || isSaving;

  /// `true` bila sedang ada unggahan foto yang berjalan.
  bool get isUploading => isSaving && uploadTotal > 0;

  AdminProductFormState copyWith({
    bool? isPicking,
    bool? isSaving,
    List<PickedProductImage>? pendingImages,
    List<String>? removedImageUrls,
    int? uploadedImageCount,
    int? uploadTotal,
    double? uploadProgress,
    String? errorMessage,
    String? noticeMessage,
    bool clearError = false,
    bool clearNotice = false,
  }) => AdminProductFormState(
    isPicking: isPicking ?? this.isPicking,
    isSaving: isSaving ?? this.isSaving,
    pendingImages: pendingImages ?? this.pendingImages,
    removedImageUrls: removedImageUrls ?? this.removedImageUrls,
    uploadedImageCount: uploadedImageCount ?? this.uploadedImageCount,
    uploadTotal: uploadTotal ?? this.uploadTotal,
    uploadProgress: uploadProgress ?? this.uploadProgress,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    noticeMessage: clearNotice ? null : (noticeMessage ?? this.noticeMessage),
  );
}

/// Menjalankan pemilihan, validasi, unggah, dan penyimpanan produk.
///
/// Kelas ini tidak menyentuh Firebase secara langsung: pemilih berkas,
/// penyimpanan foto, dan repository disuntikkan lewat provider, sehingga seluruh
/// alurnya dapat diuji tanpa kredensial maupun platform channel.
class AdminProductFormController extends Notifier<AdminProductFormState> {
  @override
  AdminProductFormState build() => const AdminProductFormState();

  AdminProductImagePicker get _picker =>
      ref.read(adminProductImagePickerProvider);

  ProductImageStorage get _storage => ref.read(productImageStorageProvider);

  AdminProductRepository get _repository =>
      ref.read(adminProductRepositoryProvider);

  /// Document ID baru untuk produk yang akan dibuat.
  ///
  /// Dipanggil form tambah produk supaya ID sudah pasti sebelum foto dipilih
  /// (foto disimpan pada `products/{productId}/**`).
  String reserveNewProductId() => _repository.reserveProductId();

  /// Membuka galeri, membaca berkas, lalu memvalidasi format dan ukurannya.
  ///
  /// Pembatalan oleh admin bukan kegagalan: pratinjau sebelumnya tetap dipakai
  /// dan tidak ada pesan error. Berkas yang ditolak tidak pernah diunggah.
  Future<void> pickImages() async {
    if (state.isBusy) {
      return;
    }
    final previous = state.pendingImages;
    state = state.copyWith(
      isPicking: true,
      clearError: true,
      clearNotice: true,
    );

    final List<PickedProductImage> picked;
    try {
      picked = await _picker.pickImages();
    } catch (_) {
      // Detail kegagalan platform (izin ditolak, galeri tidak tersedia) tidak
      // ditampilkan mentah kepada pengguna.
      state = state.copyWith(
        isPicking: false,
        pendingImages: previous,
        errorMessage: 'Foto tidak dapat dipilih dari galeri. Coba lagi.',
      );
      return;
    }

    if (picked.isEmpty) {
      state = state.copyWith(isPicking: false, pendingImages: previous);
      return;
    }

    final accepted = <PickedProductImage>[];
    String? rejectionMessage;
    for (final image in picked) {
      final validation = ImageUploadValidator.validate(
        fileName: image.fileName,
        sizeBytes: image.sizeBytes,
        mimeType: image.mimeType,
      );
      if (validation.isValid) {
        accepted.add(image.withContentType(validation.contentType!));
      } else {
        rejectionMessage ??= validation.errorMessage;
      }
    }

    final rejectedCount = picked.length - accepted.length;
    state = state.copyWith(
      isPicking: false,
      pendingImages: <PickedProductImage>[...previous, ...accepted],
      errorMessage: rejectedCount == 0
          ? null
          : '$rejectedCount foto tidak dipakai. ${rejectionMessage ?? ''}'
                .trim(),
      clearError: rejectedCount == 0,
      noticeMessage: accepted.isEmpty
          ? null
          : '${accepted.length} foto siap diunggah saat produk disimpan.',
      clearNotice: accepted.isEmpty,
    );
  }

  /// Membuang satu pratinjau foto baru.
  void removePendingImage(int index) {
    if (state.isBusy || index < 0 || index >= state.pendingImages.length) {
      return;
    }
    final remaining = <PickedProductImage>[...state.pendingImages]
      ..removeAt(index);
    state = state.copyWith(pendingImages: remaining);
  }

  /// Membuang seluruh pratinjau foto baru; foto produk yang tersimpan tidak
  /// tersentuh.
  void clearPendingImages() {
    if (state.isBusy || state.pendingImages.isEmpty) {
      return;
    }
    state = state.copyWith(pendingImages: const <PickedProductImage>[]);
  }

  /// Menandai foto lama untuk dibuang, atau membatalkan penandaan itu.
  ///
  /// Berkas pada Storage baru dihapus setelah penyimpanan berhasil.
  void toggleExistingImageRemoval(String imageUrl) {
    if (state.isBusy) {
      return;
    }
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return;
    }
    final removed = <String>[...state.removedImageUrls];
    if (!removed.remove(url)) {
      removed.add(url);
    }
    state = state.copyWith(removedImageUrls: removed);
  }

  /// Menghapus pesan yang sudah dibaca pengguna.
  void clearMessages() {
    if (state.isBusy) {
      return;
    }
    state = state.copyWith(clearError: true, clearNotice: true);
  }

  /// Mengembalikan form ke keadaan awal (mis. saat layar dibuka kembali).
  void reset() => state = const AdminProductFormState();

  /// Mengunggah foto baru, lalu menulis produk ke Firestore.
  ///
  /// Urutannya sengaja unggah → Firestore: bila unggahan gagal, dokumen produk
  /// tidak disentuh sama sekali, sehingga foto lama tetap tampil dan tidak ada
  /// dokumen setengah jadi (blueprint §10). Unggahan yang batal dipakai
  /// dibersihkan kembali, sedangkan berkas foto lama yang dibuang baru dihapus
  /// **setelah** penyimpanan berhasil.
  ///
  /// Mengembalikan `true` hanya bila Firestore benar-benar menerima penulisan,
  /// supaya layar tidak pernah menutup dengan pesan sukses palsu.
  Future<bool> save({
    required String productId,
    required bool isNew,
    required ProductDraft draft,
    required List<String> existingImageUrls,
  }) async {
    if (state.isBusy) {
      return false;
    }

    final pending = state.pendingImages;
    final removed = state.removedImageUrls.toSet();
    final keptExisting = existingImageUrls
        .where((String url) => !removed.contains(url))
        .toList(growable: false);
    final uploaded = <UploadedProductImage>[];

    state = state.copyWith(
      isSaving: true,
      uploadTotal: pending.length,
      uploadedImageCount: 0,
      uploadProgress: 0,
      clearError: true,
      clearNotice: true,
    );

    try {
      for (var index = 0; index < pending.length; index++) {
        final image = pending[index];
        final contentType = image.contentType;
        if (contentType == null || contentType.isEmpty) {
          throw const AppException(
            'Foto belum siap diunggah. Pilih ulang fotonya.',
          );
        }
        uploaded.add(
          await _storage.upload(
            productId: productId,
            bytes: image.bytes,
            contentType: contentType,
            onProgress: (double progress) =>
                _reportProgress(index: index, progress: progress),
          ),
        );
      }

      final draftToSave = draft.copyWith(
        imageUrls: <String>[
          ...keptExisting,
          ...uploaded.map((UploadedProductImage item) => item.downloadUrl),
        ],
      );
      if (isNew) {
        await _repository.createProduct(
          productId: productId,
          draft: draftToSave,
        );
      } else {
        await _repository.updateProduct(
          productId: productId,
          draft: draftToSave,
        );
      }
    } catch (error) {
      for (final item in uploaded) {
        await _storage.deletePath(item.storagePath);
      }
      state = state.copyWith(
        isSaving: false,
        uploadTotal: 0,
        uploadedImageCount: 0,
        uploadProgress: 0,
        errorMessage: repositoryErrorMessageFor(error, entityLabel: 'produk'),
      );
      return false;
    }

    for (final url in removed) {
      await _storage.deleteByUrl(url);
    }

    state = const AdminProductFormState(
      noticeMessage: 'Produk berhasil disimpan.',
    );
    return true;
  }

  void _reportProgress({required int index, required double progress}) {
    if (!state.isSaving) {
      return;
    }
    state = state.copyWith(
      uploadedImageCount: index,
      uploadProgress: progress.clamp(0.0, 1.0).toDouble(),
    );
  }
}
