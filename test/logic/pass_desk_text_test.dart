import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/onboarding_journey.dart';
import 'package:travary/logic/price_text.dart';

void main() {
  test('the passes are always Annual Pass and Holiday Pass, whatever the store calls them', () {
    const plus = Offer(
      kind: OfferKind.plusAnnual,
      productId: 'p',
      amount: 34.99,
      currencyCode: 'USD',
      title: 'Travary Annual Holiday Pass',
    );
    const pass = Offer(
      kind: OfferKind.tripPass,
      productId: 'h',
      amount: 14.99,
      currencyCode: 'USD',
      title: 'Travary Holiday Pass',
    );
    expect((plus.displayTitle, pass.displayTitle), ('Annual Pass', 'Holiday Pass'));
  });

  test('benefits lead with unlimited bookings and the family, or with what they reached for', () {
    expect(passBenefits(), [
      'Unlimited bookings, and the plan on every phone',
      'Every ticket and confirmation kept and backed up (free keeps 2)',
      "I'll read the rest of your confirmations for you",
    ]);
    // All most phones have room for: one line on an iPhone 13 mini.
    expect(passBenefits().first.length, lessThanOrEqualTo(51));
    expect(passBenefits(first: PremiumFeature.smartImport).first, "I'll read the rest of your confirmations for you");
    expect(passBenefits(first: PremiumFeature.smartImport), hasLength(3));
    for (final feature in [PremiumFeature.everyBooking, PremiumFeature.familySharing]) {
      expect(passBenefits(first: feature), passBenefits(), reason: '${feature.name} shares the first line');
    }
    // Flight alerts only once they're on sale.
    expect(passBenefits(flightAlerts: true).last, "Delays and new times on everyone's phone");
    expect(passBenefits(first: PremiumFeature.flightAlerts), hasLength(3), reason: 'not on sale: not listed');
  });

  test('the paywall asks about what they reached for', () {
    String headline(PremiumFeature? feature) {
      final words = paywallWordsFor(feature);
      return '${words.text}${words.accent}'.replaceAll('\n', ' ');
    }

    expect(headline(PremiumFeature.familySharing), 'Bring everyone along?');
    expect(headline(PremiumFeature.everyBooking), 'Room for every booking?');
    expect(paywallWordsFor(PremiumFeature.everyBooking).subtitle, 'A pass makes room for the whole plan.');
    expect(headline(PremiumFeature.ticketBackup), 'Every ticket, kept safe?');
    expect(headline(PremiumFeature.smartImport), 'Shall I read the rest?');
    expect(headline(PremiumFeature.flightAlerts), 'Shall I watch your flights?');
    expect(headline(null), 'Shall I help with the rest?');
  });
}
