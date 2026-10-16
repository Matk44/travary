import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/art/art_catalog.dart' show ArtImageRef;
import '../design/art/art_slots.dart';
import '../design/cards/card_parts.dart';
import '../design/tokens.dart';
import '../design/trip_chrome.dart';
import '../design/widgets/nav_bar.dart';
import '../design/widgets/travi_cameo.dart';
import '../domain/domain.dart';
import '../features/booking/booking_actions.dart';
import '../features/profile/profile_screen.dart';
import '../features/today/today_screen.dart';
import '../features/trips/trip_screen.dart';
import '../features/trips/trips_screen.dart';
import '../features/wallet/wallet_screen.dart';
import '../logic/travi_cameos.dart';
import '../state/app_session.dart';
import '../state/countdown_widget_sync.dart';
import '../state/notifications_store.dart';
import '../state/premium_store.dart';
import '../state/reminders_store.dart';
import '../state/share_inbox.dart';
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

  /// Absent in tests that don't need it.
  late final NotificationsStore? _notifications;
  late final RemindersStore? _reminders;
  late final ShareInbox? _shares;
  bool _readingShare = false;
  late final AppSession? _session;
  late final CountdownWidgetSync? _widget;

  /// A trip the countdown widget was tapped on, opened once it has loaded.
  String? _pendingTrip;

  /// A tapped flight alert's booking, opened as soon as it has loaded.
  String? _pendingBooking;

  @override
  void initState() {
    super.initState();
    _store = context.read<TravelStore>()
      ..addListener(_showErrors)
      ..addListener(_openPendingBooking);
    _premium = context.read<PremiumStore>()..addListener(_premiumChanged);
    _documents = context.read<TravelDocumentsStore>();
    _notifications = context.read<NotificationsStore?>()?..addListener(_notificationsChanged);
    _reminders = context.read<RemindersStore?>()?..addListener(_reminderTapped);
    _shares = context.read<ShareInbox?>()?..addListener(_readShare);
    _store.addListener(_readShare);
    _session = context.read<AppSession?>()?..addListener(_widgetTapped);
    _store.addListener(_openPendingTrip);
    _widget = context.read<CountdownWidgetSync?>();
    // A flight alert or a reminder may have opened the app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationsChanged();
      _reminderTapped();
      // A file shared in may be waiting (shared before, or during onboarding).
      _readShare();
      // Or the countdown widget opened the app.
      _widgetTapped();
    });
    // After switching account the app is rebuilt: say what happened.
    final notice = context.read<AppSession>().takeNotice();
    if (notice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notice)));
      });
    }
    // Tickets are backed up for shared trips and for trips with Plus.
    _store.shouldBackUp = (plan) => plan.trip.isShared || _premium.forTrip(plan).allowed;
    // A Holiday Pass belongs to its trip: emptying the trip mustn't lose it.
    // (The organiser's own Plus is stamped on every trip, so that alone
    // doesn't keep one.)
    _store.keepWhenEmpty = (plan) =>
        _premium.policy.tripPassFor(plan) != null ||
        (plan.trip.premium?.grantedBy ?? plan.trip.ownerId) != plan.trip.ownerId;
    WidgetsBinding.instance.addObserver(this);
  }

  /// Back from the background: new art packs may be out (and a download
  /// that failed offline can finish now). Into the background: the travel
  /// documents lock again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _store.refreshArtPacksIfStale();
      // Notifications may have been turned on in Settings meanwhile.
      if (_notifications case final notifications?) unawaited(notifications.refresh());
      // The phone may have landed in another time zone: reminders are set
      // again on its clock.
      if (_reminders case final reminders?) unawaited(reminders.refresh());
      // The countdown widget too.
      if (_widget case final widget?) unawaited(widget.refresh());
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
    _store
      ..removeListener(_showErrors)
      ..removeListener(_openPendingBooking);
    _premium.removeListener(_premiumChanged);
    _notifications?.removeListener(_notificationsChanged);
    _reminders?.removeListener(_reminderTapped);
    _shares?.removeListener(_readShare);
    _store.removeListener(_readShare);
    _session?.removeListener(_widgetTapped);
    _store.removeListener(_openPendingTrip);
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

  /// A flight alert tapped opens its flight; one that arrives while the app
  /// is open (Android shows nothing then) shows here.
  void _notificationsChanged() {
    final notifications = _notifications;
    if (notifications == null || !mounted) return;
    if (notifications.takeUnseen() case final alert?) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text([alert.title, alert.body].whereType<String>().join('\n')),
          action: SnackBarAction(label: 'Open', onPressed: () => _openBooking(alert.bookingId)),
        ),
      );
    }
    if (notifications.takeToOpen() case final alert?) _openBooking(alert.bookingId);
  }

  /// A screenshot or PDF shared into Travary: read like Smart Import,
  /// over whatever is open, once the trips have loaded.
  Future<void> _readShare() async {
    final shares = _shares;
    if (shares == null || _readingShare || !shares.hasWaiting || !mounted || _store.isLoading) return;
    final file = shares.take()!;
    _readingShare = true;
    try {
      await importSharedFile(context, file);
    } finally {
      _readingShare = false;
      await shares.done(file);
    }
    // Another may have come in meanwhile.
    _readShare();
  }

  /// A reminder tapped: its booking, or Today for the morning's plan.
  void _reminderTapped() {
    final opens = _reminders?.takeToOpen();
    if (opens == null || !mounted) return;
    if (opens.startsWith('booking:')) return _openBooking(opens.substring('booking:'.length));
    Navigator.of(context).popUntil((route) => route.isFirst);
    _select(0);
  }

  /// The countdown widget tapped: the trip it showed, else Today.
  void _widgetTapped() {
    final target = _session?.takeWidgetTarget();
    if (target == null || !mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    _select(0);
    if (target.isNotEmpty) {
      _pendingTrip = target;
      _openPendingTrip();
    }
  }

  /// Waits for the trips to load after a cold start; a trip that's gone
  /// leaves Today showing.
  void _openPendingTrip() {
    final id = _pendingTrip;
    if (id == null || !mounted || _store.isLoading) return;
    _pendingTrip = null;
    if (_store.plan(id) == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripScreen(tripId: id)));
  }

  void _openBooking(String bookingId) {
    _pendingBooking = bookingId;
    _openPendingBooking();
  }

  /// Waits for the trips to load after a cold start.
  void _openPendingBooking() {
    final id = _pendingBooking;
    if (id == null || !mounted || _store.isLoading) return;
    final booking = _store.booking(id);
    if (booking == null) return;
    _pendingBooking = null;
    openBooking(context, booking);
  }

  void _showErrors() {
    final error = _store.error;
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TraviMessage(moment: TraviMoment.oops, text: error),
      ),
    );
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
            children: [
              for (final (i, screen) in screens.indexed)
                _TabPage(linen: linen, linenHeight: box.maxHeight, showing: i == _index, child: screen),
            ],
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
  const _TabPage({required this.linen, required this.linenHeight, required this.showing, required this.child});

  final ArtImageRef? linen;
  final double linenHeight;

  /// The chosen tab. The others hold their animations (Today's countdown
  /// entry, Travi) until they're chosen, so nothing plays unseen.
  final bool showing;
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
        Positioned.fill(
          child: TickerMode(enabled: widget.showing, child: widget.child),
        ),
      ],
    );
  }
}
