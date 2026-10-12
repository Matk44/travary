import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/art/art_slots.dart';
import '../../design/tokens.dart';
import '../../design/widgets/ledger.dart';
import '../../domain/domain.dart';
import '../../logic/flight_alerts.dart';
import '../../logic/trip_plan.dart';
import '../../state/notifications_store.dart';
import '../../state/premium_store.dart';
import '../premium/premium_gate.dart';

/// Flight alerts on a flight's page: on (everyone on the trip hears the
/// moment it changes), off on this phone, or one tap from the paywall.
/// Opening a flight on a paid trip is when this phone is asked for
/// notifications, once (never at launch).
class FlightAlertsRow extends StatefulWidget {
  const FlightAlertsRow({super.key, required this.booking, required this.plan, required this.now});

  final Booking booking;
  final TripPlan? plan;
  final DateTime now;

  /// Whether [booking]'s page has the row: a flight alerts would cover, on
  /// a phone that can get them, once they're on sale.
  static bool showsFor(BuildContext context, Booking booking, LocalDate today) =>
      (PremiumFeature.flightAlerts.released || kDebugMode) &&
      (context.read<NotificationsStore?>()?.available ?? false) &&
      flightAlertsCover(booking, today);

  @override
  State<FlightAlertsRow> createState() => _FlightAlertsRowState();
}

class _FlightAlertsRowState extends State<FlightAlertsRow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_askIfNeeded()));
  }

  bool get _allowed =>
      context.read<PremiumStore?>()?.decide(PremiumFeature.flightAlerts, trip: widget.plan).allowed ?? false;

  /// The system's prompt, the first time a paid trip's flight is opened.
  Future<void> _askIfNeeded() async {
    final notifications = context.read<NotificationsStore>();
    if (notifications.permission == null) await notifications.refresh();
    if (!mounted) return;
    final ask = shouldAskForNotifications(
      allowed: _allowed,
      covered: flightAlertsCover(widget.booking, LocalDate.fromDateTime(widget.now)),
      permission: notifications.permission ?? NotificationPermission.denied,
    );
    if (ask) await notifications.ask();
  }

  Future<void> _onTap(FlightAlertsState state) async {
    switch (state) {
      case FlightAlertsState.locked:
        final access = await requirePremium(
          context,
          PremiumFeature.flightAlerts,
          trip: widget.plan,
          source: 'flight_page',
        );
        if (access != null && mounted) await _askIfNeeded();
      case FlightAlertsState.ask:
        await context.read<NotificationsStore>().ask();
      case FlightAlertsState.blocked:
        // Android may show its prompt once more; iOS only changes in Settings.
        if (defaultTargetPlatform == TargetPlatform.android) {
          await context.read<NotificationsStore>().ask();
        } else {
          await launchUrl(Uri.parse('app-settings:'));
        }
      case FlightAlertsState.on:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final permission = context.watch<NotificationsStore>().permission;
    context.watch<PremiumStore?>();
    final state = flightAlertsStateFor(allowed: _allowed, permission: permission ?? NotificationPermission.notAsked);
    final trip = widget.plan?.trip;
    final text = flightAlertsTextFor(
      state,
      flightNumber: widget.booking.detail(DetailKeys.flightNumber) ?? '',
      everyone: trip?.premium?.activeAt(widget.now) ?? false,
      shared: trip?.isShared ?? false,
    );
    return Padding(
      padding: const EdgeInsets.only(top: TravarySpace.lg),
      child: PaperPanel(
        child: PaperRow(
          key: const ValueKey('flight-alerts'),
          title: text.title,
          subtitle: text.subtitle,
          titleStyle: TravaryText.label.copyWith(fontSize: 16),
          leading: const RowIcon(IconSlot.flight),
          trailing: state == FlightAlertsState.on ? null : const Icon(Icons.chevron_right_rounded),
          onTap: state == FlightAlertsState.on ? null : () => unawaited(_onTap(state)),
        ),
      ),
    );
  }
}
