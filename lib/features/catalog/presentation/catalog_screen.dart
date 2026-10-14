import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/repository_error_mapper.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/external_launcher.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../domain/banner.dart';
import '../domain/category.dart';
import 'catalog_drawer.dart';
import 'catalog_providers.dart';
import 'widgets/catalog_app_bar_actions.dart';
import 'widgets/catalog_banner_section.dart';
import 'widgets/catalog_filter_bar.dart';
import 'widgets/catalog_products_section.dart';
import 'widgets/catalog_search_field.dart';
import 'widgets/catalog_section_notice.dart';

/// Halaman Catalog/Home (`docs/BLUEPRINT_APLIKASI.md` §4 dan §5).
///
/// Halaman pertama setelah login. Seluruh data dibaca lewat provider katalog
/// (stream Firestore di repository), sehingga perubahan admin tercermin tanpa
/// memuat ulang aplikasi. Halaman ini juga pemilik kriteria pencarian/filter:
/// satu `catalogFilterProvider` dipakai bersama oleh kolom pencarian, chip
/// filter, dan drawer kategori.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Kata kunci awal diambil dari provider: membuka kembali halaman katalog
    // tidak menghapus pencarian yang masih aktif.
    _searchController = TextEditingController(
      text: ref.read(catalogFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String value) =>
      ref.read(catalogFilterProvider.notifier).setQuery(value);

  void _handleClearSearch() {
    _searchController.clear();
    ref.read(catalogFilterProvider.notifier).setQuery('');
  }

  /// Mengembalikan katalog ke keadaan tanpa kriteria.
  ///
  /// Kolom pencarian ikut dikosongkan supaya teks di layar tidak menyimpang
  /// dari kriteria yang benar-benar dipakai.
  void _handleResetFilters() {
    _searchController.clear();
    ref.read(catalogFilterProvider.notifier).reset();
  }

  /// Menjalankan aksi banner sesuai `targetType` dokumennya.
  ///
  /// Slide tanpa tujuan valid tidak pernah sampai ke sini: carousel
  /// menampilkannya sebagai bidang yang tidak dapat ditekan. URL eksternal
  /// tidak dikarang — nilainya berasal dari dokumen banner dan divalidasi
  /// [ExternalLauncher] sebelum dibuka.
  void _handleBannerTap(Banner banner) {
    switch (banner.targetType) {
      case BannerTargetType.portfolio:
        context.push(AppRoutes.portfolio);
      case BannerTargetType.category:
        ref
            .read(catalogFilterProvider.notifier)
            .selectCategory(banner.targetValue);
      case BannerTargetType.externalUrl:
        _openBannerLink(banner.targetValue);
      case BannerTargetType.unknown:
        break;
    }
  }

  Future<void> _openBannerLink(String rawUrl) async {
    // Messenger diambil sebelum `await` supaya hasilnya tetap dapat dilaporkan
    // walau halaman sudah dibangun ulang.
    final messenger = ScaffoldMessenger.of(context);
    final status = await const ExternalLauncher().open(rawUrl);
    final message = _bannerLinkMessage(status);
    if (message == null) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  /// Pesan untuk hasil pembukaan tautan banner; `null` berarti tanpa pesan.
  static String? _bannerLinkMessage(ExternalLaunchStatus status) {
    switch (status) {
      case ExternalLaunchStatus.launched:
        return null;
      case ExternalLaunchStatus.copiedToClipboard:
        return 'Tautan banner disalin ke clipboard karena tidak ada aplikasi '
            'yang dapat membukanya.';
      case ExternalLaunchStatus.invalidUrl:
        return 'Tautan banner belum valid sehingga tidak dapat dibuka.';
      case ExternalLaunchStatus.failed:
        return 'Tautan banner tidak dapat dibuka. Coba lagi nanti.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(catalogFilterProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final categories = categoriesAsync.value ?? const <Category>[];
    final brands = ref.watch(catalogBrandsProvider);
    final filterNotifier = ref.read(catalogFilterProvider.notifier);

    return AppScaffold(
      drawer: const CatalogDrawer(),
      actions: const <Widget>[CatalogAppBarActions()],
      body: ListView(
        padding: AppSpacing.screen,
        children: <Widget>[
          CatalogBannerSection(onSlideTap: _handleBannerTap),
          const SizedBox(height: AppSpacing.xl),
          CatalogSearchField(
            controller: _searchController,
            onChanged: _handleSearchChanged,
            onClear: _handleClearSearch,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildCategoryNotice(categoriesAsync),
          CatalogFilterBar(
            categories: categories,
            brands: brands,
            filter: filter,
            onSelectCategory: filterNotifier.selectCategory,
            onSelectBrand: filterNotifier.selectBrand,
            onReset: _handleResetFilters,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Katalog alat', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          CatalogProductsSection(
            onOpenProduct: (product) =>
                context.push(AppRoutes.productDetailPath(product.id)),
            onResetFilters: _handleResetFilters,
          ),
        ],
      ),
    );
  }

  /// Keterangan keadaan kategori (memuat, gagal, atau belum dikonfigurasi).
  ///
  /// Chip kategori berasal dari Firestore, jadi UI wajib jujur saat daftar itu
  /// belum ada; bagian lain halaman tetap dapat dipakai dan punya tombol
  /// pemulihan sendiri.
  Widget _buildCategoryNotice(AsyncValue<List<Category>> categoriesAsync) {
    if (categoriesAsync.isLoading && !categoriesAsync.hasValue) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: CatalogSectionNotice(message: 'Memuat kategori…'),
      );
    }
    if (categoriesAsync.hasError && !categoriesAsync.hasValue) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: CatalogSectionNotice(
          isError: true,
          message: repositoryErrorMessageFor(
            categoriesAsync.error,
            entityLabel: 'kategori',
          ),
          onRetry: () => ref.invalidate(activeCategoriesProvider),
        ),
      );
    }
    if (categoriesAsync.hasValue && (categoriesAsync.value?.isEmpty ?? true)) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: CatalogSectionNotice(
          message:
              'Kategori belum dikonfigurasi admin, sehingga filter '
              'kategori belum tersedia.',
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
