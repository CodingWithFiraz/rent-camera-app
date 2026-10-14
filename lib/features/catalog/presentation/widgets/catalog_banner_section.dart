import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/repository_error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/banner.dart';
import '../../domain/banner_selection.dart';
import '../catalog_providers.dart';
import 'banner_carousel.dart';
import 'catalog_section_notice.dart';

/// Bagian carousel banner pada halaman katalog.
///
/// Menangani sendiri keadaan memuat, gagal, dan belum dikonfigurasi supaya
/// kegagalan satu bagian tidak memblokir pencarian, filter, dan daftar produk.
/// Navigasi tidak dilakukan di sini: slide yang punya tujuan valid diteruskan
/// ke [onSlideTap] agar aturan navigasi tetap berada di screen.
class CatalogBannerSection extends ConsumerWidget {
  const CatalogBannerSection({
    super.key,
    required this.onSlideTap,
    this.autoPlayInterval = const Duration(seconds: 6),
  });

  /// Dipanggil hanya untuk slide yang tujuan navigasinya valid.
  final ValueChanged<Banner> onSlideTap;

  /// Jeda auto-play; `null` mematikan auto-play (dipakai pada test).
  final Duration? autoPlayInterval;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionAsync = ref.watch(catalogBannerSelectionProvider);
    return selectionAsync.when(
      loading: () => const _BannerLoadingPlaceholder(),
      error: (Object error, StackTrace stackTrace) => CatalogSectionNotice(
        isError: true,
        message: repositoryErrorMessageFor(error, entityLabel: 'banner'),
        onRetry: () => ref.invalidate(activeBannersProvider),
      ),
      data: (BannerSelection selection) => _BannerContent(
        selection: selection,
        onSlideTap: onSlideTap,
        autoPlayInterval: autoPlayInterval,
      ),
    );
  }
}

/// Isi bagian banner: carousel ditambah keterangan konfigurasi yang belum
/// lengkap.
///
/// Keterangan itu tidak menutupi carousel: banner yang sudah benar tetap dapat
/// dipakai, sedangkan kekurangan data dilaporkan apa adanya (bukan diisi banner
/// rekaan atau URL karangan).
class _BannerContent extends StatelessWidget {
  const _BannerContent({
    required this.selection,
    required this.onSlideTap,
    required this.autoPlayInterval,
  });

  final BannerSelection selection;
  final ValueChanged<Banner> onSlideTap;
  final Duration? autoPlayInterval;

  @override
  Widget build(BuildContext context) {
    if (selection.isEmpty) {
      return const CatalogSectionNotice(
        message:
            'Banner katalog belum dikonfigurasi admin, sehingga carousel '
            'belum dapat ditampilkan.',
      );
    }

    final notices = <String>[
      if (!selection.hasPortfolioSlide)
        'Belum ada banner yang menuju halaman Portofolio; blueprint '
            'menetapkan minimal satu banner portofolio.',
      if (selection.hasNonNavigableSlide)
        'Sebagian banner belum punya tujuan yang valid sehingga tidak dapat '
            'ditekan.',
      if (selection.ignoredCount > 0)
        '${selection.ignoredCount} banner aktif tidak ditampilkan karena '
            'carousel hanya memuat ${BannerSelection.maxSlides} slide.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BannerCarousel(
          slides: selection.slides,
          onSlideTap: onSlideTap,
          autoPlayInterval: autoPlayInterval,
        ),
        for (final message in notices) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          CatalogSectionNotice(message: message),
        ],
      ],
    );
  }
}

/// Kerangka bidang carousel saat banner masih dimuat.
///
/// Memakai rasio yang sama dengan slide sebenarnya supaya tata letak halaman
/// tidak meloncat saat data tiba.
class _BannerLoadingPlaceholder extends StatelessWidget {
  const _BannerLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: BannerCarousel.slideAspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdAll,
          // `Border.all` bukan constructor const, sehingga dekorasi ini tidak
          // dapat ditulis sebagai konstanta.
          border: Border.all(color: AppColors.border),
        ),
        child: const AppLoading(label: 'Memuat banner…'),
      ),
    );
  }
}
