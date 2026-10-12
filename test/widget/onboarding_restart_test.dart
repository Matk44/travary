import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/data/demo_data.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/onboarding_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/domain/onboarding.dart';
import 'package:travary/features/onboarding/onboarding_gate.dart';
import 'package:travary/features/onboarding/onboarding_screen.dart';
import 'package:travary/logic/destinations.dart';
import 'package:travary/state/onboarding_store.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../support/session.dart';
import '../support/travel_documents.dart';

/// Design tools' "Restart onboarding": a finished account with plans gets
/// the whole story again from the first screen, then goes home.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  testWidgets('restarting plays onboarding from the start, then home again', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final now = DateTime(2026, 10, 14, 11);
    final repository = MemoryTravelRepository();
    final demo = buildDemoData(LocalDate.fromDateTime(now), userId: repository.userId);
    repository.replaceAll(demo.trips, demo.bookings);
    final finished = OnboardingDraft(
      step: OnboardingStep.booking,
      destination: countryPlace('JP').destination,
      completed: true,
    );
    final setup = OnboardingStore(repository: MemoryOnboardingRepository(finished));
    await setup.load();
    addTearDown(setup.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TravelStore(repository: repository, artCatalog: const ArtCatalog.empty(), clock: () => now),
          ),
          ChangeNotifierProvider(
            create: (_) => PremiumStore(purchases: TestPurchaseService(clock: () => now)),
          ),
          ChangeNotifierProvider.value(value: setup),
          appSessionProvider(),
          travelDocumentsProvider(),
        ],
        // A cloud account (not the demo), which has finished onboarding.
        child: MaterialApp(theme: buildTravaryTheme(), home: const OnboardingGate(force: false)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);

    await setup.restart();
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-destination')), findsOneWidget);
    expect(setup.draft.destination, isNull);

    await setup.complete();
    expect(setup.replaying, isFalse);
  });
}
