import 'local_date.dart';
import 'pricing.dart';

/// Everything the Annual Pass (or a Holiday Pass) unlocks.
///
/// Rule of the house: a traveller's own tickets and bookings are never
/// behind a paywall. Only these extras are.
///
/// Family first: what people pay for is everyone having the plan and their
/// own tickets, and nothing lost with a phone. Smart Import is a bonus.
enum PremiumFeature {
  familySharing(
    title: 'Family sharing',
    benefit: 'Up to 6 people on the plan, each with their own tickets offline and the same packing list to tick',
    pillar: PremiumPillar.together,
  ),
  ticketBackup(
    title: 'Every ticket',
    benefit: 'Attach every ticket and confirmation (free holidays keep 2), backed up and on any phone you sign in to',
    pillar: PremiumPillar.peaceOfMind,
  ),
  smartImport(
    title: 'Smart Import',
    benefit: 'Snap a screenshot or PDF and the booking fills itself in',
    pillar: PremiumPillar.time,
  ),
  flightAlerts(
    title: 'Flight alerts',
    benefit: 'Delays, new times and cancellations the moment they happen, on everyone\'s phone',
    pillar: PremiumPillar.peaceOfMind,
  );

  const PremiumFeature({required this.title, required this.benefit, required this.pillar});

  final String title;
  final String benefit;
  final PremiumPillar pillar;

  /// Whether the feature is built and shipping. The paywall only sells
  /// released features (debug builds also show the rest, marked "Soon").
  bool get released => switch (this) {
    smartImport || familySharing || ticketBackup => true,
    flightAlerts => flightAlertsReleased,
  };
}

/// Flight alerts are on sale in every build (the server's checker is
/// deployed). `--dart-define=TRAVARY_FLIGHT_ALERTS=false` hides them, a
/// build-time kill switch. iOS needs the APNs key in Firebase before a build
/// reaches anyone, or its phones are sold alerts that never arrive.
const flightAlertsReleased = bool.fromEnvironment('TRAVARY_FLIGHT_ALERTS', defaultValue: true);

/// The three reasons people pay, most important first, used to group the
/// paywall.
enum PremiumPillar {
  together('Keeps everyone together'),
  peaceOfMind('Has your back'),
  time('Saves you time');

  const PremiumPillar(this.label);

  final String label;
}

/// An Annual Pass subscription (yearly, no free trial: premium features
/// sell themselves where they're needed).
class PlusSubscription {
  const PlusSubscription({required this.expiresAt, this.willRenew = true});

  /// End of the current year.
  final DateTime expiresAt;
  final bool willRenew;

  bool activeAt(DateTime now) => now.isBefore(expiresAt);
}

/// A Trip Pass: Plus on one trip of at most [Pricing.tripPassMaxDays],
/// bought for the dates it had then, until [Pricing.tripPassGraceDays]
/// after. It grows with the same holiday but can't be carried over to
/// another one by changing the trip's dates or place (the rule is
/// `tripPassLastDay` in `logic/access.dart`).
class TripPass {
  const TripPass({required this.tripId, required this.start, required this.end});

  final String tripId;
  final LocalDate start;
  final LocalDate end;

  /// A week after the dates it was bought for: the last day Plus is on
  /// unless the trip has grown since.
  LocalDate get lastDay => end.addDays(Pricing.tripPassGraceDays);

  @override
  bool operator ==(Object other) =>
      other is TripPass && other.tripId == tripId && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(tripId, start, end);

  @override
  String toString() => 'TripPass($tripId, $start → $end)';
}

/// What the signed-in traveller has bought, and how much of the free
/// allowance they've used.
///
/// In production this comes from the store via RevenueCat and is mirrored to
/// `users/{uid}` by a server function. The app never writes it itself.
class Entitlements {
  const Entitlements({this.plus, this.tripPasses = const {}, this.smartImportsUsed = 0});

  static const none = Entitlements();

  final PlusSubscription? plus;

  /// The Trip Passes this traveller bought, by trip id.
  final Map<String, TripPass> tripPasses;

  /// Free Smart Imports used so far (only counts while on the free plan).
  final int smartImportsUsed;

  /// What the server mirrored to `users/{uid}`: `plus` {expiresAt (ms),
  /// willRenew}, `tripPasses` {tripId: {start, end}} (the dates each pass was
  /// claimed for) and `smartImport.total`. Anything malformed is skipped.
  static Entitlements fromUserRecord(Map<String, Object?>? json) {
    if (json == null) return none;
    final passes = <String, TripPass>{};
    final rawPasses = json['tripPasses'];
    if (rawPasses is Map) {
      for (final MapEntry(:key, :value) in rawPasses.entries) {
        if (value is! Map) continue;
        final start = LocalDate.tryParse(value['start']);
        final end = LocalDate.tryParse(value['end']);
        if (start == null || end == null || end.isBefore(start)) continue;
        passes['$key'] = TripPass(tripId: '$key', start: start, end: end);
      }
    }
    final plus = json['plus'];
    final expiresAt = plus is Map ? plus['expiresAt'] : null;
    final usage = json['smartImport'];
    final used = usage is Map ? usage['total'] : null;
    return Entitlements(
      plus: plus is Map && expiresAt is num
          ? PlusSubscription(
              expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt.toInt()),
              willRenew: plus['willRenew'] != false,
            )
          : null,
      tripPasses: passes,
      smartImportsUsed: used is num ? used.toInt() : 0,
    );
  }

  Entitlements copyWith({
    PlusSubscription? plus,
    bool clearPlus = false,
    Map<String, TripPass>? tripPasses,
    int? smartImportsUsed,
  }) {
    return Entitlements(
      plus: clearPlus ? null : (plus ?? this.plus),
      tripPasses: tripPasses ?? this.tripPasses,
      smartImportsUsed: smartImportsUsed ?? this.smartImportsUsed,
    );
  }
}

/// Plus that travels with a trip: stamped on the trip by the server when its
/// organiser has Plus or bought a Trip Pass, so everyone invited to the trip
/// gets the Plus features on it too.
///
/// Clients can read this but never write it (see `firestore.rules`).
class TripPremium {
  const TripPremium({required this.grantedBy, required this.until});

  /// The traveller whose Plus or Trip Pass unlocked the trip.
  final String grantedBy;
  final DateTime until;

  bool activeAt(DateTime now) => now.isBefore(until);

  static TripPremium? fromJson(Object? json) {
    if (json is! Map) return null;
    final until = json['until'];
    if (until is! num) return null;
    return TripPremium(
      grantedBy: '${json['grantedBy'] ?? ''}',
      until: DateTime.fromMillisecondsSinceEpoch(until.toInt()),
    );
  }
}
