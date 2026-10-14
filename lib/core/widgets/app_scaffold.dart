import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// Kerangka layar konsisten: app bar, drawer opsional, dan body dengan safe area.
///
/// Dipakai layar utama supaya hamburger (muncul otomatis dari [drawer]),
/// identitas aplikasi, dan aksi sisi kanan (keranjang/profil) selalu berada pada
/// posisi yang sama di setiap layar.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.drawer,
    this.actions = const <Widget>[],
    this.leading,
  });

  /// Isi layar; sudah dibungkus `SafeArea` oleh scaffold ini.
  final Widget body;

  /// Judul app bar; `null` berarti memakai identitas aplikasi
  /// ([AppConfig.appName]).
  final String? title;

  /// Drawer navigasi; keberadaannya memunculkan tombol hamburger.
  final Widget? drawer;

  final List<Widget> actions;

  /// Nav kiri khusus, misalnya tombol kembali yang tetap bekerja walau route
  /// tidak dapat di-pop (tautan langsung/deep link).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    const Color charcoalText = Color(0xFF1E1E1E);
    final resolvedDrawer = drawer;
    final resolvedLeading = leading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(
          0xFFBCEE46,
        ), // Warna latar belakang AppBar hijau limau
        foregroundColor: charcoalText, // Warna ikon dan teks otomatis gelap
        // `automaticallyImplyLeading` dimatikan hanya saat pemanggil sudah
        // menyediakan tombol sendiri, supaya tidak ada dua tombol kiri.
        automaticallyImplyLeading: resolvedLeading == null,
        leading: resolvedLeading,
        // Nama produk/brand bisa panjang: judul dipotong satu baris agar app bar
        // tidak berubah tinggi atau meluap pada layar sempit.
        title: Text(
          title ?? AppConfig.appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: charcoalText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: actions,
      ),
      drawer: resolvedDrawer,
      body: SafeArea(child: body),
    );
  }
}
