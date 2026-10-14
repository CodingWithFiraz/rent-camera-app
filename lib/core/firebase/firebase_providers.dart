import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_bootstrap.dart';

/// Status bootstrap Firebase; dioverride di `main()` dengan hasil
/// [FirebaseBootstrap.initialize].
///
/// Membaca provider ini tanpa override akan melempar [StateError] supaya entry
/// point yang salah gagal cepat, bukan diam-diam menganggap Firebase siap.
final firebaseBootstrapProvider = Provider<FirebaseBootstrapStatus>(
  (ref) => throw StateError(
    'firebaseBootstrapProvider harus dioverride di main() atau di test.',
  ),
);

/// Instance `FirebaseAuth`.
///
/// Melempar [StateError] bila Firebase belum dikonfigurasi; pemanggil harus
/// memeriksa [firebaseBootstrapProvider] lebih dulu.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  if (!ref.watch(firebaseBootstrapProvider).isConfigured) {
    throw StateError(
      'Firebase Auth belum tersedia: konfigurasi Firebase belum ada (lihat SETUP.md).',
    );
  }
  return FirebaseAuth.instance;
});

/// Instance `FirebaseFirestore` dengan aturan yang sama seperti
/// [firebaseAuthProvider].
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  if (!ref.watch(firebaseBootstrapProvider).isConfigured) {
    throw StateError(
      'Cloud Firestore belum tersedia: konfigurasi Firebase belum ada (lihat SETUP.md).',
    );
  }
  return FirebaseFirestore.instance;
});

/// Instance `FirebaseStorage` dengan aturan yang sama seperti
/// [firebaseAuthProvider].
///
/// Dipakai menyimpan foto profil ke `profiles/{uid}/**` (blueprint §10). Bucket
/// Storage harus benar-benar aktif pada project Firebase; bila belum, unggahan
/// gagal dengan pesan yang sudah dipetakan, bukan klaim berhasil.
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  if (!ref.watch(firebaseBootstrapProvider).isConfigured) {
    throw StateError(
      'Firebase Storage belum tersedia: konfigurasi Firebase belum ada (lihat SETUP.md).',
    );
  }
  return FirebaseStorage.instance;
});
