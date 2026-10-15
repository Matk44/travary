import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/ai_consent.dart';

import '../helpers.dart';

void main() {
  group('the question says who gets what (Apple 5.1.2(i))', () {
    test('every ask names Google’s Gemini AI', () {
      for (final ask in AiAsk.values) {
        final words = aiConsentWordsFor(ask);
        expect('${words.title} ${words.lead}', contains('Google’s'), reason: ask.name);
        expect(words.lead, contains('Gemini'), reason: ask.name);
        expect(words.band, words.band.toUpperCase(), reason: 'printed on the ticket’s band');
      }
    });

    test('what goes covers both uses, whichever asked', () {
      expect(aiSentLabel, contains('GEMINI'));
      expect(aiSentWords, contains('Files you choose for Smart Import'));
      expect(aiSentWords, contains('trips’ names'));
      expect(aiSentWords, contains('bookings’ names and places'));
      expect(aiSettingCopy, contains('Gemini'));
    });

    test('travel documents never go, and the answer can be changed', () {
      expect(aiNeverSentWords, contains('travel documents'));
      expect(aiSettingCopy, contains('Never your travel documents'));
      expect(aiFinePrint, contains('Profile'));
    });
  });

  group('a trip’s page offers automatic looks', () {
    final kyoto = trip('kyoto', title: 'Kyoto');
    final temple = [booking('temple', BookingKind.attraction, d(4, 6), tripId: 'kyoto')];

    bool offers({AiConsent consent = AiConsent.undecided, bool available = true, Trip? on, List<Booking>? bookings}) =>
        offersTripLooks(consent: consent, available: available, trip: on ?? kyoto, bookings: bookings ?? temple);

    test('until the traveller answers, once it has a booking', () {
      expect(kyoto.isAutomaticLook, isTrue);
      expect(offers(), isTrue);
      expect(offers(bookings: const []), isFalse, reason: 'nothing to go by yet');
    });

    test('never again once answered, either way', () {
      expect(offers(consent: AiConsent.allowed), isFalse);
      expect(offers(consent: AiConsent.declined), isFalse, reason: '"Not now" is for good; Profile keeps the switch');
    });

    test('not for a look the traveller chose, or without automatic looks (demo)', () {
      final chosen = kyoto.copyWith(theme: ExperienceTheme.alpine, themeSource: ThemeSource.manual);
      expect(offers(on: chosen), isFalse);
      expect(offers(available: false), isFalse);
    });
  });

  test('a stored answer reads back; anything else is asked again', () {
    for (final consent in AiConsent.values) {
      expect(AiConsent.parse(consent.name), consent);
    }
    expect(AiConsent.parse('maybe'), AiConsent.undecided);
    expect(AiConsent.parse(null), AiConsent.undecided);
  });
}
