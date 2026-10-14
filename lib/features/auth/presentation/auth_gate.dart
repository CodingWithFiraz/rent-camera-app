import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../core/routing/auth_guard.dart';
import '../../../core/widgets/app_loading.dart';
import 'auth_providers.dart';
import 'firebase_setup_required_screen.dart';

/// Auth gate: layar awal yang membaca status sesi dan konfigurasi Firebase.
///
/// Keputusan navigasi dijalankan oleh `resolveAuthRedirect` melalui `go_router`
/// (lihat `core/routing/app_router.dart`), sehingga layar ini hanya menampilkan
/// status pemuatan selama sesi belum diketahui. Tidak ada route terproteksi yang
/// dapat dibuka tanpa login karena guard bersifat default-deny.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapStatus = ref.watch(firebaseBootstrapProvider);
    if (!bootstrapStatus.isConfigured) {
      return const FirebaseSetupRequiredScreen();
    }

    final session = ref.watch(authSessionNotifierProvider);
    final label = session.status == AuthSessionStatus.signedIn
        ? 'Menyiapkan katalog…'
        : 'Memuat sesi…';

    return Scaffold(body: AppLoading(label: label));
  }
}
