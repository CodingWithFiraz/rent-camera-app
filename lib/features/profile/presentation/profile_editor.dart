import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/repository_error_mapper.dart';
import '../../../core/utils/image_upload_validator.dart';
import '../data/profile_image_picker.dart';
import '../data/profile_photo_storage.dart';
import '../data/user_profile_repository.dart';
import 'profile_providers.dart';

/// Status layar Edit Profil.
class ProfileEditorState {
  const ProfileEditorState({
    this.isPicking = false,
    this.isSaving = false,
    this.pickedImage,
    this.errorMessage,
    this.noticeMessage,
  });

  /// `true` selama galeri dibuka dan berkas dibaca.
  final bool isPicking;

  /// `true` selama foto diunggah dan/atau profil disimpan.
  final bool isSaving;

  /// Foto yang sudah dipilih tetapi belum disimpan; `null` berarti tidak ada
  /// perubahan foto (foto lama tetap dipakai).
  final PickedProfileImage? pickedImage;

  /// Pesan kegagalan yang sudah dipetakan; `null` bila tidak ada.
  final String? errorMessage;

  /// Pesan informasi non-fatal; `null` bila tidak ada.
  final String? noticeMessage;

  /// `true` bila ada pekerjaan yang membuat form harus dinonaktifkan.
  bool get isBusy => isPicking || isSaving;
}

/// Menjalankan pemilihan, validasi, unggah, dan penyimpanan profil.
///
/// Kelas ini tidak menyentuh Firebase secara langsung: pemilih berkas,
/// penyimpanan foto, dan repository disuntikkan lewat provider sehingga dapat
/// diuji tanpa kredensial maupun platform channel.
///
/// Urutan penyimpanan sengaja menulis Firestore **setelah** unggah berhasil:
/// bila unggahan gagal, `users/{uid}.photoUrl` tidak disentuh sama sekali,
/// sehingga foto lama tetap tampil (blueprint §10).
class ProfileEditor extends Notifier<ProfileEditorState> {
  @override
  ProfileEditorState build() => const ProfileEditorState();

  ProfileImagePicker get _picker => ref.read(profileImagePickerProvider);

  ProfilePhotoStorage get _storage => ref.read(profilePhotoStorageProvider);

  UserProfileRepository get _repository =>
      ref.read(userProfileRepositoryProvider);

  /// Membuka galeri, membaca berkas, lalu memvalidasi format dan ukurannya.
  ///
  /// Pembatalan oleh pengguna bukan kegagalan: pilihan foto sebelumnya tetap
  /// dipertahankan dan tidak ada pesan error.
  Future<void> pickPhoto() async {
    if (state.isBusy) {
      return;
    }
    final previous = state.pickedImage;
    state = ProfileEditorState(isPicking: true, pickedImage: previous);

    final PickedProfileImage? picked;
    try {
      picked = await _picker.pickFromGallery();
    } catch (_) {
      // Detail kegagalan platform (izin ditolak, galeri tidak tersedia) tidak
      // ditampilkan mentah kepada pengguna.
      state = ProfileEditorState(
        pickedImage: previous,
        errorMessage: 'Foto tidak dapat dipilih dari galeri. Coba lagi.',
      );
      return;
    }

    if (picked == null) {
      state = ProfileEditorState(pickedImage: previous);
      return;
    }

    final validation = ImageUploadValidator.validate(
      fileName: picked.fileName,
      sizeBytes: picked.sizeBytes,
      mimeType: picked.mimeType,
    );
    if (!validation.isValid) {
      // Berkas ditolak sebelum ada unggahan: foto lama tidak terpengaruh.
      state = ProfileEditorState(
        pickedImage: previous,
        errorMessage: validation.errorMessage,
      );
      return;
    }

    state = ProfileEditorState(
      pickedImage: picked.withContentType(validation.contentType!),
    );
  }

  /// Membatalkan pilihan foto baru; foto lama tetap dipakai.
  void clearPickedPhoto() {
    if (state.isBusy) {
      return;
    }
    state = const ProfileEditorState();
  }

  /// Menghapus pesan dari percobaan sebelumnya.
  void clearMessages() {
    if (state.isBusy) {
      return;
    }
    state = ProfileEditorState(pickedImage: state.pickedImage);
  }

  /// Mengembalikan form ke keadaan awal (mis. saat layar dibuka kembali).
  void reset() => state = const ProfileEditorState();

  /// Menyimpan nama, nomor telepon, dan (bila dipilih) foto baru.
  ///
  /// Mengembalikan `true` hanya bila penyimpanan benar-benar berhasil, supaya
  /// layar tidak menutup dengan pesan sukses palsu.
  Future<bool> save({
    required String uid,
    required String displayName,
    required String phoneNumber,
    String? photoUrl,
    String? previousPhotoUrl,
  }) async {
    if (state.isBusy) {
      return false;
    }
    final picked = state.pickedImage;
    final contentType = picked?.contentType;
    if (photoUrl == null &&
        picked != null &&
        (contentType == null || contentType.isEmpty)) {
      state = ProfileEditorState(
        pickedImage: picked,
        errorMessage: 'Foto belum siap diunggah. Pilih ulang fotonya.',
      );
      return false;
    }

    state = ProfileEditorState(isSaving: true, pickedImage: picked);

    UploadedProfilePhoto? uploaded;
    try {
      if (photoUrl == null && picked != null) {
        uploaded = await _storage.upload(
          uid: uid,
          bytes: picked.bytes,
          contentType: contentType!,
        );
      }
      await _repository.updateProfile(
        uid: uid,
        displayName: displayName,
        phoneNumber: phoneNumber,
        photoUrl: photoUrl ?? uploaded?.downloadUrl,
      );
    } catch (error) {
      // Unggahan yang batal dipakai dibersihkan, sedangkan dokumen profil tidak
      // disentuh sama sekali sehingga foto lama pengguna tetap utuh.
      if (uploaded != null) {
        await _storage.deletePath(uploaded.storagePath);
      }
      state = ProfileEditorState(
        pickedImage: picked,
        errorMessage: repositoryErrorMessageFor(error, entityLabel: 'profil'),
      );
      return false;
    }

    // Foto lama hanya dihapus setelah penyimpanan berhasil; kegagalan
    // pembersihan tidak pernah mengubah hasil penyimpanan.
    final oldPhotoUrl = previousPhotoUrl?.trim() ?? '';
    if (uploaded != null && oldPhotoUrl.isNotEmpty) {
      await _storage.deleteByUrl(oldPhotoUrl);
    }

    state = const ProfileEditorState(
      noticeMessage: 'Profil berhasil disimpan.',
    );
    return true;
  }
}

/// Status layar Edit Profil.
final profileEditorProvider =
    NotifierProvider<ProfileEditor, ProfileEditorState>(ProfileEditor.new);
