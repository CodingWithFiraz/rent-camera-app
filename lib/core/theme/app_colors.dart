import 'package:flutter/material.dart';

/// Token warna aplikasi (palet awal pada bagian desain blueprint).
///
/// Widget tidak boleh memakai warna literal; selalu ambil dari token ini atau
/// dari `Theme.of(context).colorScheme`.
abstract final class AppColors {
  /// Latar halaman: warm off-white.
  static const Color canvas = Color(0xFFF5F4EF);

  /// Permukaan card/field di atas [canvas].
  static const Color surface = Color(0xFFFFFFFF);

  /// Teks utama.
  static const Color textPrimary = Color(0xFF171817);

  /// Teks sekunder/caption.
  static const Color textSecondary = Color(0xFF6F746F);

  /// Warna aksi utama (deep green).
  static const Color primary = Color(0xFF172A26);

  /// Aksen lime, hanya untuk CTA/status penting.
  static const Color accentLime = Color(0xFFC7F36A);

  /// Garis pemisah dan border input.
  static const Color border = Color(0xFFDFE2DA);

  /// Warna error.
  static const Color error = Color(0xFFB93838);

  /// Latar pesan error pada form (turunan gelap-terang dari [error]).
  static const Color errorContainer = Color(0xFFF6E2E1);

  /// Teks di atas [errorContainer].
  static const Color onErrorContainer = Color(0xFF6E1D1D);
}
