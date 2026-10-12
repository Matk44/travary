import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/art_pack_service.dart';
import '../data/art_pack_store.dart';
import '../data/attachment_backup.dart';
import '../data/attachment_store.dart';
import '../data/auth_service.dart';
import '../data/demo_data.dart';
import '../data/document_lock.dart';
import '../data/firestore_travel_repository.dart';
import '../data/memory_travel_repository.dart';
import '../data/onboarding_record.dart';
import '../data/pending_pass_claims.dart';
import '../data/purchase_server.dart';
import '../data/push_service.dart';
import '../data/reminder_scheduler.dart';
import '../data/shared_files.dart';
import '../data/purchase_service.dart';
import '../data/revenuecat_offer_catalog.dart';
import '../data/revenuecat_identity.dart';
import '../data/revenuecat_purchase_service.dart';
import '../data/flight_status_service.dart';
import '../data/sharing_service.dart';
import '../data/smart_import_service.dart';
import '../data/travel_document_repository.dart';
import '../data/travel_repository.dart';
import '../data/visual_profile_service.dart';
import '../design/art/art_catalog.dart';
import '../domain/domain.dart';
import '../firebase_options.dart';
import '../state/analytics.dart';
import 'build_info.dart';

/// Where data lives: the cloud (real trips) unless started with
/// `--dart-define=TRAVARY_BACKEND=demo` for the sample trips.
enum Backend {
  /// Sample trips in memory, for designing and testing.
  demo,

  /// Firestore: a guest (anonymous) account until the traveller signs in
  /// with Apple or Google.
  cloud,
}

const _backendName = String.fromEnvironment('TRAVARY_BACKEND');

Backend get configuredBackend => _backendName == 'demo' ? Backend.demo : Backend.cloud;

/// Local development against the Firebase emulators:
/// `--dart-define=TRAVARY_EMULATOR_HOST=127.0.0.1` (10.0.2.2 from the
/// Android emulator). Ports are the ones in firebase.json.
const _emulatorHost = String.fromEnvironment('TRAVARY_EMULATOR_HOST');

/// Opt in for release after the deployment's AeroData plan is ready. The
/// callable remains authenticated, capped and server-keyed in every mode.
const flightLookupEnabled = bool.fromEnvironment('TRAVARY_FLIGHT_LOOKUP', defaultValue: kDebugMode);

const _revenueCatIosKey = String.fromEnvironment('TRAVARY_REVENUECAT_IOS_KEY');
const _revenueCatAndroidKey = String.fromEnvironment('TRAVARY_REVENUECAT_ANDROID_KEY');
const _revenueCatOffering = String.fromEnvironment('TRAVARY_REVENUECAT_OFFERING');

String get _revenueCatKey => kIsWeb
    ? ''
    : switch (defaultTargetPlatform) {
        TargetPlatform.iOS => _revenueCatIosKey,
        TargetPlatform.android => _revenueCatAndroidKey,
        _ => '',
      };

/// Everything the app needs before it can show a screen.
class Dependencies {
  const Dependencies({
    required this.repositoryFor,
    required this.initialUserId,
    this.auth,
    this.onboardingRecord,
    this.signInLinks,
    required this.purchases,
    this.purchasesFor,
    this.offerLoaderFor,
    required this.smartImport,
    this.visualProfiles,
    this.backup,
    this.sharing,
    this.flightStatus,
    this.push,
    this.reminders,
    this.sharedFiles,
    required this.artCatalog,
    required this.artPacks,
    required this.attachments,
    required this.travelDocuments,
    required this.documentLock,
  });

  /// The traveller's trips and bookings, for the account [userId]. Called
  /// again when the account changes (sign in to another account, sign out,
  /// delete); demo mode always returns the same sample data.
  final TravelRepository Function(String userId) repositoryFor;

  /// Who is signed in at startup (a guest at first).
  final String initialUserId;

  /// Signing in with Apple, Google or an email link. Cloud mode only.
  final AuthService? auth;

  /// Whether an account has been through onboarding, on any phone. Cloud
  /// mode only.
  final OnboardingRecord? onboardingRecord;

  /// Links that open the app (email sign-in links). Only when email links
  /// are set up (`TRAVARY_EMAIL_LINKS`).
  final Stream<Uri>? signInLinks;
  final SmartImportService smartImport;

  /// Automatic trip looks. Cloud mode only: the server classifies the trip
  /// as it's saved there.
  final VisualProfileService? visualProfiles;

  /// Cloud mode only: ticket backup and family sharing need saved trips.
  final AttachmentBackup? backup;
  final SharingService? sharing;

  /// Cloud flight service, enabled by [flightLookupEnabled]. Debug defaults
  /// on; release builds opt in once the deployment's provider plan is ready.
  final FlightStatusService? flightStatus;

  /// Notifications for flight alerts. Cloud mode only: the server sends
  /// them for paid trips.
  final PushService? push;

  /// Reminders on this phone (local notifications), in every mode. Null in
  /// tests and on the web.
  final ReminderScheduler? reminders;

  /// Screenshots and PDFs shared into Travary from other apps. Null in tests
  /// and on the web.
  final SharedFiles? sharedFiles;

  /// The simulated store: demo mode, tests, and builds without RevenueCat
  /// keys (Profile → Design tools switches plans).
  final PurchaseService purchases;

  /// Real store purchases through RevenueCat, made for each account. When
  /// set (cloud builds with RevenueCat keys), it's used instead of
  /// [purchases].
  final PurchaseService Function(String userId)? purchasesFor;

  /// RevenueCat's catalog (store prices, pass names); absent in the offline
  /// preview, which shows the launch prices.
  final Future<List<Offer>> Function() Function(String userId)? offerLoaderFor;

  /// The bundled artwork.
  final ArtCatalog artCatalog;

  /// Downloaded art packs, already loaded from this phone.
  final ArtPackManager artPacks;
  final AttachmentStore attachments;

  /// Passports and other travel documents: on this phone only, in every
  /// mode, behind [documentLock].
  final TravelDocumentRepository travelDocuments;
  final DocumentLock documentLock;
}

/// A startup problem worth explaining to whoever is running the app.
class StartupException implements Exception {
  const StartupException(this.message, {this.hint});

  final String message;
  final String? hint;
}

/// Everything local first; the network only ever in the background.
///
/// 1. The bundled art catalog. 2. The local art-pack store. 3. Installed
/// packs, validated offline. 4. The app, built on bundled plus installed
/// art (see `ArtCatalogController`). 5. After sign-in, a background
/// refresh of the remote pack catalog.
Future<Dependencies> bootstrap() async {
  final artCatalog = await ArtCatalog.load(rootBundle);
  final artPacks = ArtPackManager(
    store: await ArtPackStore.open(),
    remote: FirebaseArtPackRemote(ensureSignedIn: () async => ensureSignedIn()),
    appBuild: appBuildNumber,
  );
  await artPacks.loadInstalled();
  final attachments = await AttachmentStore.open();
  final travelDocuments = await LocalTravelDocumentRepository.open();
  final cloud = configuredBackend == Backend.cloud;
  final demo = cloud ? null : _demoRepository();
  final initialUserId = demo?.userId ?? await _cloudSignIn();
  // Signs in first (in the background in demo mode); never awaited.
  unawaited(artPacks.refreshCatalog());
  final auth = cloud ? FirebaseAuthService(ensureSignedIn: ensureSignedIn) : null;
  if (cloud) await useFirebaseAnalytics();
  return Dependencies(
    repositoryFor: (userId) => demo ?? FirestoreTravelRepository(firestore: FirebaseFirestore.instance, userId: userId),
    initialUserId: initialUserId,
    auth: auth,
    onboardingRecord: cloud ? FirestoreOnboardingRecord(ensureSignedIn: () async => ensureSignedIn()) : null,
    // Links that open the app: family invites, and email sign-in links
    // when those are on.
    signInLinks: auth != null ? AppLinks().uriLinkStream : null,
    purchases: TestPurchaseService(),
    purchasesFor: !cloud || _revenueCatKey.isEmpty
        ? null
        : (uid) => RevenueCatPurchaseService(
            store: RevenueCatStoreClient(publicSdkKey: _revenueCatKey, userId: uid),
            server: CloudPurchaseServer(ensureSignedIn: () async => ensureSignedIn()),
            userRecord: FirebaseFirestore.instance.doc('users/$uid').snapshots().map((s) => s.data()),
            offers: _revenueCatCatalog(uid).load,
            pending: LocalPendingPassClaims(userId: uid),
          ),
    offerLoaderFor: _revenueCatKey.isEmpty ? null : (uid) => _revenueCatCatalog(uid).load,
    // Smart Import always uses the cloud, even in demo mode. Firebase is set
    // up on first use, so demo mode still starts instantly and offline.
    smartImport: CloudSmartImportService(ensureSignedIn: () async => ensureSignedIn()),
    visualProfiles: cloud ? CloudVisualProfileService(ensureSignedIn: () async => ensureSignedIn()) : null,
    backup: cloud ? FirebaseAttachmentBackup(ensureSignedIn: () async => ensureSignedIn()) : null,
    sharing: cloud ? CloudSharingService(ensureSignedIn: () async => ensureSignedIn()) : null,
    flightStatus: cloud && flightLookupEnabled
        ? CloudFlightStatusService(ensureSignedIn: () async => ensureSignedIn())
        : null,
    push: cloud ? FirebasePushService(ensureSignedIn: () async => ensureSignedIn()) : null,
    reminders: kIsWeb ? null : LocalReminderScheduler(),
    sharedFiles: kIsWeb ? null : PluginSharedFiles(),
    artCatalog: artCatalog,
    artPacks: artPacks,
    attachments: attachments,
    travelDocuments: travelDocuments,
    documentLock: DeviceDocumentLock(),
  );
}

/// Funnel events go to Firebase Analytics in release builds; debug runs stay
/// out of the numbers unless started with `--dart-define=TRAVARY_ANALYTICS=true`
/// (for DebugView). Collection is off in the platform config until this
/// turns it on. Purchases reach Firebase through RevenueCat, which is given
/// this phone's analytics ID.
Future<void> useFirebaseAnalytics() async {
  const enabled = !kDebugMode || bool.fromEnvironment('TRAVARY_ANALYTICS');
  try {
    final analytics = FirebaseAnalytics.instance;
    await analytics.setAnalyticsCollectionEnabled(enabled);
    if (!enabled) return;
    analyticsSink = (event, parameters) =>
        unawaited(analytics.logEvent(name: event, parameters: parameters).catchError((Object _) {}));
    RevenueCatIdentity.analyticsInstanceId = () => analytics.appInstanceId;
  } catch (_) {
    // Analytics never stops the app starting.
  }
}

RevenueCatOfferCatalog _revenueCatCatalog(String uid) => RevenueCatOfferCatalog(
  publicSdkKey: _revenueCatKey,
  userId: uid,
  offeringId: _revenueCatOffering.isEmpty ? null : _revenueCatOffering,
);

MemoryTravelRepository _demoRepository() {
  final repository = MemoryTravelRepository();
  final demo = buildDemoData(LocalDate.fromDateTime(DateTime.now()), userId: repository.userId);
  repository.replaceAll(demo.trips, demo.bookings);
  return repository;
}

/// Initialises Firebase (once) and signs the traveller in anonymously if
/// they aren't signed in yet. Returns their user id. Callers at the same
/// moment share one attempt, so there's never a second anonymous account.
Future<String> ensureSignedIn() => _signingIn ??= _signIn().whenComplete(() {
  _signingIn = null;
});

Future<String>? _signingIn;

Future<String> _signIn() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (_emulatorHost.isNotEmpty) await _useEmulators(_emulatorHost);
  }
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
  if (user == null) throw const StartupException('Couldn\'t sign in.');
  return user.uid;
}

/// Points every Firebase service at the local emulators (before any use).
Future<void> _useEmulators(String host) async {
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
}

/// Signs in (a guest the first time) and returns who.
Future<String> _cloudSignIn() async {
  try {
    return await ensureSignedIn();
  } on FirebaseAuthException catch (e) {
    if (e.code == 'network-request-failed') {
      throw const StartupException(
        'Travary needs the internet the first time it opens.',
        hint: 'Connect to Wi-Fi or mobile data and try again. After that, your trips and tickets open offline.',
      );
    }
    if (e.code == 'operation-not-allowed' || e.code == 'admin-restricted-operation') {
      throw const StartupException(
        'Anonymous sign-in is turned off for this Firebase project.',
        hint: 'Firebase console → Authentication → Sign-in method → enable Anonymous.',
      );
    }
    throw StartupException('Couldn\'t sign in (${e.code}).', hint: e.message);
  }
}
