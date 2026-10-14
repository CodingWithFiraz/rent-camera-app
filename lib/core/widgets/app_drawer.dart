import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Satu baris navigasi pada [AppDrawer].
class AppDrawerEntry {
  const AppDrawerEntry({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.badgeCount,
  });

  final String label;
  final IconData icon;

  /// Aksi navigasi; pemanggil yang menutup drawer sebelum berpindah halaman.
  ///
  /// `null` berarti tujuan memang belum dapat dipakai (mis. kategori belum
  /// berhasil dimuat). Baris seperti itu tampil nonaktif, bukan tombol mati
  /// yang tetap bisa ditekan.
  final VoidCallback? onTap;

  /// Menandai halaman yang sedang dibuka.
  final bool isSelected;

  /// Angka penanda (mis. jumlah item keranjang); `null`/0 berarti tanpa penanda.
  final int? badgeCount;
}

/// Drawer navigasi bersama untuk seluruh layar utama.
///
/// Bersifat presentasional: daftar tujuan, header, dan footer disusun oleh
/// pemanggil dari provider, sehingga tidak ada pembacaan data di dalam widget
/// ini dan drawer yang sama dapat dipakai layar katalog, portofolio, dan profil.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.entries, this.header, this.footer});

  /// Identitas di bagian atas drawer (mis. brand dan pengguna aktif).
  final Widget? header;

  final List<AppDrawerEntry> entries;

  /// Bagian bawah drawer (mis. tombol keluar).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final headerWidget = header;
    final footerWidget = footer;
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (headerWidget != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: headerWidget,
              ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: entries.length,
                itemBuilder: (BuildContext context, int index) =>
                    _DrawerEntryTile(entry: entries[index]),
              ),
            ),
            if (footerWidget != null) ...<Widget>[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: footerWidget,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DrawerEntryTile extends StatelessWidget {
  const _DrawerEntryTile({required this.entry});

  final AppDrawerEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeCount = entry.badgeCount;
    final hasBadge = badgeCount != null && badgeCount > 0;

    return ListTile(
      // `ListTile` menonaktifkan dirinya sendiri saat `onTap` bernilai `null`.
      onTap: entry.onTap,
      enabled: entry.onTap != null,
      selected: entry.isSelected,
      selectedTileColor: theme.colorScheme.secondaryContainer,
      selectedColor: theme.colorScheme.onSecondaryContainer,
      leading: Icon(
        entry.icon,
        size: 20,
        color: entry.isSelected
            ? theme.colorScheme.onSecondaryContainer
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        entry.label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: entry.isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: hasBadge
          ? Text('$badgeCount', style: theme.textTheme.labelMedium)
          : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
    );
  }
}
