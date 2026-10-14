import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../data/profile_image_picker.dart';
import '../data/profile_photo_storage.dart';
import '../data/user_profile_repository.dart';
import '../domain/user_profile.dart';

/// Akses dokumen `users/{uid}` (`docs/BLUEPRINT_APLIKASI.md` §6.3).
///
/// Provider ini juga dipakai `authRepositoryProvider` untuk menyinkronkan
/// dokumen profil saat register/login, sehingga hanya ada satu pintu akses.
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepository(ref.watch(firebaseFirestoreProvider)),
);

/// Profil pengguna realtime berdasarkan UID.
///
/// `null` berarti dokumen `users/{uid}` belum ada (misalnya rules belum
/// dideploy saat register) atau UID belum tersedia. UI wajib menampilkan
/// keadaan kosong/konfigurasi, bukan profil rekaan.
final userProfileProvider = StreamProvider.family<UserProfile?, String>(
  (ref, uid) => ref.watch(userProfileRepositoryProvider).watchProfile(uid),
);

/// Penyimpanan foto profil pada `profiles/{uid}/**` (blueprint §10).
///
/// Memakai bucket Storage project; bila Storage belum aktif atau Storage Rules
/// belum dideploy, unggahan gagal dengan pesan yang sudah dipetakan.
final profilePhotoStorageProvider = Provider<ProfilePhotoStorage>(
  (ref) => FirebaseProfilePhotoStorage(ref.watch(firebaseStorageProvider)),
);

/// Pemilih foto dari galeri.
///
/// Disediakan sebagai provider supaya test dapat memakai pemilih palsu: tidak
/// ada platform channel `image_picker` yang dipanggil saat pengujian.
final profileImagePickerProvider = Provider<ProfileImagePicker>(
  (ref) => ImagePickerProfileImagePicker(),
);
