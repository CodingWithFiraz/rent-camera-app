import 'dart:async';

import 'package:flutter/material.dart' hide Banner;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/product_image.dart';
import '../../domain/banner.dart';

/// Carousel banner katalog.
///
/// Presentasional: seluruh data dan aksi navigasi diberikan pemanggil, sehingga
/// widget ini dapat diuji tanpa Firestore. Tiga hal dijaga di sini:
/// 1. Tinggi slide konsisten — seluruh slide berada pada satu [AspectRatio],
///    bukan tinggi terpisah per gambar.
/// 2. Slide tanpa tujuan navigasi valid **tidak** dapat ditekan, jadi tidak ada
///    tombol yang tampak bisa dipakai tetapi tidak melakukan apa pun.
/// 3. Auto-play berhenti bila animasi sistem dimatikan (aksesibilitas) atau
///    hanya ada satu slide.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.slides,
    required this.onSlideTap,
    this.autoPlayInterval = const Duration(seconds: 6),
  });

  /// Slide yang ditampilkan (sudah dibatasi tiga oleh `BannerSelection`).
  final List<Banner> slides;

  /// Dipanggil hanya untuk slide yang tujuan navigasinya valid.
  final ValueChanged<Banner> onSlideTap;

  /// Jeda auto-play; `null` mematikan auto-play (dipakai pada test dan saat
  /// pengguna mematikan animasi sistem).
  final Duration? autoPlayInterval;

  /// Rasio bidang carousel; dipakai agar tinggi seluruh slide sama.
  static const double slideAspectRatio = 16 / 9;

  /// Tinggi area judul; dibatasi agar judul panjang tidak mengubah tinggi slide.
  static const double captionHeight = 40;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controller = PageController();
  Timer? _autoPlayTimer;
  int _index = 0;
  bool _animationsDisabled = false;

  @override
  void initState() {
    super.initState();
    _restartAutoPlay();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.of(context).disableAnimations;
    if (disabled != _animationsDisabled) {
      _animationsDisabled = disabled;
      _restartAutoPlay();
    }
  }

  @override
  void didUpdateWidget(covariant BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final slideCountChanged = oldWidget.slides.length != widget.slides.length;
    if (!slideCountChanged &&
        oldWidget.autoPlayInterval == widget.autoPlayInterval) {
      return;
    }
    if (_index >= widget.slides.length) {
      // Banner bisa dinonaktifkan admin saat carousel terbuka: kembali ke slide
      // pertama agar tidak ada posisi halaman di luar jumlah slide.
      _index = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
    _restartAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartAutoPlay() {
    _autoPlayTimer?.cancel();
    final interval = widget.autoPlayInterval;
    if (interval == null || widget.slides.length < 2 || _animationsDisabled) {
      return;
    }
    _autoPlayTimer = Timer.periodic(interval, (_) => _advance());
  }

  void _advance() {
    if (!mounted || !_controller.hasClients || widget.slides.length < 2) {
      return;
    }
    final nextIndex = (_index + 1) % widget.slides.length;
    _controller.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    if (slides.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AspectRatio(
          aspectRatio: BannerCarousel.slideAspectRatio,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (int index) => setState(() => _index = index),
            itemBuilder: (BuildContext context, int index) {
              final banner = slides[index];
              return _BannerSlide(
                banner: banner,
                onTap: banner.hasNavigableTarget
                    ? () => widget.onSlideTap(banner)
                    : null,
              );
            },
          ),
        ),
        if (slides.length > 1)
          _SlideIndicator(count: slides.length, index: _index),
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.banner, this.onTap});

  final Banner banner;

  /// `null` berarti tujuan banner belum dikonfigurasi: slide tampil tanpa aksi.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ProductImage(
                imageUrl: banner.imageUrl,
                borderRadius: AppRadius.mdAll,
                semanticLabel: 'Gambar banner ${banner.title}',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Kotak tinggi tetap: judul panjang hanya dipotong, tidak mengubah
            // tinggi slide dan tidak memicu overflow.
            SizedBox(
              height: BannerCarousel.captionHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  banner.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indikator posisi slide (bukan tombol: hanya penanda posisi saat ini).
class _SlideIndicator extends StatelessWidget {
  const _SlideIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Slide ${index + 1} dari $count',
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(count, (int position) {
            final isActive = position == index;
            return Container(
              width: isActive ? 14 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ),
    );
  }
}
