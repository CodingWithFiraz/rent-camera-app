/// Formatter mata uang Rupiah.
///
/// Harga pada aplikasi ini selalu integer Rupiah (tanpa pecahan), sehingga
/// formatter ini tidak bergantung pada locale perangkat: hasilnya harus sama di
/// setiap perangkat dan pada test. Pemisah ribuan memakai titik sesuai penulisan
/// Indonesia, contoh `Rp150.000`.
abstract final class CurrencyFormatter {
  /// Mengubah integer Rupiah menjadi teks `Rp150.000`.
  ///
  /// Nilai negatif dipertahankan: `-Rp1.000`. Nilai nol tetap diformat apa adanya
  /// (`Rp0`); pemanggil yang memutuskan apakah nol berarti "belum diisi".
  static String formatRupiah(int amount) {
    final isNegative = amount < 0;
    final digits = amount.abs().toString();
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }

    return isNegative ? '-Rp$buffer' : 'Rp$buffer';
  }
}
