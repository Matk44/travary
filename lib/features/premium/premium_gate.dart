import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/domain.dart';
import '../../logic/access.dart';
import '../../logic/trip_plan.dart';
import '../../state/premium_store.dart';
import 'paywall_screen.dart';

/// The one way into a premium feature:
///
///     final access = await requirePremium(context, PremiumFeature.smartImport,
///         trip: plan, source: 'add_sheet');
///     if (access == null) return;
///
/// Returns the access decision when the feature may be used (straight away,
/// via a free use, or after buying on the paywall), or null if not.
Future<AccessDecision?> requirePremium(
  BuildContext context,
  PremiumFeature feature, {
  TripPlan? trip,
  required String source,
}) async {
  final premium = context.read<PremiumStore>();
  final before = premium.decide(feature, trip: trip);
  if (before.allowed) return before;

  final bought = await showPaywall(context, feature: feature, tripId: trip?.id, source: source);
  if (!bought) return null;
  final after = premium.decide(feature, trip: trip);
  return after.allowed ? after : null;
}

/// Room on [plan] for [adding] more ticket files, which keeps [kept]
/// already (`ticketFilesIn`): free holidays keep [Pricing.freeTicketFiles],
/// a pass or Plus any number. Opens the paywall once they're used. True
/// when the files can be added. Files already attached are never touched.
Future<bool> requireTicketRoom(
  BuildContext context,
  TripPlan? plan, {
  required int kept,
  int adding = 1,
  required String source,
}) async {
  final premium = context.read<PremiumStore?>();
  if (premium == null || premium.policy.canAttachTickets(plan, kept: kept, adding: adding)) return true;
  final bought = await showPaywall(context, feature: PremiumFeature.ticketBackup, tripId: plan?.id, source: source);
  return bought && premium.policy.canAttachTickets(plan, kept: kept, adding: adding);
}

/// Opens the paywall. Returns true if something was bought.
Future<bool> showPaywall(
  BuildContext context, {
  PremiumFeature? feature,
  String? tripId,
  required String source,
}) async {
  final bought = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PaywallScreen(feature: feature, tripId: tripId, source: source),
    ),
  );
  return bought ?? false;
}
