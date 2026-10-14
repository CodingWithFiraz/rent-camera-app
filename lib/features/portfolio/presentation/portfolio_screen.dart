import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/repository_error_mapper.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/external_launcher.dart';
import '../../../core/utils/external_url.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../cart/presentation/cart_providers.dart';
import '../../catalog/presentation/widgets/catalog_app_bar_actions.dart';
import '../../catalog/presentation/widgets/catalog_section_notice.dart';
import '../domain/creative.dart';
import '../domain/service_rate.dart';
import 'portfolio_providers.dart';
import 'widgets/creative_card.dart';
import 'widgets/service_rate_card.dart';

/// Halaman Portofolio & Layanan (`docs/BLUEPRINT_APLIKASI.md` §4 dan §6.6–6.7).
///
/// Seluruh isi halaman berasal dari Firestore lewat [activeServiceRatesProvider]
/// dan [activeCreativesProvider]: empat kelompok layanan beserta rate card dan
/// kartu kreator dengan tautan portofolio. Tidak ada rate, foto, atau pengalaman
/// kreator yang dikarang di widget; bila dokumennya belum diisi, halaman
/// menampilkan keadaan belum dikonfigurasi.
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  /// Id kreator yang tautannya sedang dibuka; `null` berarti tidak ada.
  String? _openingCreativeId;

  /// Jumlah kelompok layanan yang diminta blueprint §6.6.
  static const int expectedServiceRateCount = 4;

  /// Jumlah kartu kreator yang diminta blueprint §6.7.
  static const int expectedCreativeCount = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Portofolio & Layanan',
      leading: BackButton(onPressed: _back),
      actions: const <Widget>[CatalogAppBarActions()],
      body: ListView(
        padding: AppSpacing.screen,
        children: <Widget>[
          Text(
            'Halaman ini menampilkan kelompok jasa beserta rate card-nya dan '
            'kartu kreator dengan tautan portofolio. Seluruh isinya berasal dari '
            'data yang dikonfigurasi pemilik aplikasi.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Kelompok layanan', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          const _ServiceRatesSection(),
          const SizedBox(height: AppSpacing.xl),
          Text('Kreator', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _CreativesSection(
            openingCreativeId: _openingCreativeId,
            onOpenPortfolio: _openPortfolio,
          ),
        ],
      ),
    );
  }

  /// Kembali ke katalog; tetap bekerja bila halaman dibuka tanpa riwayat.
  void _back() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.catalog);
  }

  /// Membuka tautan portofolio kreator lewat aplikasi lain (`url_launcher`).
  ///
  /// URL divalidasi [ExternalUrl] (hanya `http`/`https`) walau tombolnya sudah
  /// dinonaktifkan saat URL tidak valid, dan kegagalan tidak pernah dilaporkan
  /// sebagai keberhasilan.
  Future<void> _openPortfolio(Creative creative) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = creative.portfolioUrl.trim();
    if (!ExternalUrl.isValid(url)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Tautan portofolio belum valid sehingga tidak dapat dibuka.',
          ),
        ),
      );
      return;
    }

    setState(() => _openingCreativeId = creative.id);
    try {
      final status = await ref.read(externalLauncherProvider).open(url);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(_launchMessage(creative.name, status))),
      );
    } finally {
      if (mounted) {
        setState(() => _openingCreativeId = null);
      }
    }
  }

  /// Kalimat hasil pembukaan tautan; kegagalan tidak dilaporkan sebagai sukses.
  static String _launchMessage(
    String creativeName,
    ExternalLaunchStatus status,
  ) {
    switch (status) {
      case ExternalLaunchStatus.launched:
        return 'Portofolio $creativeName dibuka di aplikasi lain.';
      case ExternalLaunchStatus.copiedToClipboard:
        return 'Tautan portofolio $creativeName disalin ke clipboard karena '
            'tidak ada aplikasi yang dapat membukanya.';
      case ExternalLaunchStatus.invalidUrl:
        return 'Tautan portofolio $creativeName belum valid sehingga tidak '
            'dapat dibuka.';
      case ExternalLaunchStatus.failed:
        return 'Tautan portofolio $creativeName tidak dapat dibuka. Coba lagi '
            'nanti.';
    }
  }
}

/// Daftar rate card layanan aktif beserta state loading/error/empty-nya.
class _ServiceRatesSection extends ConsumerWidget {
  const _ServiceRatesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratesAsync = ref.watch(activeServiceRatesProvider);

    if (ratesAsync.isLoading && !ratesAsync.hasValue) {
      return const AppLoading(label: 'Memuat rate card…');
    }
    if (ratesAsync.hasError && !ratesAsync.hasValue) {
      return AppErrorState(
        title: 'Rate card belum dapat dimuat',
        message: repositoryErrorMessageFor(
          ratesAsync.error,
          entityLabel: 'rate card',
        ),
        onRetry: () => ref.invalidate(activeServiceRatesProvider),
      );
    }

    final rates = ratesAsync.value ?? const <ServiceRate>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (ratesAsync.hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: CatalogSectionNotice(
              isError: true,
              message: repositoryErrorMessageFor(
                ratesAsync.error,
                entityLabel: 'rate card',
              ),
              onRetry: () => ref.invalidate(activeServiceRatesProvider),
            ),
          ),
        if (rates.isEmpty)
          const AppEmptyState(
            icon: Icons.design_services_outlined,
            title: 'Rate card belum dikonfigurasi',
            message:
                'Pemilik aplikasi belum mengisi kelompok layanan, sehingga '
                'belum ada judul, rate, atau hasil pekerjaan yang dapat '
                'ditampilkan.',
          )
        else ...<Widget>[
          if (rates.length != _PortfolioScreenState.expectedServiceRateCount)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: CatalogSectionNotice(
                message:
                    'Saat ini ada ${rates.length} kelompok layanan aktif, '
                    'sedangkan halaman ini dirancang untuk empat kelompok '
                    'layanan.',
              ),
            ),
          for (final rate in rates)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ServiceRateCard(rate: rate),
            ),
        ],
      ],
    );
  }
}

/// Daftar kartu kreator aktif beserta state loading/error/empty-nya.
class _CreativesSection extends ConsumerWidget {
  const _CreativesSection({
    required this.openingCreativeId,
    required this.onOpenPortfolio,
  });

  /// Id kreator yang tautannya sedang dibuka.
  final String? openingCreativeId;

  final Future<void> Function(Creative creative) onOpenPortfolio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creativesAsync = ref.watch(activeCreativesProvider);

    if (creativesAsync.isLoading && !creativesAsync.hasValue) {
      return const AppLoading(label: 'Memuat kreator…');
    }
    if (creativesAsync.hasError && !creativesAsync.hasValue) {
      return AppErrorState(
        title: 'Data kreator belum dapat dimuat',
        message: repositoryErrorMessageFor(
          creativesAsync.error,
          entityLabel: 'kreator',
        ),
        onRetry: () => ref.invalidate(activeCreativesProvider),
      );
    }

    final creatives = creativesAsync.value ?? const <Creative>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (creativesAsync.hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: CatalogSectionNotice(
              isError: true,
              message: repositoryErrorMessageFor(
                creativesAsync.error,
                entityLabel: 'kreator',
              ),
              onRetry: () => ref.invalidate(activeCreativesProvider),
            ),
          ),
        if (creatives.isEmpty)
          const AppEmptyState(
            icon: Icons.person_search_outlined,
            title: 'Kreator belum dikonfigurasi',
            message:
                'Pemilik aplikasi belum mengisi data kreator, sehingga kartu '
                'kreator dan tautan portofolio belum dapat ditampilkan.',
          )
        else ...<Widget>[
          if (creatives.length != _PortfolioScreenState.expectedCreativeCount)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: CatalogSectionNotice(
                message:
                    'Saat ini ada ${creatives.length} kreator aktif, sedangkan '
                    'halaman ini dirancang untuk dua kartu kreator.',
              ),
            ),
          for (final creative in creatives)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: CreativeCard(
                creative: creative,
                isOpening: openingCreativeId == creative.id,
                onOpenPortfolio:
                    creative.hasPortfolioUrl &&
                        ExternalUrl.isValid(creative.portfolioUrl)
                    ? () => onOpenPortfolio(creative)
                    : null,
              ),
            ),
        ],
      ],
    );
  }
}
