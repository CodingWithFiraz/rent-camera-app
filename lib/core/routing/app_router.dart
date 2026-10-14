import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/upcoming_feature_screen.dart';
import '../../features/auth/presentation/auth_gate.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/firebase_setup_required_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/catalog/presentation/catalog_screen.dart';
import '../../features/catalog/presentation/product_detail_screen.dart';
import '../firebase/firebase_providers.dart';
import '../widgets/app_error_state.dart';
import 'app_routes.dart';
import 'auth_guard.dart';

/// Router aplikasi beserta route guard autentikasi.
///
/// Redirect dihitung oleh [resolveAuthRedirect] dan router menyegarkan diri
/// lewat [AuthSessionNotifier] (`refreshListenable`), sehingga perubahan sesi
/// langsung memindahkan pengguna antara route auth dan route terproteksi.
final goRouterProvider = Provider<GoRouter>((ref) {
  final bootstrapStatus = ref.watch(firebaseBootstrapProvider);
  final session = ref.watch(authSessionNotifierProvider);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: session,
    redirect: (BuildContext context, GoRouterState state) =>
        resolveAuthRedirect(
          location: state.matchedLocation,
          isFirebaseConfigured: bootstrapStatus.isConfigured,
          sessionStatus: session.status,
        ),
    errorBuilder: (BuildContext context, GoRouterState state) =>
        const _RouteNotFoundScreen(),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) =>
            const AuthGate(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (BuildContext context, GoRouterState state) =>
            const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (BuildContext context, GoRouterState state) =>
            const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupRequired,
        name: 'setupRequired',
        builder: (BuildContext context, GoRouterState state) =>
            const FirebaseSetupRequiredScreen(),
      ),
      GoRoute(
        path: AppRoutes.catalog,
        name: 'catalog',
        builder: (BuildContext context, GoRouterState state) =>
            const CatalogScreen(),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        name: 'productDetail',
        builder: (BuildContext context, GoRouterState state) =>
            ProductDetailScreen(
              productId: state.pathParameters['productId'] ?? '',
            ),
      ),
      GoRoute(
        path: AppRoutes.cart,
        name: 'cart',
        builder: (BuildContext context, GoRouterState state) =>
            const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.portfolio,
        name: 'portfolio',
        builder: (BuildContext context, GoRouterState state) =>
            const UpcomingFeatureScreen(
              title: 'Portofolio & Layanan',
              phaseLabel: 'Fase 5 — Portofolio, Rate Card & Profil',
              message:
                  'Rate card layanan dan kartu kreator belum dibangun, '
                  'sehingga halaman ini belum menampilkan data apa pun.',
            ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (BuildContext context, GoRouterState state) =>
            const UpcomingFeatureScreen(
              title: 'Profil',
              phaseLabel: 'Fase 5 — Portofolio, Rate Card & Profil',
              message:
                  'Pengaturan nama, nomor telepon, dan foto profil belum '
                  'dibangun.',
            ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

/// Halaman yang tampil bila route tidak dikenal.
class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const AppErrorState(
        title: 'Halaman tidak ditemukan',
        message: 'Alamat yang dituju tidak tersedia pada aplikasi ini.',
      ),
    );
  }
}
