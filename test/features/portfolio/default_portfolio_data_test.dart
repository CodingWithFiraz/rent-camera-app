import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/utils/external_url.dart';
import 'package:rent_camera_app/features/catalog/domain/price_unit.dart';
import 'package:rent_camera_app/features/portfolio/data/default_portfolio_data.dart';

void main() {
  group('DefaultPortfolioData', () {
    test('memiliki tepat 4 kelompok layanan aktif dan terurut', () {
      final rates = DefaultPortfolioData.serviceRates;
      expect(rates.length, 4);

      for (var i = 0; i < rates.length; i++) {
        final rate = rates[i];
        expect(rate.id, isNotEmpty);
        expect(rate.title, isNotEmpty);
        expect(rate.description, isNotEmpty);
        expect(rate.sortOrder, i + 1);
        expect(rate.isActive, isTrue);
        expect(rate.hasConfiguredRate, isTrue);
        expect(rate.deliverables, isNotEmpty);
        expect(rate.priceUnit, PriceUnit.perSession);
      }
    });

    test('memiliki tepat 2 kreator aktif dengan tautan portofolio valid', () {
      final creatives = DefaultPortfolioData.creatives;
      expect(creatives.length, 2);

      for (var i = 0; i < creatives.length; i++) {
        final creative = creatives[i];
        expect(creative.id, isNotEmpty);
        expect(creative.name, isNotEmpty);
        expect(creative.roleTitle, isNotEmpty);
        expect(creative.specialties, isNotEmpty);
        expect(creative.sortOrder, i + 1);
        expect(creative.isActive, isTrue);
        expect(creative.hasPortfolioUrl, isTrue);
        expect(ExternalUrl.isValid(creative.portfolioUrl), isTrue);
      }
    });
  });
}

