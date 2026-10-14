import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../admin/presentation/admin_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../cart/presentation/cart_providers.dart';
import '../domain/catalog_filter.dart';
import '../domain/category.dart';
import 'catalog_providers.dart';
import 'category_icons.dart';

/// Drawer navigasi untuk halaman katalog.
///
/// Isinya mengikuti blueprint: seluruh kategori aktif, halaman Portofolio,
/// Keranjang, dan Profil. Kategori diambil dari stream Firestore, bukan daftar
/// hardcoded, sehingga memilih kategori dari sini langsung mengubah filter
/// katalog di provider yang sama dengan chip filter.
///
/// Halaman detail produk sengaja tidak memakai drawer ini: app bar-nya memakai
/// tombol kembali supaya pengguna tidak terjebak pada halaman yang dibuka
/// dengan `push`.
///
/// Entri "Dashboard Admin" hanya muncul saat `AdminAccessNotifier` melaporkan
/// status `granted`, yaitu ketika custom claim `{admin: true}` benar-benar
/// terbaca dari ID token. Menyembunyikan entri bukan pengamanan: route guard dan
/// Firestore/Storage rules tetap menolak akses tanpa claim tersebut.
class CatalogDrawer extends ConsumerWidget {
  const CatalogDrawer({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    // Kedua objek diambil sebelum drawer ditutup agar pesan error tetap dapat
    // ditampilkan setelah drawer hilang.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    navigator.pop();
    await ref.read(authControllerProvider.notifier).signOut();
    final message = ref.read(authControllerProvider).errorMessage;
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authSessionNotifierProvider);
    final adminAccess = ref.watch(adminAccessNotifierProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final filter = ref.watch(catalogFilterProvider);
    final isSubmitting = ref.watch(authControllerProvider).isSubmitting;
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    final filterNotifier = ref.read(catalogFilterProvider.notifier);
    final categories = categoriesAsync.value ?? const <Category>[];

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[session, adminAccess]),
      builder: (BuildContext context, Widget? _) {
        final user = session.user;
        final itemCount = ref.watch(cartItemCountProvider(user?.uid ?? ''));
        final email = user?.email;

        return AppDrawer(
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(AppConfig.appName, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                user?.preferredName ?? 'Pengguna',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              if (email != null)
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          entries: _entries(
            categories: categories,
            categoriesAsync: categoriesAsync,
            filter: filter,
            itemCount: itemCount,
            navigator: navigator,
            filterNotifier: filterNotifier,
            router: router,
            showAdmin: adminAccess.isGranted,
          ),
          footer: _footer(
            ref: ref,
            categoriesAsync: categoriesAsync,
            isSubmitting: isSubmitting,
            onSignOut: () => _signOut(context, ref),
          ),
        );
      },
    );
  }

  /// Entri navigasi: kategori aktif, lalu halaman utama aplikasi.
  ///
  /// Setiap entri menutup drawer lebih dulu (`navigator.pop`) supaya drawer
  /// tidak menutupi halaman tujuan.
  List<AppDrawerEntry> _entries({
    required List<Category> categories,
    required AsyncValue<List<Category>> categoriesAsync,
    required CatalogFilter filter,
    required int itemCount,
    required NavigatorState navigator,
    required CatalogFilterNotifier filterNotifier,
    required GoRouter router,
    required bool showAdmin,
  }) {
    void closeThen(VoidCallback action) {
      navigator.pop();
      action();
    }

    return <AppDrawerEntry>[
      AppDrawerEntry(
        label: 'Semua kategori',
        icon: Icons.grid_view_outlined,
        isSelected: !filter.hasCategory,
        onTap: () => closeThen(() => filterNotifier.selectCategory(null)),
      ),
      for (final category in categories)
        AppDrawerEntry(
          label: category.name,
          icon: CategoryIcons.forKey(category.resolvedIconKey),
          isSelected: filter.categoryId == category.id,
          onTap: () =>
              closeThen(() => filterNotifier.selectCategory(category.id)),
        ),
      if (categoriesAsync.isLoading && !categoriesAsync.hasValue)
        const AppDrawerEntry(
          label: 'Memuat kategori…',
          icon: Icons.hourglass_empty_outlined,
          onTap: null,
        ),
      if (categoriesAsync.hasError)
        const AppDrawerEntry(
          label: 'Kategori belum dapat dimuat',
          icon: Icons.error_outline,
          onTap: null,
        ),
      AppDrawerEntry(
        label: 'Portofolio & Layanan',
        icon: Icons.photo_library_outlined,
        onTap: () => closeThen(() => router.push(AppRoutes.portfolio)),
      ),
      AppDrawerEntry(
        label: 'Keranjang',
        icon: Icons.shopping_bag_outlined,
        badgeCount: itemCount,
        onTap: () => closeThen(() => router.push(AppRoutes.cart)),
      ),
      AppDrawerEntry(
        label: 'Profil',
        icon: Icons.person_outline,
        onTap: () => closeThen(() => router.push(AppRoutes.profile)),
      ),
      // Hanya tampil untuk admin terverifikasi. Route guard tetap menolak
      // akses langsung ke `/admin` tanpa claim, jadi entri ini murni petunjuk
      // navigasi, bukan kontrol keamanan.
      if (showAdmin)
        AppDrawerEntry(
          label: 'Dashboard admin',
          icon: Icons.admin_panel_settings_outlined,
          onTap: () => closeThen(() => router.push(AppRoutes.admin)),
        ),
    ];
  }

  /// Bagian bawah drawer: pemulihan kategori yang gagal dimuat dan tombol keluar.
  ///
  /// Tombol "Muat ulang kategori" hanya muncul saat stream kategori berakhir
  /// error, sehingga tidak ada tombol yang tidak melakukan apa pun.
  Widget _footer({
    required WidgetRef ref,
    required AsyncValue<List<Category>> categoriesAsync,
    required bool isSubmitting,
    required VoidCallback onSignOut,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (categoriesAsync.hasError) ...<Widget>[
          TextButton.icon(
            onPressed: () => ref.invalidate(activeCategoriesProvider),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Muat ulang kategori'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        OutlinedButton(
          onPressed: isSubmitting ? null : onSignOut,
          child: Text(isSubmitting ? 'Keluar…' : 'Keluar'),
        ),
      ],
    );
  }
}
