/// Validasi URL eksternal sebelum dibuka atau dimuat gambarnya.
///
/// URL pada aplikasi ini berasal dari dokumen Firestore yang diisi admin
/// (banner, link portofolio kreator, foto produk). Nilai itu tidak boleh
/// dipercaya mentah: hanya skema `http`/`https` yang diizinkan, sehingga skema
/// lain seperti `javascript:`, `file:`, atau `intent:` tidak pernah diteruskan
/// ke aplikasi lain.
abstract final class ExternalUrl {
  /// Skema yang boleh dibuka aplikasi.
  static const Set<String> allowedSchemes = <String>{'http', 'https'};

  /// Mengembalikan [Uri] bila [rawUrl] valid dan aman, atau `null` bila tidak.
  ///
  /// Spasi di awal/akhir dibuang, dan `host` wajib terisi supaya teks seperti
  /// `https://` atau `example.com` (tanpa skema) tidak dianggap tautan.
  static Uri? tryParse(String? rawUrl) {
    final trimmed = rawUrl?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return null;
    }
    if (!allowedSchemes.contains(uri.scheme.toLowerCase())) {
      return null;
    }
    if (uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  /// `true` bila [rawUrl] boleh dibuka atau dimuat.
  static bool isValid(String? rawUrl) => tryParse(rawUrl) != null;
}
