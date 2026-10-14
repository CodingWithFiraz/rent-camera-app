import 'banner.dart';

/// Slide carousel yang dipakai halaman katalog.
///
/// Blueprint §5 menetapkan katalog memakai **tiga** banner. Repository
/// mengembalikan seluruh banner aktif (terurut `sortOrder`); kelas ini yang
/// memotongnya menjadi maksimal tiga slide dan memeriksa apakah salah satu
/// slide yang **tampil** menuju halaman Portofolio. Pemeriksaan itu dilakukan di
/// sini supaya UI dapat menampilkan state konfigurasi yang jujur saat banner
/// wajib tersebut belum diisi, tanpa menebak atau mengarang banner.
class BannerSelection {
  const BannerSelection({required this.slides, required this.ignoredCount});

  /// Jumlah slide maksimum pada katalog.
  static const int maxSlides = 3;

  /// Slide yang ditampilkan, sudah dibatasi [maxSlides] dan bersifat read-only.
  final List<Banner> slides;

  /// Jumlah banner aktif yang tidak muat pada carousel; `0` bila semuanya
  /// tampil. Dikembalikan sebagai data, bukan disembunyikan, supaya admin dapat
  /// mengetahui ada banner yang tidak tampil.
  final int ignoredCount;

  /// Membaca banner aktif (urutan `sortOrder` dari repository dipertahankan).
  factory BannerSelection.from(List<Banner> banners) {
    final slides = banners.take(maxSlides).toList(growable: false);
    return BannerSelection(
      slides: List<Banner>.unmodifiable(slides),
      ignoredCount: banners.length - slides.length,
    );
  }

  bool get isEmpty => slides.isEmpty;

  /// `true` bila ada slide yang tampil menuju halaman Portofolio.
  bool get hasPortfolioSlide =>
      slides.any((banner) => banner.targetType == BannerTargetType.portfolio);

  /// `true` bila ada slide yang belum punya tujuan navigasi valid sehingga
  /// tidak dapat ditekan. Ditampilkan UI sebagai keterangan konfigurasi supaya
  /// slide yang tidak bereaksi tidak dianggap kerusakan aplikasi.
  bool get hasNonNavigableSlide =>
      slides.any((banner) => !banner.hasNavigableTarget);

  /// `true` bila carousel sesuai blueprint: tiga slide dan ada tujuan
  /// Portofolio.
  bool get isComplete => slides.length == maxSlides && hasPortfolioSlide;
}
