import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import '../data/attachment_store.dart';
import '../data/demo_data.dart';
import '../data/firestore_travel_repository.dart';
import '../data/memory_travel_repository.dart';
import '../data/purchase_service.dart';
import '../data/smart_import_service.dart';
import '../data/travel_repository.dart';
import '../design/art/art_catalog.dart';
import '../domain/domain.dart';
import '../firebase_options.dart';

/// Where data lives. Pick with `--dart-define=TRAVARY_BACKEND=cloud`.
enum Backend {
  /// Sample trips in memory. The default while the interface is designed.
  demo,

  /// Firestore with anonymous sign-in.
  cloud,
}

const _backendName = String.fromEnvironment('TRAVARY_BACKEND', defaultValue: 'demo');

Backend get configuredBackend => _backendName == 'cloud' ? Backend.cloud : Backend.demo;

/// Everything the app needs before it can show a screen.
class Dependencies {
  const Dependencies({
    required this.repository,
    required this.purchases,
    required this.smartImport,
    required this.artCatalog,
    required this.attachments,
  });

  final TravelRepository repository;
  final SmartImportService smartImport;

  /// Simulated store until RevenueCat is connected (step 4 of the plan).
  final PurchaseService purchases;
  final ArtCatalog artCatalog;
  final AttachmentStore attachments;
}

/// A startup problem worth explaining to whoever is running the app.
class StartupException implements Exception {
  const StartupException(this.message, {this.hint});

  final String message;
  final String? hint;
}

Future<Dependencies> bootstrap() async {
  final artCatalog = await ArtCatalog.load(rootBundle);
  final attachments = await AttachmentStore.open();
  final repository = switch (configuredBackend) {
    Backend.demo => _demoRepository(),
    Backend.cloud => await _cloudRepository(),
  };
  return Dependencies(
    repository: repository,
    purchases: TestPurchaseService(),
    // Smart Import always uses the cloud, even in demo mode. Firebase is set
    // up on first use, so demo mode still starts instantly and offline.
    smartImport: CloudSmartImportService(ensureSignedIn: () async => ensureSignedIn()),
    artCatalog: artCatalog,
    attachments: attachments,
  );
}

TravelRepository _demoRepository() {
  final repository = MemoryTravelRepository();
  final demo = buildDemoData(LocalDate.fromDateTime(DateTime.now()), userId: repository.userId);
  repository.replaceAll(demo.trips, demo.bookings);
  return repository;
}

/// Initialises Firebase (once) and signs the traveller in anonymously if
/// they aren't signed in yet. Returns their user id.
Future<String> ensureSignedIn() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
  if (user == null) throw const StartupException('Couldn\'t sign in.');
  return user.uid;
}

Future<TravelRepository> _cloudRepository() async {
  try {
    final userId = await ensureSignedIn();
    return FirestoreTravelRepository(firestore: FirebaseFirestore.instance, userId: userId);
  } on FirebaseAuthException catch (e) {
    if (e.code == 'operation-not-allowed' || e.code == 'admin-restricted-operation') {
      throw const StartupException(
        'Anonymous sign-in is turned off for this Firebase project.',
        hint: 'Firebase console → Authentication → Sign-in method → enable Anonymous.',
      );
    }
    throw StartupException('Couldn\'t sign in (${e.code}).', hint: e.message);
  }
}
