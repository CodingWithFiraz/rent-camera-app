import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
