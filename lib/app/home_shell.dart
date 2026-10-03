import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/art/art_catalog.dart' show ArtImageRef;
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
import '../state/app_session.dart';
import '../state/premium_store.dart';
import '../state/travel_documents_store.dart';
import '../state/travel_store.dart';
import 'route_observer.dart';
import 'trip_chrome_scope.dart';

/// The four tabs plus the add button, on the focused trip's palette and
/// linen. Also shows background sync errors.
///
/// The tabs are pages of one [PageView]: choosing a tab slides the pages
/// sideways through every tab in between, with a slight overshoot
/// ([NavLayout.switchCurve]) before settling. Swiping between tabs is off;
/// only the nav bar changes tab. The nav bar stays put while the pages move.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.weather});

  /// Today's forecast for the header pill, when one is available.
  final WeatherReport? weather;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver, RouteAware {
  static const _items = [
    NavItem('Today', IconSlot.navToday),
    NavItem('Trips', IconSlot.navTrips),
    // The ticket wallet: every booking's tickets and documents.
    NavItem('Documents', IconSlot.navDocuments),
    NavItem('Profile', IconSlot.navProfile),
  ];

  int _index = 0;
  final _pages = PageController();

  /// Ticks each time Today comes back into view: its tab is chosen, the
  /// app returns from the background, or a screen over it closes. Its
  /// countdown replays its entry.
  final _todayShown = ValueNotifier<int>(0);
  bool _wasAway = false;
  late final TravelStore _store;

  late final PremiumStore _premium;
  late final TravelDocumentsStore _documents;

  @override
  void initState() {
    super.initState();
    _store = context.read<TravelStore>()..addListener(_showErrors);
    _premium = context.read<PremiumStore>()..addListener(_premiumChanged);
    _documents = context.read<TravelDocumentsStore>();
    // After switching account the app is rebuilt: say what happened.
    final notice = context.read<AppSession>().takeNotice();
    if (notice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notice)));
      });
    }
    // Tickets are backed up for shared trips and for trips with Plus.
    _store.shouldBackUp = (plan) => plan.trip.isShared || _premium.forTrip(plan).allowed;
    WidgetsBinding.instance.addObserver(this);
  }

  /// Back from the background: new art packs may be out (and a download
  /// that failed offline can finish now). Into the background: the travel
  /// documents lock again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _store.refreshArtPacksIfStale();
      // Back from the background, not just from Control Centre.
      if (_wasAway) _showedToday();
      _wasAway = false;
    }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _documents.lock();
      _wasAway = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context) case final PageRoute<dynamic> route) appRouteObserver.subscribe(this, route);
  }

  /// A screen opened over the home tabs has closed.
  @override
  void didPopNext() => _showedToday();

  void _showedToday() {
    if (_index == 0) _todayShown.value++;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _todayShown.dispose();
    _store.removeListener(_showErrors);
    _premium.removeListener(_premiumChanged);
    _pages.dispose();
    super.dispose();
  }

  /// The nav highlights the chosen tab at once while the pages slide to it
  /// (or jump, with reduced motion). Rapid taps restart the slide from
  /// wherever the pages are.
  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    // Today's countdown starts its entry as its page slides in.
    _showedToday();
    if (!_pages.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(index, duration: NavLayout.switchDuration, curve: NavLayout.switchCurve);
    }
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
    final screens = [
      TodayScreen(weather: widget.weather, shown: _todayShown),
      const TripsScreen(),
      const WalletScreen(),
      const ProfileScreen(),
    ];
    return LayoutBuilder(
      builder: (context, box) => DecoratedBox(
        decoration: _linenDecoration(linen),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: PageView(
            controller: _pages,
            physics: const NeverScrollableScrollPhysics(),
            children: [for (final screen in screens) _TabPage(linen: linen, linenHeight: box.maxHeight, child: screen)],
          ),
          bottomNavigationBar: TravaryNavBar(
            items: _items,
            selectedIndex: _index,
            onSelected: _select,
            onAdd: () => startAddBooking(context, date: _store.focus.day),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _linenDecoration(ArtImageRef? linen) => BoxDecoration(
  color: TravaryColors.linen,
  image: linen == null ? null : DecorationImage(image: artImageProvider(linen), repeat: ImageRepeat.repeat, scale: 3),
);

/// One tab. It paints its own linen, so the page slides as a whole card and
/// nothing shows through during the overshoot, and it stays alive when
/// scrolled away (a [PageView] builds only the pages in view), so each tab
/// keeps its scroll position and anything typed.
///
/// The linen is laid out at the shell's full height (the page stops above the
/// nav bar), so its tiles line up with the linen behind the nav bar.
class _TabPage extends StatefulWidget {
  const _TabPage({required this.linen, required this.linenHeight, required this.child});

  final ArtImageRef? linen;
  final double linenHeight;
  final Widget child;

  @override
  State<_TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<_TabPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: widget.linenHeight,
          child: DecoratedBox(decoration: _linenDecoration(widget.linen)),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
