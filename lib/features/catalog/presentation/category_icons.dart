import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Pemetaan `categories.iconKey` ke ikon Material yang dikenal aplikasi.
///
/// Blueprint §6.1: `iconKey` dokumen Firestore **tidak** dijalankan sebagai nama
/// class dinamis. Nilai yang tidak dikenal jatuh ke ikon kategori netral,
/// sehingga dokumen lama/tak terduga tidak pernah membuat katalog gagal render.
abstract final class CategoryIcons {
  static const Map<String, IconData> _icons = <String, IconData>{
    CategoryIconKeys.camera: Icons.photo_camera_outlined,
    CategoryIconKeys.lens: Icons.camera_outlined,
    CategoryIconKeys.flash: Icons.flash_on_outlined,
    CategoryIconKeys.lighting: Icons.light_mode_outlined,
    CategoryIconKeys.drone: Icons.flight_outlined,
    CategoryIconKeys.microphone: Icons.mic_none_outlined,
    CategoryIconKeys.mic: Icons.mic_none_outlined,
    CategoryIconKeys.stabilizer: Icons.videocam_outlined,
    CategoryIconKeys.tripod: Icons.videocam_outlined,
    CategoryIconKeys.sdCard: Icons.sd_card_outlined,
    CategoryIconKeys.accessory: Icons.cable_outlined,
    CategoryIconKeys.defaultKey: Icons.category_outlined,
  };

  /// Ikon untuk [iconKey] (`null`/tak dikenal menjadi ikon default).
  static IconData forKey(String? iconKey) =>
      _icons[iconKey] ?? _icons[CategoryIconKeys.defaultKey]!;
}
