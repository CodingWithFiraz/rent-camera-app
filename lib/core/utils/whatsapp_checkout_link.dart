/// Penyusun tautan checkout WhatsApp (`https://wa.me/...`).
///
/// Blueprint §7 langkah 6 memakai format `https://wa.me/<nomor>?text=<pesan>`
/// dan langkah 5 melarang nomor disebar ke banyak file — nomor hanya datang
/// dari [AppConfig] (`WHATSAPP_NUMBER`). Kelas ini murni: tidak membaca
/// konfigurasi dan tidak membuka tautan, sehingga dapat diuji tanpa platform.
///
/// Nomor dan pesan tidak pernah disisipkan mentah:
/// - [normalizeNumber] hanya meloloskan digit dengan pemisah yang lazim, dan
///   menolak teks lain (mis. huruf) supaya tautan yang dibuka bukan tautan
///   yang salah;
/// - pesan di-encode dengan [Uri.encodeComponent], sehingga spasi menjadi
///   `%20`, baris baru `%0A`, dan karakter khusus (`&`, `#`, `?`, `+`,
///   non-ASCII) tidak memotong atau mengubah query URL.
abstract final class WhatsAppCheckoutLink {
  /// Basis tautan resmi WhatsApp untuk memulai chat berdasarkan nomor.
  static const String baseUrl = 'https://wa.me';

  /// Panjang nomor E.164 tanpa `+` yang masih masuk akal: 8–15 digit.
  static const int minDigits = 8;
  static const int maxDigits = 15;

  /// Pemisah yang lazim ditulis pengguna dan aman dibuang.
  static const String _separators = ' +-().';

  /// Membuang pemisah dan `+`, menyisakan digit saja.
  ///
  /// Mengembalikan string kosong bila nomor kosong atau memuat karakter selain
  /// digit dan [_separators]; nilai seperti itu tidak boleh ditebak-tebak.
  static String normalizeNumber(String? rawNumber) {
    final raw = rawNumber?.trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }
    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        buffer.writeCharCode(rune);
        continue;
      }
      if (_separators.codeUnits.contains(rune)) {
        continue;
      }
      return '';
    }
    return buffer.toString();
  }

  /// `true` bila [rawNumber] dapat dipakai sebagai nomor tujuan checkout.
  ///
  /// Nomor diawali `0` ditolak: itu awalan nasional (mis. `08...`) yang tidak
  /// berlaku pada `wa.me`, dan menebak kode negara akan mengirim permintaan ke
  /// nomor orang lain.
  static bool isUsableNumber(String? rawNumber) =>
      _isUsableDigits(normalizeNumber(rawNumber));

  /// Membangun URI checkout, atau `null` bila nomor belum dikonfigurasi/tidak
  /// sah. Pemanggil menampilkan state konfigurasi, bukan mengarang nomor.
  static Uri? tryBuildUri({required String? number, required String message}) {
    final digits = normalizeNumber(number);
    if (!_isUsableDigits(digits)) {
      return null;
    }
    final encodedMessage = Uri.encodeComponent(message);
    return Uri.tryParse('$baseUrl/$digits?text=$encodedMessage');
  }

  static bool _isUsableDigits(String digits) {
    if (digits.length < minDigits || digits.length > maxDigits) {
      return false;
    }
    return !digits.startsWith('0');
  }
}
