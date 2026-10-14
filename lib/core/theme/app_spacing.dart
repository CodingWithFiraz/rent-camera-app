import 'package:flutter/widgets.dart';

/// Skala spacing berbasis kelipatan 4 (blueprint §11).
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Padding standar halaman.
  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: xl,
  );

  /// Jarak antar field form.
  static const double fieldGap = lg;

  /// Lebar maksimum kolom form agar tetap nyaman pada layar lebar.
  static const double maxFormWidth = 420;

  /// Ukuran tap target minimum yang disarankan pedoman aksesibilitas.
  static const double minTapTarget = 48;
}
