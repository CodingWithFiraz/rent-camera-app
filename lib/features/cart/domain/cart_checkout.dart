import '../../../core/utils/whatsapp_message_builder.dart';
import '../../catalog/domain/price_display.dart';
import '../../catalog/domain/price_unit.dart';
import '../../catalog/domain/product.dart';
import 'cart_item.dart';

/// Alasan satu baris keranjang belum dapat dipesan saat checkout.
///
/// Nilai ini dipakai UI untuk memilih tindakan yang tepat — hapus baris,
/// perbarui harga, atau turunkan jumlah — bukan sekadar untuk warna pesan.
enum CartCheckoutIssueKind {
  /// Dokumen produk sudah tidak ada di collection `products`.
  productMissing,

  /// Produk masih ada tetapi sudah diarsipkan (`isActive == false`).
  productInactive,

  /// Admin belum mengisi harga (`price <= 0`), sehingga total belum pasti.
  priceNotConfigured,

  /// Harga dokumen berbeda dari harga saat produk dimasukkan ke keranjang.
  priceChanged,

  /// Satuan periode harga berbeda dari snapshot keranjang.
  priceUnitChanged,

  /// Jumlah di keranjang melebihi stok terverifikasi terbaru.
  insufficientStock,
}

/// Satu masalah checkout beserta kalimat yang menjelaskan perbaikannya.
///
/// [message] selalu berisi data yang memang ada di Firestore (mis. stok
/// terbaru) dan menyebut langkah pengguna; tidak ada detail internal, tipe
/// exception, atau nilai yang ditebak.
class CartCheckoutIssue {
  const CartCheckoutIssue({required this.kind, required this.message});

  final CartCheckoutIssueKind kind;
  final String message;

  @override
  String toString() => 'CartCheckoutIssue(${kind.name})';
}

/// Satu baris keranjang yang sudah dicocokkan dengan data produk terbaru.
///
/// Harga dan satuan pada baris ini berasal dari dokumen produk hasil baca ulang
/// saat checkout bila produk masih ada, sehingga pesan WhatsApp tidak memakai
/// harga lama. Saat produk sudah hilang, yang tersisa hanya snapshot keranjang —
/// dan baris itu selalu punya [issue], jadi tidak pernah ikut dipesan.
class CartCheckoutLine {
  const CartCheckoutLine({
    required this.productId,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.priceUnit,
    this.availableStock,
    this.issue,
  });

  /// Document ID produk; sama dengan document ID baris keranjang.
  final String productId;

  /// Nama tampil: snapshot keranjang, atau document ID bila snapshot kosong.
  final String name;

  final String brand;
  final String imageUrl;

  /// Jumlah yang diminta pengguna; integer >= 1.
  final int quantity;

  /// Harga satuan integer Rupiah terbaru yang dapat dipakai menghitung.
  final int unitPrice;

  /// Satuan periode harga terbaru; [PriceUnit.unspecified] berarti belum
  /// ditetapkan dokumen.
  final PriceUnit priceUnit;

  /// Stok terverifikasi terbaru; `null` bila produk tidak ada sehingga stok
  /// tidak dapat diketahui (bukan dianggap 0).
  final int? availableStock;

  /// Masalah yang menghalangi baris ini ikut dipesan; `null` berarti siap.
  final CartCheckoutIssue? issue;

  /// Subtotal integer Rupiah: `unitPrice * quantity`.
  int get subtotal => unitPrice * quantity;

  bool get isUsable => issue == null;

  /// Harga satuan siap tampil, mis. `Rp150.000/hari` atau `Rp150.000`.
  ///
  /// Memakai [PriceDisplay] agar aturan "harga 0 berarti belum diisi" dan satuan
  /// periode yang eksplisit sama dengan katalog.
  String get unitPriceText =>
      PriceDisplay.fromAmount(unitPrice, priceUnit).amountText;

  /// Label satuan periode (`/hari`); `null` bila belum ditetapkan dokumen.
  String? get periodLabel => PriceDisplay.periodLabelFor(priceUnit);

  /// Kata satuan periode tanpa garis miring (`hari`); `null` bila belum
  /// ditetapkan dokumen.
  ///
  /// Dipakai pesan WhatsApp yang menulis `Rp150.000 / hari`, sedangkan UI
  /// menulis `Rp150.000/hari`. Keduanya memakai pemetaan yang sama di
  /// [PriceDisplay] supaya label periode tidak pernah berbeda antar tampilan.
  String? get periodWord => PriceDisplay.periodWordFor(priceUnit);

  /// Batas jumlah yang boleh dipilih dari stok terbaru; `null` berarti stok
  /// tidak dapat dipercaya (produk hilang/arsip atau stok 0).
  int? get selectableMaxQuantity {
    final stock = availableStock;
    if (stock == null || stock < 1) {
      return null;
    }
    return stock < CartItem.maxQuantity ? stock : CartItem.maxQuantity;
  }

  /// `true` bila pengguna masih boleh mengubah jumlah baris ini.
  ///
  /// Baris tanpa masalah selalu boleh; baris yang kelebihan stok juga boleh
  /// karena menurunkan jumlah adalah cara memperbaikinya.
  bool get canChangeQuantity {
    final kind = issue?.kind;
    if (kind != null && kind != CartCheckoutIssueKind.insufficientStock) {
      return false;
    }
    return selectableMaxQuantity != null;
  }

  /// Jumlah yang disarankan agar sesuai stok terbaru; `null` bila stok sedang
  /// habis atau tidak diketahui (satu-satunya perbaikan adalah menghapus baris).
  int? get recommendedQuantityForStock {
    final stock = availableStock;
    if (stock == null || stock < 1) {
      return null;
    }
    return stock;
  }

  @override
  String toString() => 'CartCheckoutLine($productId x$quantity)';
}

/// Hasil pencocokan seluruh baris keranjang dengan data produk terbaru.
///
/// Blueprint §7 langkah 4: subtotal dan total dihitung ulang dari data aktual —
/// bukan dari snapshot keranjang — sehingga total yang ditampilkan dan yang
/// dikirim ke WhatsApp berasal dari harga dokumen terakhir yang dibaca.
class CartCheckoutValidation {
  const CartCheckoutValidation({required this.lines});

  /// Keranjang kosong.
  static const CartCheckoutValidation empty = CartCheckoutValidation(
    lines: <CartCheckoutLine>[],
  );

  final List<CartCheckoutLine> lines;

  /// Mencocokkan setiap baris keranjang dengan hasil baca ulang produk.
  ///
  /// [products] berasal dari `ProductRepository.fetchProductsByIds`. Produk yang
  /// sudah dihapus tidak muncul pada map, sehingga barisnya ditandai
  /// [CartCheckoutIssueKind.productMissing] — bukan dibuang diam-diam.
  factory CartCheckoutValidation.validate({
    required List<CartItem> items,
    required Map<String, Product> products,
  }) {
    return CartCheckoutValidation(
      lines: List<CartCheckoutLine>.unmodifiable(
        items.map(
          (CartItem item) => _validateLine(item, products[item.productId]),
        ),
      ),
    );
  }

  bool get isEmpty => lines.isEmpty;

  bool get hasLines => lines.isNotEmpty;

  /// Baris yang benar-benar siap dipesan.
  List<CartCheckoutLine> get usableLines => lines
      .where((CartCheckoutLine line) => line.isUsable)
      .toList(growable: false);

  /// Jumlah baris yang masih perlu diperbaiki pengguna.
  int get blockedLineCount => lines.length - usableLines.length;

  bool get hasIssues => blockedLineCount > 0;

  /// `true` bila keranjang berisi dan seluruh barisnya siap dipesan.
  bool get isReady => hasLines && !hasIssues;

  /// Total estimasi integer Rupiah dari baris yang siap dipesan.
  ///
  /// Baris bermasalah tidak dijumlahkan: memasukkan harga yang belum pasti
  /// berlaku akan membuat total terlihat final padahal bukan.
  int get total => usableLines.fold<int>(
    0,
    (int sum, CartCheckoutLine line) => sum + line.subtotal,
  );

  /// Baris yang siap dipesan dalam bentuk baris pesan WhatsApp.
  ///
  /// Satuan periode dikirim sebagai kata ([CartCheckoutLine.periodWord]); `null`
  /// berarti pemilik belum menetapkan periode, sehingga pesan hanya menulis
  /// angka Rupiah tanpa periode yang dikarang.
  List<WhatsAppOrderLine> toWhatsAppLines() => usableLines
      .map(
        (CartCheckoutLine line) => WhatsAppOrderLine(
          name: line.name,
          brand: line.brand,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          periodLabel: line.periodWord,
        ),
      )
      .toList(growable: false);

  /// Total estimasi siap tampil, mis. `Rp250.000 / hari`.
  ///
  /// Memakai [WhatsAppOrderMessage.totalText] supaya angka di layar dan angka di
  /// pesan checkout tidak pernah berbeda. Periode hanya ditulis bila seluruh
  /// baris siap pesan memakai satuan yang sama.
  String get totalText =>
      WhatsAppOrderMessage(lines: toWhatsAppLines()).totalText;

  /// Pesan permintaan sewa siap kirim ke WhatsApp (blueprint §7 langkah 6).
  ///
  /// Prasyarat: [isReady] — ada baris dan tidak ada masalah. Bila prasyarat itu
  /// tidak dipenuhi, [WhatsAppMessageBuilder.build] melempar [ArgumentError]:
  /// pemanggil harus menampilkan baris bermasalah lebih dulu, bukan mengirim
  /// pesan yang memuat harga snapshot yang belum terverifikasi.
  String buildWhatsAppMessage({String? customerName}) =>
      WhatsAppMessageBuilder.build(
        WhatsAppOrderMessage(
          lines: toWhatsAppLines(),
          customerName: customerName,
        ),
      );

  static CartCheckoutLine _validateLine(CartItem item, Product? product) {
    if (product == null) {
      return CartCheckoutLine(
        productId: item.productId,
        name: _snapshotName(item),
        brand: item.brandSnapshot,
        imageUrl: item.imageUrlSnapshot,
        quantity: item.quantity,
        unitPrice: item.unitPriceSnapshot,
        priceUnit: item.priceUnitSnapshot,
        issue: const CartCheckoutIssue(
          kind: CartCheckoutIssueKind.productMissing,
          message:
              'Alat ini sudah tidak ada di katalog, sehingga tidak dapat '
              'dipesan. Hapus dari keranjang untuk melanjutkan.',
        ),
      );
    }

    // Nama, brand, foto, harga, dan stok baris yang produknya masih ada selalu
    // diambil dari dokumen terbaru, bukan dari snapshot keranjang.
    CartCheckoutLine line({
      required int quantity,
      required int unitPrice,
      required PriceUnit priceUnit,
      CartCheckoutIssue? issue,
    }) => CartCheckoutLine(
      productId: product.id,
      name: product.name,
      brand: product.brand,
      imageUrl: product.primaryImageUrl ?? '',
      quantity: quantity,
      unitPrice: unitPrice,
      priceUnit: priceUnit,
      availableStock: product.stockQuantity,
      issue: issue,
    );

    if (!product.isActive) {
      return line(
        quantity: item.quantity,
        unitPrice: product.price,
        priceUnit: product.priceUnit,
        issue: const CartCheckoutIssue(
          kind: CartCheckoutIssueKind.productInactive,
          message:
              'Alat ini sudah tidak dipasarkan, sehingga tidak dapat dipesan. '
              'Hapus dari keranjang untuk melanjutkan.',
        ),
      );
    }

    if (product.price <= 0) {
      return line(
        quantity: item.quantity,
        unitPrice: product.price,
        priceUnit: product.priceUnit,
        issue: const CartCheckoutIssue(
          kind: CartCheckoutIssueKind.priceNotConfigured,
          message:
              'Admin belum mengisi harga alat ini, sehingga total sewa belum '
              'dapat dihitung. Hapus baris ini atau hubungi admin.',
        ),
      );
    }

    final snapshotPrice = PriceDisplay.fromAmount(
      item.unitPriceSnapshot,
      item.priceUnitSnapshot,
    ).text;
    final currentPrice = PriceDisplay.fromAmount(
      product.price,
      product.priceUnit,
    ).text;

    if (product.price != item.unitPriceSnapshot) {
      return line(
        quantity: item.quantity,
        unitPrice: product.price,
        priceUnit: product.priceUnit,
        issue: CartCheckoutIssue(
          kind: CartCheckoutIssueKind.priceChanged,
          message:
              'Harga berubah dari $snapshotPrice menjadi $currentPrice. '
              'Perbarui harga di keranjang sebelum checkout.',
        ),
      );
    }

    if (product.priceUnit != item.priceUnitSnapshot) {
      return line(
        quantity: item.quantity,
        unitPrice: product.price,
        priceUnit: product.priceUnit,
        issue: CartCheckoutIssue(
          kind: CartCheckoutIssueKind.priceUnitChanged,
          message:
              'Satuan harga berubah dari $snapshotPrice menjadi $currentPrice. '
              'Perbarui keranjang sebelum checkout.',
        ),
      );
    }

    if (item.quantity > product.stockQuantity) {
      final stock = product.stockQuantity;
      return line(
        quantity: item.quantity,
        unitPrice: product.price,
        priceUnit: product.priceUnit,
        issue: CartCheckoutIssue(
          kind: CartCheckoutIssueKind.insufficientStock,
          message: stock < 1
              ? 'Stok alat ini sedang habis, sehingga jumlah di keranjang tidak '
                    'dapat dipenuhi. Hapus dari keranjang untuk melanjutkan.'
              : 'Stok terbaru hanya $stock, sedangkan keranjang meminta '
                    '${item.quantity}. Turunkan jumlah atau hapus baris ini.',
        ),
      );
    }

    return line(
      quantity: item.quantity,
      unitPrice: product.price,
      priceUnit: product.priceUnit,
    );
  }

  /// Nama snapshot; document ID dipakai apa adanya bila snapshot kosong.
  static String _snapshotName(CartItem item) {
    final name = item.productNameSnapshot.trim();
    return name.isEmpty ? item.productId : name;
  }
}
