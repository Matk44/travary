import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:travary/data/revenuecat_offer_catalog.dart';
import 'package:travary/domain/pricing.dart';
import 'package:travary/logic/price_text.dart';

void main() {
  rc.Package package(String id, {bool annual = false, String? period, String price = '14,99 €'}) => rc.Package(
    id,
    annual ? rc.PackageType.annual : rc.PackageType.custom,
    rc.StoreProduct(
      'store_$id',
      'Description',
      'Store title',
      14.99,
      price,
      'EUR',
      productCategory: annual ? rc.ProductCategory.subscription : rc.ProductCategory.nonSubscription,
      subscriptionPeriod: annual ? period ?? 'P1Y' : null,
    ),
    const rc.PresentedOfferingContext('onboarding', null, null),
  );
  rc.Offering offering(Map<String, Object> metadata, List<rc.Package> packages) => rc.Offering(
    'onboarding',
    'Current remote offer',
    metadata,
    packages,
    annual: packages.where((p) => p.packageType == rc.PackageType.annual).firstOrNull,
  );

  test('remote package mapping, title and scope use the authoritative store-formatted price', () {
    final offers = offersFromRevenueCat(
      offering(
        {
          'pass_desk': {
            'holiday': {
              'package': 'summer_holiday',
              'title': 'Family Holiday Pass',
              'scope': 'This trip, together',
              'price': '0.99',
            },
            'annual': {'package': 'yearly', 'title': 'Annual Pass', 'scope': 'Holidays through the year'},
          },
        },
        [package('summer_holiday'), package('yearly', annual: true, price: '49,50 €')],
      ),
    );
    expect(offers, hasLength(2));
    expect(offers.first.kind, OfferKind.tripPass);
    expect(offers.first.productId, 'store_summer_holiday');
    expect(offers.first.packageId, 'summer_holiday');
    expect(offers.first.offeringId, 'onboarding');
    expect(offers.first.displayTitle, 'Family Holiday Pass');
    expect(offers.first.displayScope, 'This trip, together');
    expect(priceOf(offers.first), '14,99 €');
    expect(offers.first.amount, 14.99);
    expect(priceOf(offers.last), '49,50 €');
  });

  test('remote removal, missing mappings and disabled passes never invent a product', () {
    final config = {
      'pass_desk': {
        'holiday': {'package': 'removed'},
        'annual': {'package': 'yearly', 'enabled': false},
      },
    };
    expect(offersFromRevenueCat(offering(config, [package('yearly', annual: true)])), isEmpty);
    expect(offersFromRevenueCat(offering(const {}, const [])), isEmpty);
  });

  test('monthly products cannot be sold as annual and subscriptions cannot be sold as one-off', () {
    expect(
      offersFromRevenueCat(
        offering(
          {
            'pass_desk': {
              'holiday': {'package': 'monthly'},
              'annual': {'package': 'monthly'},
            },
          },
          [package('monthly', annual: true, period: 'P1M')],
        ),
      ),
      isEmpty,
    );
  });

  test('an annual package can use its store title when no custom metadata exists', () {
    final offers = offersFromRevenueCat(offering(const {}, [package('yearly', annual: true)]));
    expect(offers.single.kind, OfferKind.plusAnnual);
    expect(offers.single.displayTitle, 'Store title');
  });
}
