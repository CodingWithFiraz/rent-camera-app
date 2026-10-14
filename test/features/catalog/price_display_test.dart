import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/features/catalog/domain/price_display.dart';
import 'package:rent_camera_app/features/catalog/domain/price_unit.dart';
import 'package:rent_camera_app/features/catalog/domain/product.dart';

Product _product({
  required int price,
  PriceUnit priceUnit = PriceUnit.unspecified,
}) => Product(
  id: 'p1',
  name: 'Lumix G85',
  categoryId: 'kamera',
  brand: 'Panasonic',
  price: price,
  priceUnit: priceUnit,
);

void main() {
  test('harga terisi ditampilkan sebagai Rupiah dengan satuan periode', () {
    final display = PriceDisplay.fromAmount(150000, PriceUnit.perDay);

    expect(display.amountText, 'Rp150.000');
    expect(display.hasAmount, isTrue);
    expect(display.periodLabel, '/hari');
    expect(display.text, 'Rp150.000/hari');
  });

  test('harga nol berarti belum diisi, bukan gratis', () {
    final display = PriceDisplay.fromAmount(0, PriceUnit.perDay);

    expect(display.amountText, 'Harga belum diisi');
    expect(display.hasAmount, isFalse);
    // Satuan tidak boleh digabungkan pada harga yang belum diisi: teks
    // "Harga belum diisi/hari" akan terbaca sebagai periode yang sudah pasti.
    expect(display.text, 'Harga belum diisi');
    expect(display.text, isNot(contains('Rp')));
  });

  test('label periode hanya muncul bila satuan ditetapkan dokumen', () {
    final perSession = PriceDisplay.fromAmount(200000, PriceUnit.perSession);
    final unspecified = PriceDisplay.fromAmount(200000, PriceUnit.unspecified);

    expect(perSession.periodLabel, '/sesi');
    expect(unspecified.hasPeriodLabel, isFalse);
    expect(unspecified.periodLabel, isNull);
    expect(unspecified.text, 'Rp200.000');
  });

  test('forProduct memakai harga dan satuan milik produk', () {
    final perDay = PriceDisplay.forProduct(
      _product(price: 250000, priceUnit: PriceUnit.perDay),
    );
    final belumDiatur = PriceDisplay.forProduct(_product(price: 250000));

    expect(perDay.text, 'Rp250.000/hari');
    expect(belumDiatur.text, 'Rp250.000');
    expect(belumDiatur.hasAmount, isTrue);
  });
}
