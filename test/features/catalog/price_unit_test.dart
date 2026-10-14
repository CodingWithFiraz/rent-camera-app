import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/features/catalog/domain/price_unit.dart';

void main() {
  group('PriceUnit.fromStorage', () {
    test('memetakan nilai yang dikenal', () {
      expect(PriceUnit.fromStorage('per_day'), PriceUnit.perDay);
      expect(PriceUnit.fromStorage('per_session'), PriceUnit.perSession);
      expect(PriceUnit.fromStorage(' per_day '), PriceUnit.perDay);
    });

    test('nilai kosong, bukan teks, atau tak dikenal menjadi unspecified', () {
      expect(PriceUnit.fromStorage(null), PriceUnit.unspecified);
      expect(PriceUnit.fromStorage(''), PriceUnit.unspecified);
      expect(PriceUnit.fromStorage(42), PriceUnit.unspecified);
      expect(PriceUnit.fromStorage('per_hari'), PriceUnit.unspecified);
    });

    test('hanya satuan yang dikenal yang dianggap terkonfigurasi', () {
      expect(PriceUnit.perDay.isConfigured, isTrue);
      expect(PriceUnit.perSession.isConfigured, isTrue);
      expect(PriceUnit.unspecified.isConfigured, isFalse);
    });
  });
}
