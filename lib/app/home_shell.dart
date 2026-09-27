import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/widgets/nav_bar.dart';
import '../features/booking/booking_actions.dart';
import '../features/profile/profile_screen.dart';
import '../features/today/today_screen.dart';
import '../features/trips/trips_screen.dart';
import '../features/wallet/wallet_screen.dart';
import '../state/premium_store.dart';
import '../state/travel_store.dart';

/// The four tabs plus the add button. Also shows background sync errors.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _items = [
    NavItem('Today', Icons.wb_sunny_outlined, Icons.wb_sunny_rounded),
    NavItem('Trips', Icons.luggage_outlined, Icons.luggage_rounded),
    NavItem('Wallet', Icons.confirmation_number_outlined, Icons.confirmation_number_rounded),
    NavItem('Profile', Icons.person_outline_rounded, Icons.person_rounded),
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
  }

  @override
  void dispose() {
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
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [TodayScreen(), TripsScreen(), WalletScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: TravaryNavBar(
        items: _items,
        selectedIndex: _index,
        onSelected: (index) => setState(() => _index = index),
        onAdd: () => startAddBooking(context, date: _store.focus.day),
      ),
    );
  }
}
