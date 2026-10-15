import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/ai_consent_record.dart';
import '../data/art_pack_service.dart';
import '../data/smart_import_service.dart';
import '../data/visual_profile_service.dart';
import '../data/onboarding_repository.dart';
import '../data/reminder_settings.dart';
import '../data/travi_greeting_record.dart';
import '../design/tokens.dart';
import '../logic/formatters.dart';
import '../state/ai_consent_store.dart';
import '../state/app_session.dart';
import '../state/notifications_store.dart';
import '../state/premium_store.dart';
import '../state/reminders_store.dart';
import '../state/share_inbox.dart';
import '../state/travel_documents_store.dart';
import '../state/travel_store.dart';
import '../state/onboarding_store.dart';
import '../state/travi_greetings.dart';
import '../features/onboarding/onboarding_gate.dart';
import 'bootstrap.dart';
import 'route_observer.dart';
import 'trip_chrome_scope.dart';

class TravaryApp extends StatelessWidget {
  const TravaryApp({super.key, required this.dependencies});

  final Dependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SmartImportService>.value(value: dependencies.smartImport),
        Provider<VisualProfileService?>.value(value: dependencies.visualProfiles),
        // Owned by bootstrap for the app's lifetime.
        ChangeNotifierProvider<ArtPackManager>.value(value: dependencies.artPacks),
        // On this phone, whoever is signed in.
        ChangeNotifierProvider(
          create: (_) =>
              TravelDocumentsStore(repository: dependencies.travelDocuments, lock: dependencies.documentLock),
        ),
        // Whether Smart Import and trip looks may use Google's AI: asked on
        // this phone, whoever is signed in.
        ChangeNotifierProvider(create: (_) => AiConsentStore(LocalAiConsentRecord())),
        // Travi greets at most once a day on this phone.
        Provider<TraviGreetings?>(create: (_) => TraviGreetings(LocalTraviGreetingRecord())),
        // A file shared in waits here, whatever the account, until home reads it.
        ChangeNotifierProvider(create: (_) => ShareInbox(dependencies.sharedFiles)..start()),
        ChangeNotifierProvider(
          create: (_) => AppSession(
            auth: dependencies.auth,
            uid: dependencies.initialUserId,
            onboardingRecord: dependencies.onboardingRecord,
            links: dependencies.signInLinks,
          ),
        ),
      ],
      // Everything that holds a traveller's data starts afresh for a new
      // account (switching to an existing one, signing out, deleting).
      child: Selector<AppSession, String>(
        selector: (_, session) => session.uid,
        builder: (context, uid, _) => KeyedSubtree(
          key: ValueKey(uid),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (context) => TravelStore(
                  repository: dependencies.repositoryFor(uid),
                  artCatalog: dependencies.artCatalog,
                  artPacks: context.read<ArtPackManager>(),
                  visualProfiles: context.read<VisualProfileService?>(),
                  attachments: dependencies.attachments,
                  backup: dependencies.backup,
                  sharing: dependencies.sharing,
                  flightStatus: dependencies.flightStatus,
                  aiConsent: context.read<AiConsentStore>(),
                ),
              ),
              ChangeNotifierProvider(
                create: (context) {
                  final travel = context.read<TravelStore>();
                  final accountPurchases = dependencies.purchasesFor?.call(uid);
                  // Shares the travel clock, so "Preview a different time"
                  // also previews Plus and Trip Pass expiry.
                  return PremiumStore(
                    purchases: accountPurchases ?? dependencies.purchases,
                    ownsPurchases: accountPurchases != null,
                    clock: () => travel.now,
                    offerLoader: dependencies.offerLoaderFor?.call(uid),
                  );
                },
              ),
              // Flight alerts reach this phone for this account.
              ChangeNotifierProvider(
                create: (_) => NotificationsStore(push: dependencies.push, userId: uid)..start(),
              ),
              // Reminders for this account's trips; on or off for this phone.
              ChangeNotifierProvider(
                create: (context) => RemindersStore(
                  scheduler: dependencies.reminders,
                  settings: LocalReminderSettings(),
                  travel: context.read<TravelStore>(),
                )..start(),
              ),
              ChangeNotifierProvider(
                create: (context) => OnboardingStore(
                  repository: context.read<TravelStore>().isDemo
                      ? MemoryOnboardingRepository()
                      : LocalOnboardingRepository(userId: uid),
                  record: dependencies.onboardingRecord,
                  userId: uid,
                )..load(),
              ),
            ],
            child: MaterialApp(
              title: 'Travary',
              debugShowCheckedModeBanner: false,
              theme: buildTravaryTheme(),
              // Every screen, pushed ones included, shares the trip's palette.
              builder: (context, child) {
                // Times are written the way the phone is set to show them.
                ClockStyle.use24Hour = MediaQuery.alwaysUse24HourFormatOf(context);
                return TripChromeScope(child: child!);
              },
              navigatorObservers: [appRouteObserver],
              home: const OnboardingGate(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the app when startup fails, with a hint for fixing it.
class StartupErrorApp extends StatefulWidget {
  const StartupErrorApp({super.key, required this.message, this.hint, this.onRetry});

  final String message;
  final String? hint;

  /// Starts again from the top (never a dead end: the alternative is
  /// closing the app by hand).
  final Future<void> Function()? onRetry;

  @override
  State<StartupErrorApp> createState() => _StartupErrorAppState();
}

class _StartupErrorAppState extends State<StartupErrorApp> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await widget.onRetry!();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTravaryTheme(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TravarySpace.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 40, color: TravaryColors.coral),
                const SizedBox(height: TravarySpace.lg),
                Text(widget.message, style: TravaryText.title),
                if (widget.hint case final hint?) ...[
                  const SizedBox(height: TravarySpace.sm),
                  Text(hint, style: TravaryText.bodySoft),
                ],
                if (widget.onRetry != null) ...[
                  const SizedBox(height: TravarySpace.xl),
                  FilledButton(
                    key: const ValueKey('startup-retry'),
                    onPressed: _retrying ? null : _retry,
                    child: Text(_retrying ? 'Trying…' : 'Try again'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
