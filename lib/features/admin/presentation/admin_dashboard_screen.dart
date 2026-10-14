import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/repository_error_mapper.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_form_banner.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../catalog/domain/category.dart';
import '../../catalog/domain/product.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../domain/admin_access.dart';
import '../domain/admin_product_filter.dart';
import 'admin_product_actions.dart';
import 'admin_providers.dart';
import 'widgets/admin_product_list_tile.dart';

/// Dashboard admin (`docs/BLUEPRINT_APLIKASI.md` §8): jumlah produk nyata,
/// pencarian/filter, daftar produk aktif dan arsip, serta aksi
/// tambah/edit/arsip/pulihkan.
///
/// Data produk hanya dimuat setelah custom claim `admin: true` terverifikasi.
/// Selama status akses belum diketahui, layar menampilkan keadaan memuat dan
/// tidak menjalankan aksi tulis apa pun. Bila akses ditolak, route guard sudah
/// memindahkan pengguna ke katalog (lihat `resolveAdminRedirect`).
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(adminProductFilterProvider).query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(adminAccessNotifierProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final filter = ref.watch(adminProductFilterProvider);

    return AppScaffold(
      title: 'Dashboard Admin',
      leading: IconButton(
        tooltip: 'Kembali ke katalog',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(AppRoutes.catalog),
      ),
      body: ListenableBuilder(
        listenable: access,
        builder: (BuildContext context, Widget? _) => switch (access.status) {
          AdminAccessStatus.unknown => const AppLoading(),
          AdminAccessStatus.denied => _AccessDeniedView(
            onRetry: () => access.refresh(),
          ),
          AdminAccessStatus.granted => _buildContent(
            categoriesAsync: categoriesAsync,
            filter: filter,
          ),
        },
      ),
    );
  }

  Widget _buildContent({
    required AsyncValue<List<Category>> categoriesAsync,
    required AdminProductFilter filter,
  }) {
    final productsAsync = ref.watch(adminVisibleProductsProvider);
    final summary = ref.watch(adminProductSummaryProvider);
    final actions = ref.watch(adminProductActionsProvider);
    final categories = categoriesAsync.value ?? const <Category>[];

    return ListView(
      padding: AppSpacing.screen,
      children: <Widget>[
        _SummaryHeader(summary: summary),
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: 'Tambah Alat',
          icon: Icons.add,
          onPressed: () => context.push(AppRoutes.adminProductNew),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!categoriesAsync.isLoading && categories.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppFormBanner.notice(
              'Belum ada kategori pada collection "categories". Buat kategori '
              'lebih dulu (lihat SETUP.md): produk tidak dapat disimpan tanpa '
              'kategori, dan aplikasi tidak membuat kategori otomatis.',
            ),
          ),
        if (actions.errorMessage case final String message)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppFormBanner.error(message),
          ),
        TextField(
          controller: _searchController,
          onChanged: (String value) =>
              ref.read(adminProductFilterProvider.notifier).setQuery(value),
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            labelText: 'Cari produk',
            hintText: 'Nama, brand, atau ID kategori',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final visibility in AdminProductVisibility.values)
              ChoiceChip(
                label: Text(_visibilityLabel(visibility, summary)),
                selected: filter.visibility == visibility,
                onSelected: (bool _) => ref
                    .read(adminProductFilterProvider.notifier)
                    .setVisibility(visibility),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._productSection(
          productsAsync: productsAsync,
          filter: filter,
          actions: actions,
        ),
      ],
    );
  }

  /// Bagian daftar produk: memuat, error, kosong, atau daftar produk.
  List<Widget> _productSection({
    required AsyncValue<List<Product>> productsAsync,
    required AdminProductFilter filter,
    required AdminProductActionsState actions,
  }) {
    if (productsAsync.isLoading && !productsAsync.hasValue) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: AppLoading(),
        ),
      ];
    }
    if (productsAsync.hasError) {
      return <Widget>[
        AppErrorState(
          title: 'Daftar produk tidak dapat dimuat',
          message: repositoryErrorMessageFor(
            productsAsync.error,
            entityLabel: 'produk',
          ),
          onRetry: () => ref.invalidate(adminProductsProvider),
        ),
      ];
    }

    final products = productsAsync.value ?? const <Product>[];
    if (products.isEmpty) {
      return <Widget>[
        AppEmptyState(
          icon: Icons.inventory_2_outlined,
          title: filter.isFiltering
              ? 'Tidak ada produk yang cocok'
              : 'Belum ada produk',
          message: filter.isFiltering
              ? 'Ubah kata kunci atau filter status untuk melihat produk lain.'
              : 'Tambahkan alat pertama lewat tombol "Tambah Alat".',
        ),
      ];
    }

    return <Widget>[
      for (final product in products)
        AdminProductListTile(
          product: product,
          categoryName: ref.watch(categoryNameProvider(product.categoryId)),
          isBusy: actions.busyProductId == product.id,
          onEdit: () =>
              context.push(AppRoutes.adminProductEditPath(product.id)),
          onToggleActive: () => _toggleActive(product),
        ),
    ];
  }

  /// Mengarsipkan (dengan konfirmasi) atau memulihkan produk.
  ///
  /// Snackbar hanya muncul setelah Firestore menjawab, dan isinya berasal dari
  /// hasil operasi nyata — bukan sukses yang diasumsikan.
  Future<void> _toggleActive(Product product) async {
    if (product.isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Arsipkan produk ini?'),
          content: Text(
            '${product.name} tidak akan tampil di katalog. Foto tetap tersimpan '
            'dan produk dapat dipulihkan kapan saja.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Arsipkan'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }

    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await ref
        .read(adminProductActionsProvider.notifier)
        .setActive(productId: product.id, isActive: !product.isActive);
    messenger.showSnackBar(SnackBar(content: Text(outcome.message)));
  }

  /// Label chip filter, disertai jumlah produk nyata bila data sudah terbaca.
  String _visibilityLabel(
    AdminProductVisibility visibility,
    AdminProductSummary? summary,
  ) {
    final String label;
    final int? count;
    switch (visibility) {
      case AdminProductVisibility.all:
        label = 'Semua';
        count = summary?.total;
      case AdminProductVisibility.active:
        label = 'Aktif';
        count = summary?.active;
      case AdminProductVisibility.archived:
        label = 'Arsip';
        count = summary?.archived;
    }
    return count == null ? label : '$label ($count)';
  }
}

/// Ringkasan jumlah produk pada header dashboard.
///
/// Angka berasal dari dokumen produk yang benar-benar terbaca; selama data belum
/// tersedia ditampilkan tanda "—", bukan angka nol atau grafik karangan.
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary});

  final AdminProductSummary? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = summary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Kelola alat', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Perubahan di sini langsung terlihat di katalog pelanggan karena '
            'katalog membaca Firestore lewat stream realtime.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _Metric(label: 'Total produk', value: data?.total),
              ),
              Expanded(
                child: _Metric(label: 'Aktif', value: data?.active),
              ),
              Expanded(
                child: _Metric(label: 'Arsip', value: data?.archived),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Satu angka ringkasan; `null` berarti datanya belum terbaca.
class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(value?.toString() ?? '—', style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// Keadaan akses ditolak: hanya terlihat bila halaman admin dibuka tanpa claim
/// `admin: true` (mis. route guard dilewati atau claim dicabut sesudahnya).
class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: 'Akses admin diperlukan',
      message:
          'Akun ini tidak memiliki custom claim "admin: true" pada ID token, '
          'sehingga dashboard admin tidak dapat dibuka. Minta pemilik project '
          'memberikan claim memakai scripts/grant_admin.mjs, lalu pilih '
          '"Periksa ulang".',
      onRetry: onRetry,
      retryLabel: 'Periksa ulang',
    );
  }
}
