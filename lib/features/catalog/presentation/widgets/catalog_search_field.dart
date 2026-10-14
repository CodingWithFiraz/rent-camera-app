import 'package:flutter/material.dart';

/// Kolom pencarian katalog.
///
/// Nilai teks tetap dipegang pemanggil lewat [controller] supaya satu sumber
/// kebenaran kriteria pencarian tetap ada di provider filter. Widget ini hanya
/// mengurus tampilan: ikon pencarian dan tombol hapus yang muncul saat kolom
/// terisi (dipantau lewat [ListenableBuilder], bukan state lokal).
class CatalogSearchField extends StatelessWidget {
  const CatalogSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;

  /// Dipanggil pada setiap perubahan teks (tanpa debounce: penyaringan produk
  /// dilakukan di memori atas data yang sudah dimuat).
  final ValueChanged<String> onChanged;

  /// Mengosongkan kata kunci.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          autocorrect: false,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Cari nama alat, brand, atau kata kunci',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus kata kunci',
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                  ),
          ),
        );
      },
    );
  }
}
