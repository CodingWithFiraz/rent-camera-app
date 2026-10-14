import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
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
