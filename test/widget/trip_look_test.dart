import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/data/visual_profile_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/trips/trip_details_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

class _FailingService implements VisualProfileService {
  int calls = 0;

  @override
  Future<TripVisualProfile> classify(Trip trip, List<Booking> bookings) async {
    calls++;
    throw const VisualProfileException(
      VisualProfileFailure.busy,
      'Automatic looks are busy right now. Try again in a minute.',
    );
  }
}

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  final kyoto = Trip(
    id: 'kyoto',
    title: 'Kyoto',
    themeSource: ThemeSource.auto,
    visualProfile: const TripVisualProfile(
      primaryTheme: ExperienceTheme.urbanHeritage,
      confidence: 0.9,
      sourceHash: 'h',
    ),
    ownerId: 'me',
    memberIds: const ['me'],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Future<MemoryTravelRepository> pump(WidgetTester tester, {VisualProfileService? service}) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = MemoryTravelRepository(userId: 'me')
      ..replaceAll([kyoto], [booking('temple', BookingKind.attraction, d(4, 6), tripId: 'kyoto', title: 'Kinkaku-ji')]);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TravelStore(
              repository: repo,
              artCatalog: const ArtCatalog.empty(),
              visualProfiles: service,
              clock: () => DateTime(2026, 4, 1, 9),
            ),
          ),
          ChangeNotifierProvider(create: (_) => PremiumStore(purchases: TestPurchaseService())),
        ],
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: const TripDetailsScreen(tripId: 'kyoto'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  Finder look(String key) => find.byKey(ValueKey('look-$key'));
  bool ticked(WidgetTester tester, String key) =>
      find.descendant(of: look(key), matching: find.byIcon(Icons.check_circle_rounded)).evaluate().isNotEmpty;
  Future<void> choose(WidgetTester tester, String key) async {
    await tester.ensureVisible(look(key));
    await tester.pumpAndSettle();
    await tester.tap(look(key));
    await tester.pumpAndSettle();
  }

  testWidgets('an automatic trip names the look it was given', (tester) async {
    await pump(tester);
    expect(find.text('Card style'), findsOneWidget);
    expect(find.text('Travary chose Historic city'), findsOneWidget);
    expect(ticked(tester, 'automatic'), isTrue);
    expect(ticked(tester, 'urban_heritage'), isFalse);
  });

  testWidgets('picking a look makes it manual', (tester) async {
    final repo = await pump(tester);
    await choose(tester, 'alpine');
    final trip = repo.trips.single;
    expect((trip.theme, trip.themeSource), (ExperienceTheme.alpine, ThemeSource.manual));
    expect(ticked(tester, 'alpine'), isTrue);
    expect(ticked(tester, 'automatic'), isFalse);
    expect(find.text('Let Travary choose from your bookings'), findsOneWidget);
  });

  testWidgets('going back to automatic explains a failure without blocking', (tester) async {
    final service = _FailingService();
    final repo = await pump(tester, service: service);
    await choose(tester, 'alpine');
    await choose(tester, 'automatic');
    expect(service.calls, 1);
    expect(find.text('Automatic looks are busy right now. Try again in a minute.'), findsOneWidget);
    expect(repo.trips.single.themeSource, ThemeSource.auto);
    expect(find.text('Travary chose Historic city'), findsOneWidget, reason: 'the stored profile\'s look');
  });

  testWidgets('in the demo, automatic explains that it needs the cloud', (tester) async {
    await pump(tester);
    await choose(tester, 'alpine');
    await choose(tester, 'automatic');
    expect(find.textContaining('This is the demo version'), findsOneWidget);
  });
}
