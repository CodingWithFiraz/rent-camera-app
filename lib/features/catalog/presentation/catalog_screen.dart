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
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  late final TextEditingController _searchController;

  // Inisialisasi langsung tanpa 'late' untuk mencegah LateInitializationError secara total
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(catalogFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleSearchChanged(String value) =>
      ref.read(catalogFilterProvider.notifier).setQuery(value);

  void _handleClearSearch() {
    _searchController.clear();
    ref.read(catalogFilterProvider.notifier).setQuery('');
  }

  void _handleResetFilters() {
    _searchController.clear();
    ref.read(catalogFilterProvider.notifier).reset();
  }

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
    final messenger = ScaffoldMessenger.of(context);
    final status = await const ExternalLauncher().open(rawUrl);
    final message = _bannerLinkMessage(status);
    if (message == null) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

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
        controller: _scrollController,
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
          const SizedBox(height: AppSpacing.xl),
          const CatalogFaqSection(),
          const SizedBox(height: AppSpacing.xl),
          CatalogFooterSection(onScrollToTop: _scrollToTop),
        ],
      ),
    );
  }

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

/// Widget tambahan untuk menampilkan FAQ / QnA di halaman katalog.
class CatalogFaqSection extends StatelessWidget {
  const CatalogFaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    const Color charcoalText = Color(0xFF1E1E1E);
    const Color limeGreenBox = Color(0xFFBCEE46);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: limeGreenBox.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: limeGreenBox),
      ),
      child: Material(
        // `Material` transparan menjaga efek ketuk `ExpansionTile` tetap terlihat:
        // tanpa lapisan ini, `ListTile` di dalam `DecoratedBox` berwarna akan
        // memicu assertion Flutter dan riak ketukan tidak tampil.
        type: MaterialType.transparency,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pertanyaan Sering Diajukan (FAQ)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: charcoalText,
              ),
            ),
            SizedBox(height: 12),
            ExpansionTile(
              title: Text(
                'Bagaimana cara menyewa kamera?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: charcoalText,
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Pilih alat yang diinginkan dari katalog, masukkan ke keranjang, lalu ikuti instruksi pengiriman formulir sewa.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: Text(
                'Apa saja syarat dokumen penyewaan?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: charcoalText,
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Biasanya memerlukan kartu identitas (KTP/KTM) yang masih berlaku sebagai jaminan pelajar maupun umum.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget Footer (Copyright 2026 di Kiri, Tombol Scroll ke Atas di Kanan)
/// Widget Footer (Copyright 2026 di Tengah, Tombol Scroll ke Atas di Kanan)
class CatalogFooterSection extends StatelessWidget {
  final VoidCallback onScrollToTop;

  const CatalogFooterSection({super.key, required this.onScrollToTop});

  @override
  Widget build(BuildContext context) {
    const Color charcoalText = Color(0xFF1E1E1E);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Spacer penyeimbang di sisi kiri agar teks copyright benar-benar berada di tengah
          const Spacer(),

          // Bagian Tengah: Copyright 2026 (Rata Tengah)
          const Expanded(
            flex: 2,
            child: Text(
              '© Copyright 2026, Rent Camera App',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: charcoalText,
              ),
            ),
          ),

          // Sisi Kanan: Tombol Scroll ke Atas
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: onScrollToTop,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: charcoalText,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
