import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/firebase/firebase_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hasil bootstrap diambil sebagai status, bukan dilempar sebagai error:
  // bila konfigurasi Firebase belum ada, aplikasi tetap dapat dibuka dan
  // menampilkan layar setup (lihat SETUP.md) alih-alih crash atau berpura-pura
  // autentikasi sudah aktif.
  final FirebaseBootstrapStatus bootstrapStatus =
      await FirebaseBootstrap.initialize();

  runApp(
    ProviderScope(
      overrides: [firebaseBootstrapProvider.overrideWithValue(bootstrapStatus)],
      child: const RentCameraApp(),
    ),
  );
}
