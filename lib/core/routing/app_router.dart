import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/domain/admin_guard.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_providers.dart';
import '../../features/admin/presentation/product_form_screen.dart';
import '../../features/auth/presentation/auth_gate.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/firebase_setup_required_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/catalog/presentation/catalog_screen.dart';
import '../../features/catalog/presentation/product_detail_screen.dart';
import '../../features/portfolio/presentation/portfolio_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../firebase/firebase_providers.dart';
import '../widgets/app_error_state.dart';
import 'app_routes.dart';
import 'auth_guard.dart';

/// Router aplikasi beserta route guard autentikasi dan admin.
///
/// Redirect dihitung oleh [resolveAuthRedirect] lalu [resolveAdminRedirect], dan
/// router menyegarkan diri lewat `refreshListenable` berisi [AuthSessionNotifier]
/// dan [AdminAccessNotifier], sehingga perubahan sesi maupun perubahan claim
/// admin langsung memindahkan pengguna antara route auth, katalog, dan area
/// admin.
final goRouterProvider = Provider<GoRouter>((ref) {
  final bootstrapStatus = ref.watch(firebaseBootstrapProvider);
  final session = ref.watch(authSessionNotifierProvider);
  final adminAccess = ref.watch(adminAccessNotifierProvider);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: Listenable.merge(<Listenable>[session, adminAccess]),
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.matchedLocation;
      final authRedirect = resolveAuthRedirect(
        location: location,
        isFirebaseConfigured: bootstrapStatus.isConfigured,
        sessionStatus: session.status,
      );
      if (authRedirect != null) {
        return authRedirect;
      }
      return resolveAdminRedirect(
        location: location,
        access: adminAccess.status,
      );
    },
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
            const PortfolioScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (BuildContext context, GoRouterState state) =>
            const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        builder: (BuildContext context, GoRouterState state) =>
            const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin',
        builder: (BuildContext context, GoRouterState state) =>
            const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminProductNew,
        name: 'adminProductNew',
        builder: (BuildContext context, GoRouterState state) =>
            const ProductFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminProductEdit,
        name: 'adminProductEdit',
        builder: (BuildContext context, GoRouterState state) =>
            ProductFormScreen(productId: state.pathParameters['productId'] ?? ''),
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
