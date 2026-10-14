import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'external_url.dart';

/// Hasil percobaan membuka tautan eksternal.
enum ExternalLaunchStatus {
  /// Tautan berhasil diserahkan ke aplikasi lain (browser/aplikasi tujuan).
  launched,

  /// Aplikasi tujuan gagal dibuka, tetapi tautan sudah disalin ke clipboard
  /// sebagai jalan keluar supaya pengguna tidak kehilangan tautannya.
  copiedToClipboard,

  /// URL kosong, tidak valid, atau berskema yang tidak diizinkan.
  invalidUrl,

  /// Aplikasi tujuan dan clipboard sama-sama gagal.
  failed,
}

/// Membuka [uri] melalui aplikasi lain (`url_launcher`).
Future<bool> launchExternalUrl(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Menyimpan [text] ke clipboard perangkat.
Future<void> writeToClipboard(String text) =>
    Clipboard.setData(ClipboardData(text: text));

/// Pembuka tautan eksternal yang aman dan dapat diuji.
///
/// Urutannya: validasi skema URL, coba buka lewat aplikasi lain, lalu tawarkan
/// salin tautan bila aplikasi tujuan tidak tersedia. Widget menerima
/// [ExternalLaunchStatus] dan menampilkan pesan yang sesuai — kegagalan tidak
/// pernah dilaporkan sebagai keberhasilan.
///
/// [opener] dan [clipboardWriter] dapat diganti pada test supaya tidak ada
/// pemanggilan platform channel dan hasilnya deterministik.
class ExternalLauncher {
  const ExternalLauncher({
    this.opener = launchExternalUrl,
    this.clipboardWriter = writeToClipboard,
  });

  final Future<bool> Function(Uri uri) opener;
  final Future<void> Function(String text) clipboardWriter;

  /// Membuka [rawUrl] atau menyalinnya bila aplikasi tujuan tidak tersedia.
  Future<ExternalLaunchStatus> open(String? rawUrl) async {
    final uri = ExternalUrl.tryParse(rawUrl);
    if (uri == null) {
      return ExternalLaunchStatus.invalidUrl;
    }

    var launched = false;
    try {
      launched = await opener(uri);
    } catch (_) {
      // Kegagalan peluncuran (mis. tidak ada aplikasi tujuan) bukan crash:
      // pengguna masih bisa memakai tautan yang disalin ke clipboard.
      launched = false;
    }
    if (launched) {
      return ExternalLaunchStatus.launched;
    }

    try {
      await clipboardWriter(uri.toString());
      return ExternalLaunchStatus.copiedToClipboard;
    } catch (_) {
      // Hanya status yang dilaporkan; detail error platform tidak ditampilkan.
      return ExternalLaunchStatus.failed;
    }
  }
}
