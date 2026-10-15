/// Asking before anything goes to Google's Gemini AI (Apple's guideline
/// 5.1.2(i): say clearly what goes to a third-party AI, and get explicit
/// permission first). One answer on this phone covers both uses: Smart
/// Import (the file chosen) and automatic trip looks (trip names, and
/// bookings' names and places). Travel documents never go to any AI.
///
/// Where it's asked: Smart Import, before the file is chosen (or a shared
/// one is read); a trip's page, which offers automatic looks once it has a
/// booking; Trip details' "Automatic" look; and Profile's switch. Never at
/// launch.
library;

import '../domain/ai_consent.dart';
import '../domain/booking.dart';
import '../domain/trip.dart';

/// What the traveller was doing when asked.
enum AiAsk {
  /// Smart Import, before the file goes.
  smartImport,

  /// A trip's page offering automatic looks, or Trip details' "Automatic".
  tripLooks,

  /// Profile's switch.
  settings,
}

/// The sheet's words for [AiAsk]: the ticket's band, its question and the
/// line under it. What's sent is the same whatever asked ([aiSentWords]).
typedef AiConsentWords = ({String band, String title, String lead});

AiConsentWords aiConsentWordsFor(AiAsk ask) => switch (ask) {
  AiAsk.smartImport => (
    band: 'SMART IMPORT',
    title: 'May I ask Google’s AI to read it?',
    lead: 'Gemini reads the booking in your file, and you check it before anything’s saved.',
  ),
  AiAsk.tripLooks => (
    band: 'TRIP LOOKS',
    title: 'May I ask Google’s AI to dress up your trips?',
    lead: 'Gemini picks each trip’s look from where it goes and what you’ve booked.',
  ),
  AiAsk.settings => (
    band: 'GOOGLE’S AI',
    title: 'May I ask Google’s AI to help?',
    lead: 'Gemini reads the bookings you import and picks each trip’s look.',
  ),
};

/// What goes to Gemini once allowed, whichever asked: one answer covers
/// both.
const aiSentLabel = 'SENT TO GOOGLE’S GEMINI';
const aiSentWords =
    'Files you choose for Smart Import. Your trips’ names, and your bookings’ names and places, for each '
    'trip’s look.';

/// What never goes, allowed or not.
const aiNeverSentLabel = 'NEVER SENT';
const aiNeverSentWords = 'Passports, visas and your other travel documents. They stay on this phone.';

const aiFinePrint =
    'Files aren’t kept on our servers or used to improve Google’s products. Change this any time in Profile.';

/// Written on the card Travi holds up over the sheet.
const aiConsentSign = 'MAY I?';

/// Profile's switch.
const aiSettingTitle = 'Smart Import and trip looks';
const aiSettingCopy =
    'Files you import, and your trips’ and bookings’ names and places, go to Google’s Gemini AI. Never your '
    'travel documents.';

/// The offer on a trip's page.
const aiLooksOfferTitle = 'Dress up this trip?';
const aiLooksOfferCopy = 'Google’s AI can pick its look from where it goes and what you’ve booked.';

/// Whether [trip]'s page offers automatic looks: they're available (cloud
/// trips), it's still the traveller's first answer, the trip's look is
/// automatic, and it has a booking to go by.
bool offersTripLooks({
  required AiConsent consent,
  required bool available,
  required Trip trip,
  required Iterable<Booking> bookings,
}) => available && consent == AiConsent.undecided && trip.isAutomaticLook && bookings.isNotEmpty;
