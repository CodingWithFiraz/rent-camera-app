import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/catalog_filter.dart';
import '../../domain/category.dart';
import '../category_icons.dart';

/// Baris filter katalog: kategori, brand, dan tombol hapus filter.
///
/// Pilihan brand berasal dari [brands] yang disusun provider berdasarkan
/// kategori terpilih, jadi daftar brand selalu mengikuti kategori. Kombinasi
/// pencarian + kategori + brand tetap dipegang satu provider
/// (`catalogFilterProvider`); widget ini hanya mengirim pilihan pengguna.
class CatalogFilterBar extends StatelessWidget {
  const CatalogFilterBar({
    super.key,
    required this.categories,
    required this.brands,
    required this.filter,
    required this.onSelectCategory,
    required this.onSelectBrand,
    required this.onReset,
  });

  /// Kategori aktif dari Firestore; kosong berarti belum dapat dimuat.
  final List<Category> categories;

  /// Brand unik pada kategori terpilih; kosong berarti tidak ada pilihan brand.
  final List<String> brands;

  final CatalogFilter filter;

  /// `null` berarti semua kategori.
  final ValueChanged<String?> onSelectCategory;

  /// `null` berarti semua brand.
  final ValueChanged<String?> onSelectBrand;

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (categories.isNotEmpty) ...<Widget>[
          Text('Kategori', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          _ChipRow(
            children: <Widget>[
              _CatalogChoiceChip(
                label: 'Semua',
                icon: Icons.grid_view_outlined,
                selected: !filter.hasCategory,
                onTap: () => onSelectCategory(null),
              ),
              for (final category in categories)
                _CatalogChoiceChip(
                  label: category.name,
                  icon: CategoryIcons.forKey(category.resolvedIconKey),
                  selected: filter.categoryId == category.id,
                  onTap: () => onSelectCategory(category.id),
                ),
            ],
          ),
        ],
        if (brands.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text('Brand', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          _ChipRow(
            children: <Widget>[
              _CatalogChoiceChip(
                label: 'Semua brand',
                selected: !filter.hasBrand,
                onTap: () => onSelectBrand(null),
              ),
              for (final brand in brands)
                _CatalogChoiceChip(
                  label: brand,
                  selected: filter.brand?.toLowerCase() == brand.toLowerCase(),
                  onTap: () => onSelectBrand(brand),
                ),
            ],
          ),
        ],
        if (filter.isFiltering) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Hapus filter'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Deretan chip yang dapat digulir mendatar agar aman pada layar sempit.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (var index = 0; index < children.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(width: AppSpacing.sm),
            children[index],
          ],
        ],
      ),
    );
  }
}

/// Chip pilihan tunggal dengan gaya token aplikasi.
class _CatalogChoiceChip extends StatelessWidget {
  const _CatalogChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = icon;
    return ChoiceChip(
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      avatar: iconData == null ? null : Icon(iconData, size: 18),
      labelStyle: theme.textTheme.bodyMedium,
      visualDensity: VisualDensity.compact,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
    );
  }
}
