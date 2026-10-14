import '../../../core/utils/currency_formatter.dart';
import 'price_unit.dart';
import 'product.dart';

/// Teks harga beserta periode sewa siap ditampilkan.
///
/// Kelas ini menjaga dua aturan blueprint sekaligus:
/// 1. Label periode hanya muncul bila dokumen produk benar-benar menetapkan
///    `priceUnit` (jangan mengarang "/hari" — lihat [PriceUnit]).
/// 2. Harga `0` tidak pernah ditampilkan sebagai sewa gratis; nilai itu berarti
///    pemilik belum mengisi harga, jadi ditampilkan sebagai keterangan, bukan
///    angka Rupiah yang bisa disalahartikan.
class PriceDisplay {
  const PriceDisplay({
    required this.amountText,
    this.hasAmount = true,
    this.periodLabel,
  });

  /// Membuat teks harga dari integer Rupiah dan satuan periode dokumen.
  factory PriceDisplay.fromAmount(int amount, PriceUnit unit) {
    final hasAmount = amount > 0;
    return PriceDisplay(
      amountText: hasAmount
          ? CurrencyFormatter.formatRupiah(amount)
          : 'Harga belum diisi',
      hasAmount: hasAmount,
      periodLabel: periodLabelFor(unit),
    );
  }

  /// Membuat teks harga dari data produk.
  factory PriceDisplay.forProduct(Product product) =>
      PriceDisplay.fromAmount(product.price, product.priceUnit);

  final String amountText;

  /// `true` bila dokumen produk benar-benar mengisi harga (> 0).
  ///
  /// Harga `0` berarti pemilik belum mengisi harga, bukan sewa gratis.
  final bool hasAmount;

  /// Label satuan (`/hari`); `null` bila satuan belum ditetapkan.
  final String? periodLabel;

  bool get hasPeriodLabel => periodLabel != null;

  /// Teks lengkap, contoh `Rp150.000/hari`.
  ///
  /// Tanpa label periode hasilnya hanya `Rp150.000`, bukan periode yang
  /// diasumsi. Saat harga belum diisi, satuan juga tidak ditulis karena
  /// "Harga belum diisi/hari" akan terbaca seperti periode yang sudah pasti.
  String get text =>
      hasAmount && hasPeriodLabel ? '$amountText$periodLabel' : amountText;

  /// Label satuan periode untuk UI.
  ///
  /// `switch` tanpa `default` dipakai sengaja: penambahan [PriceUnit] baru akan
  /// gagal saat kompilasi, bukan diam-diam tanpa label.
  static String? periodLabelFor(PriceUnit unit) {
    switch (unit) {
      case PriceUnit.perDay:
        return '/hari';
      case PriceUnit.perSession:
        return '/sesi';
      case PriceUnit.unspecified:
        return null;
    }
  }

  @override
  String toString() => text;
}
