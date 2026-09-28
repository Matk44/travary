import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/art/art_slots.dart';
import '../design/cards/card_parts.dart';
import '../design/tokens.dart';
import '../design/trip_chrome.dart';
import '../design/widgets/nav_bar.dart';
import '../domain/domain.dart';
import '../features/booking/booking_actions.dart';
import '../features/profile/profile_screen.dart';
import '../features/today/today_screen.dart';
import '../features/trips/trips_screen.dart';
import '../features/wallet/wallet_screen.dart';
import '../state/premium_store.dart';
import '../state/travel_store.dart';
import 'trip_chrome_scope.dart';

/// The four tabs plus the add button, on the focused trip's palette and
/// linen. Also shows background sync errors.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.weather});

  /// Today's forecast for the header pill, when one is available.
  final WeatherReport? weather;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  static const _items = [
    NavItem('Today', IconSlot.navToday),
    NavItem('Trips', IconSlot.navTrips),
    // The ticket wallet: every booking's tickets and documents.
    NavItem('Documents', IconSlot.navDocuments),
    NavItem('Profile', IconSlot.navProfile),
  ];

  int _index = 0;
  late final TravelStore _store;

  late final PremiumStore _premium;

  @override
  void initState() {
    super.initState();
    _store = context.read<TravelStore>()..addListener(_showErrors);
    _premium = context.read<PremiumStore>()..addListener(_premiumChanged);
    // Tickets are backed up for shared trips and for trips with Plus.
    _store.shouldBackUp = (plan) => plan.trip.isShared || _premium.forTrip(plan).allowed;
    WidgetsBinding.instance.addObserver(this);
  }

  /// Back from the background: new art packs may be out (and a download
  /// that failed offline can finish now).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _store.refreshArtPacksIfStale();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.removeListener(_showErrors);
    _premium.removeListener(_premiumChanged);
    super.dispose();
  }

  /// Buying Plus backs up existing tickets straight away.
  void _premiumChanged() => _store.syncTickets();

  void _showErrors() {
    final error = _store.error;
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    _store.clearError();
  }

  @override
  Widget build(BuildContext context) {
    return TripChromeScope(child: Builder(builder: (context) => _body(context)));
  }

  Widget _body(BuildContext context) {
    final linen = TravaryChrome.of(context).slots.surface(SurfaceSlot.linen);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TravaryColors.linen,
        image: linen == null
            ? null
            : DecorationImage(image: artImageProvider(linen), repeat: ImageRepeat.repeat, scale: 3),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _index,
          children: [
            TodayScreen(weather: widget.weather),
            const TripsScreen(),
            const WalletScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: TravaryNavBar(
          items: _items,
          selectedIndex: _index,
          onSelected: (index) => setState(() => _index = index),
          onAdd: () => startAddBooking(context, date: _store.focus.day),
        ),
      ),
    );
  }
}
