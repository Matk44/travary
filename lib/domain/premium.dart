/// Everything Travary Plus (or a Trip Pass) unlocks.
///
/// Rule of the house: a traveller's own tickets and bookings are never
/// behind a paywall. Only these extras are.
enum PremiumFeature {
  smartImport(
    title: 'Smart Import',
    benefit: 'Snap a screenshot or PDF and the booking fills itself in',
    pillar: PremiumPillar.time,
  ),
  familySharing(
    title: 'Family sharing',
    benefit: 'Up to 6 people plan together, with tickets on every phone',
    pillar: PremiumPillar.together,
  ),
  ticketBackup(
    title: 'Ticket backup',
    benefit: 'Tickets backed up and synced, even if you lose your phone',
    pillar: PremiumPillar.peaceOfMind,
  ),
  flightAlerts(
    title: 'Flight alerts',
    benefit: 'Delays and gate changes the moment they happen',
    pillar: PremiumPillar.peaceOfMind,
  );

  const PremiumFeature({required this.title, required this.benefit, required this.pillar});

  final String title;
  final String benefit;
  final PremiumPillar pillar;

  /// Whether the feature is built and shipping. The paywall only sells
  /// released features (debug builds also show the rest, marked "Soon").
  bool get released => switch (this) {
    smartImport => true,
    familySharing || ticketBackup || flightAlerts => false,
  };
}

/// The three reasons people pay, used to group the paywall.
enum PremiumPillar {
  time('Saves you time'),
  together('Keeps everyone together'),
  peaceOfMind('Has your back');

  const PremiumPillar(this.label);

  final String label;
}

/// A Travary Plus subscription (annual, 14-day free trial).
class PlusSubscription {
  const PlusSubscription({required this.expiresAt, this.inTrial = false, this.willRenew = true});

  /// End of the current period (or of the trial).
  final DateTime expiresAt;
  final bool inTrial;
  final bool willRenew;

  bool activeAt(DateTime now) => now.isBefore(expiresAt);
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

  /// Trips this traveller bought a Trip Pass for.
  final Set<String> tripPasses;

  /// Free Smart Imports used so far (only counts while on the free plan).
  final int smartImportsUsed;

  Entitlements copyWith({
    PlusSubscription? plus,
    bool clearPlus = false,
    Set<String>? tripPasses,
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
