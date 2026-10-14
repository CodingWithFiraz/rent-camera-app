import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/external_url.dart';
import 'app_loading.dart';

/// Foto produk/banner/kreator dengan penanganan gambar kosong dan gagal dimuat.
///
/// Tiga keadaan ditangani eksplisit: URL kosong (foto belum diunggah pemilik),
/// gambar sedang dimuat, dan gambar gagal dimuat. Tidak ada gambar acak sebagai
/// pengganti: keadaan kosong tampil apa adanya berupa bidang netral berlabel,
/// supaya foto yang belum ada tidak tampak seperti produk asli.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.aspectRatio,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  /// URL foto; kosong atau berskema tidak dikenal ditampilkan sebagai placeholder.
  final String? imageUrl;

  /// Rasio bidang foto; `null` berarti mengisi seluruh ruang dari induk
  /// (dipakai kartu grid, supaya tidak ada ukuran tetap yang bisa meluap).
  final double? aspectRatio;

  /// Radius crop; `null` berarti mengikuti induk (tanpa crop tambahan).
  final BorderRadius? borderRadius;

  final BoxFit fit;

  /// Label pembaca layar untuk foto.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final uri = ExternalUrl.tryParse(imageUrl);
    final content = uri == null
        ? const _ImagePlaceholder(message: 'Foto belum diisi')
        : Image.network(
            uri.toString(),
            fit: fit,
            semanticLabel: semanticLabel,
            loadingBuilder: (
              BuildContext context,
              Widget child,
              ImageChunkEvent? progress,
            ) => progress == null ? child : const AppLoading(),
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) =>
                    const _ImagePlaceholder(
                      message: 'Foto gagal dimuat',
                      icon: Icons.broken_image_outlined,
                    ),
          );

    final Widget surface = DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.canvas),
      child: content,
    );

    final ratio = aspectRatio;
    final Widget sized = ratio == null
        ? surface
        : AspectRatio(aspectRatio: ratio, child: surface);

    final radius = borderRadius;
    return radius == null
        ? sized
        : ClipRRect(borderRadius: radius, child: sized);
  }
}

/// Bidang pengganti foto dengan ikon dan keterangan singkat.
///
/// Isi dibungkus [FittedBox] agar tetap muat pada bidang kecil (thumbnail
/// keranjang) maupun besar (foto utama detail produk).
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({
    required this.message,
    this.icon = Icons.photo_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(message, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
