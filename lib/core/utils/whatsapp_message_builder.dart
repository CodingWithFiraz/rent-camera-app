import 'currency_formatter.dart';

/// Satu baris pesanan pada pesan checkout WhatsApp.
///
/// Kelas ini tidak bergantung pada model Firestore/feature mana pun supaya
/// penyusunan pesan dapat diuji sebagai fungsi murni. Satuan periode masuk
/// sebagai [periodLabel] (kata tanpa garis miring, mis. `hari`) hasil pemetaan
/// dokumen produk; `null` berarti pemilik belum menetapkan periode, sehingga
/// pesan tidak boleh menulis periode apa pun (blueprint §7: jangan mengarang
/// `/hari`).
class WhatsAppOrderLine {
  const WhatsAppOrderLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.brand = '',
    this.periodLabel,
  });

  /// Nama alat seperti yang tertera pada data produk.
  final String name;

  /// Brand alat; boleh kosong bila dokumen produk tidak memuatnya.
  final String brand;

  /// Jumlah yang diminta; integer >= 1.
  final int quantity;

  /// Harga satuan integer Rupiah; wajib > 0 karena harga `0` berarti pemilik
  /// belum mengisi harga (lihat [WhatsAppMessageBuilder.build]).
  final int unitPrice;

  /// Kata satuan periode tanpa garis miring, mis. `hari`; `null` bila belum
  /// ditetapkan dokumen produk.
  final String? periodLabel;

  /// Subtotal integer Rupiah: `unitPrice * quantity` (blueprint §7).
  int get subtotal => unitPrice * quantity;

  bool get hasBrand => brand.trim().isNotEmpty;

  bool get hasPeriodLabel => (periodLabel?.trim().isNotEmpty) ?? false;

  /// Judul baris untuk pesan, mis. `Lumix G85 — Panasonic`.
  ///
  /// Tanpa brand, hanya nama alat yang ditulis; tidak ada pemisah kosong yang
  /// membuat pesan tampak rusak.
  String get title => hasBrand ? '$name — ${brand.trim()}' : name;

  /// Harga satuan siap tempel, mis. `Rp150.000 / hari` atau `Rp150.000`.
  String get unitPriceText => _amountWithPeriod(unitPrice);

  /// Subtotal siap tempel, mis. `Rp300.000`.
  String get subtotalText => CurrencyFormatter.formatRupiah(subtotal);

  String _amountWithPeriod(int amount) => hasPeriodLabel
      ? '${CurrencyFormatter.formatRupiah(amount)} / ${periodLabel!.trim()}'
      : CurrencyFormatter.formatRupiah(amount);

  @override
  String toString() => 'WhatsAppOrderLine($name x$quantity)';
}

/// Isi pesan checkout: daftar baris, nama pengguna, dan total estimasi.
class WhatsAppOrderMessage {
  const WhatsAppOrderMessage({required this.lines, this.customerName});

  /// Baris yang siap dipesan; tidak boleh kosong saat pesan dibangun.
  final List<WhatsAppOrderLine> lines;

  /// Nama pengguna bila tersedia; baris `Nama:` dilewati bila kosong.
  final String? customerName;

  /// Total estimasi integer Rupiah dari seluruh subtotal.
  int get total => lines.fold<int>(0, (int sum, line) => sum + line.subtotal);

  bool get hasCustomerName => (customerName?.trim().isNotEmpty) ?? false;

  /// Satuan periode yang dipakai bersama seluruh baris.
  ///
  /// `null` bila ada baris tanpa satuan atau satuan antar baris berbeda:
  /// menjumlahkan periode yang berbeda menjadi satu label akan menjadi klaim
  /// yang tidak benar.
  String? get sharedPeriodLabel {
    String? shared;
    for (final line in lines) {
      if (!line.hasPeriodLabel) {
        return null;
      }
      final label = line.periodLabel!.trim();
      shared ??= label;
      if (shared != label) {
        return null;
      }
    }
    return shared;
  }

  /// Total siap tempel, mis. `Rp250.000 / hari` atau tanpa periode.
  String get totalText {
    final periodLabel = sharedPeriodLabel;
    final amount = CurrencyFormatter.formatRupiah(total);
    return periodLabel == null ? amount : '$amount / $periodLabel';
  }

  @override
  String toString() => 'WhatsAppOrderMessage(${lines.length} baris)';
}

/// Penyusun pesan checkout WhatsApp (blueprint §7, contoh pada baris 346–363).
///
/// Fungsi murni: masukan yang sama selalu menghasilkan pesan yang sama, tanpa
/// akses jaringan/konfigurasi, sehingga isi pesan dapat diuji kata per kata.
abstract final class WhatsAppMessageBuilder {
  /// Menyusun pesan permintaan sewa dari [order].
  ///
  /// Prasyarat yang diperiksa (dan dilanggar berarti bug pemanggil, bukan data
  /// pengguna):
  /// - [WhatsAppOrderMessage.lines] tidak kosong — keranjang kosong tidak boleh
  ///   menghasilkan pesan;
  /// - setiap baris memuat `quantity >= 1`;
  /// - setiap baris memuat `unitPrice > 0`, karena `Rp0` akan terbaca sebagai
  ///   sewa gratis padahal artinya harga belum diisi.
  ///
  /// Pelanggaran prasyarat melempar [ArgumentError]; pesan tidak pernah berisi
  /// harga atau periode karangan sebagai gantinya.
  static String build(WhatsAppOrderMessage order) {
    if (order.lines.isEmpty) {
      throw ArgumentError.value(
        order.lines,
        'order.lines',
        'pesan checkout tidak boleh dibangun tanpa baris pesanan',
      );
    }
    for (final line in order.lines) {
      if (line.quantity < 1) {
        throw ArgumentError.value(
          line.quantity,
          'order.lines.quantity',
          'jumlah pada pesan checkout minimal 1',
        );
      }
      if (line.unitPrice <= 0) {
        throw ArgumentError.value(
          line.unitPrice,
          'order.lines.unitPrice',
          'harga pada pesan checkout harus lebih dari 0',
        );
      }
    }

    final buffer = StringBuffer()
      ..writeln('Halo, saya ingin menanyakan penyewaan alat berikut:')
      ..writeln();

    for (var index = 0; index < order.lines.length; index++) {
      final line = order.lines[index];
      buffer
        ..writeln('${index + 1}. ${line.title}')
        ..writeln('   Jumlah: ${line.quantity}')
        ..writeln('   Harga satuan: ${line.unitPriceText}')
        ..writeln('   Subtotal: ${line.subtotalText}');
      if (index < order.lines.length - 1) {
        buffer.writeln();
      }
    }

    buffer
      ..writeln()
      ..writeln('TOTAL ESTIMASI: ${order.totalText}')
      ..writeln()
      ..writeln(
        'Mohon konfirmasi ketersediaan, periode sewa, dan ketentuan lainnya.',
      );

    if (order.hasCustomerName) {
      buffer.writeln('Nama: ${order.customerName!.trim()}');
    }

    // Pesan tidak diakhiri baris kosong agar rapi pada kotak chat WhatsApp.
    return buffer.toString().trimRight();
  }
}
