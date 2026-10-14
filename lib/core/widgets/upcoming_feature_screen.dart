import 'package:flutter/material.dart';

import 'app_empty_state.dart';

/// Layar penanda untuk halaman yang baru dibangun pada fase berikutnya.
///
/// Dipakai route yang sudah dibutuhkan navigasi Fase 3 (ikon keranjang, ikon
/// profil, banner menuju Portofolio) tetapi halaman penuhnya dikerjakan pada
/// fase lanjutan. Layar ini tidak menampilkan data contoh, tidak mengklaim
/// fitur berjalan, dan tidak memiliki tombol yang tidak melakukan aksi: hanya
/// menjelaskan fase pemiliknya dan menyediakan tombol kembali.
class UpcomingFeatureScreen extends StatelessWidget {
  const UpcomingFeatureScreen({
    super.key,
    required this.title,
    required this.phaseLabel,
    required this.message,
  });

  /// Judul halaman sekaligus app bar.
  final String title;

  /// Nama fase pemilik halaman ini, mis. `Fase 4 — Keranjang`.
  final String phaseLabel;

  /// Penjelasan singkat tanpa detail internal.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: AppEmptyState(
          icon: Icons.schedule_outlined,
          title: '$title belum tersedia',
          message: '$message\n\nHalaman ini dikerjakan pada $phaseLabel.',
          action: OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Kembali'),
          ),
        ),
      ),
    );
  }
}
