import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/category.dart';

class CatalogFilterBar extends StatelessWidget {
  final List<Category> categories;
  final List<String> brands;
  final dynamic filter;
  final ValueChanged<String?> onSelectCategory;
  final ValueChanged<String?> onSelectBrand;
  final VoidCallback onReset;

  const CatalogFilterBar({
    super.key,
    required this.categories,
    required this.brands,
    required this.filter,
    required this.onSelectCategory,
    required this.onSelectBrand,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCategoryCode = _getSelectedCategoryCode(filter);
    final selectedBrand = _getSelectedBrand(filter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- SECTION KATEGORI ---
        Text(
          'Kategori',
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Wrap agar tombol kategori otomatis turun ke baris baru saat di layar HP
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            // Chip 'Semua' Kategori
            FilterChip(
              avatar: const Icon(Icons.grid_view_rounded, size: 18),
              label: const Text('Semua'),
              selected: selectedCategoryCode == null || selectedCategoryCode.isEmpty,
              onSelected: (_) => onSelectCategory(null),
            ),
            // Chip Kategori Dinamis
            for (final category in categories)
              Builder(
                builder: (context) {
                  final catCode = _getCategoryCode(category);
                  final catName = _getCategoryName(category);

                  return FilterChip(
                    avatar: _getCategoryIcon(catCode),
                    label: Text(catName),
                    selected: selectedCategoryCode == catCode,
                    onSelected: (_) => onSelectCategory(catCode),
                  );
                },
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // --- SECTION BRAND ---
        if (brands.isNotEmpty) ...[
          Text(
            'Brand',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              // Chip 'Semua brand'
              FilterChip(
                label: const Text('Semua brand'),
                selected: selectedBrand == null || selectedBrand.isEmpty,
                onSelected: (_) => onSelectBrand(null),
              ),
              // Chip Brand Dinamis
              for (final brand in brands)
                FilterChip(
                  label: Text(brand),
                  selected: selectedBrand == brand,
                  onSelected: (_) => onSelectBrand(brand),
                ),
            ],
          ),
        ],
      ],
    );
  }

  // Safe getter untuk kategori terpilih
  String? _getSelectedCategoryCode(dynamic filter) {
    if (filter == null) return null;
    try {
      final val = filter.categoryCode;
      if (val != null) return val.toString();
    } catch (_) {}
    try {
      final val = filter.category;
      if (val != null) return val.toString();
    } catch (_) {}
    try {
      final val = filter.selectedCategoryCode;
      if (val != null) return val.toString();
    } catch (_) {}
    try {
      final val = filter.selectedCategory;
      if (val != null) return val.toString();
    } catch (_) {}
    return null;
  }

  // Safe getter untuk brand terpilih
  String? _getSelectedBrand(dynamic filter) {
    if (filter == null) return null;
    try {
      final val = filter.brand;
      if (val != null) return val.toString();
    } catch (_) {}
    try {
      final val = filter.selectedBrand;
      if (val != null) return val.toString();
    } catch (_) {}
    return null;
  }

  // Safe getter untuk kode/ID dari model Category
  String _getCategoryCode(dynamic category) {
    if (category == null) return '';
    try {
      final val = category.code;
      if (val != null) return val.toString();
    } catch (_) {}
    try {
      final val = category.id;
      if (val != null) return val.toString();
    } catch (_) {}
    try {
      final val = category.slug;
      if (val != null) return val.toString();
    } catch (_) {}
    return category.toString();
  }

  // Safe getter untuk nama dari model Category
  String _getCategoryName(dynamic category) {
    if (category == null) return '';
    try {
      final val = category.name;
      if (val != null) return val.toString();
    } catch (_) {}
    try {
      final val = category.title;
      if (val != null) return val.toString();
    } catch (_) {}
    return category.toString();
  }

  // Helper Icon Kategori
  Widget? _getCategoryIcon(String code) {
    switch (code.toLowerCase()) {
      case 'kamera':
      case 'camera':
        return const Icon(Icons.camera_alt_outlined, size: 18);
      case 'lensa':
      case 'lens':
        return const Icon(Icons.camera_outlined, size: 18);
      case 'lighting':
        return const Icon(Icons.wb_sunny_outlined, size: 18);
      case 'drone':
        return const Icon(Icons.flight_outlined, size: 18);
      case 'mic':
      case 'audio':
        return const Icon(Icons.mic_none_outlined, size: 18);
      case 'tripod':
        return const Icon(Icons.videocam_outlined, size: 18);
      case 'sd_card':
      case 'memory':
        return const Icon(Icons.sd_card_outlined, size: 18);
      default:
        return null;
    }
  }
}