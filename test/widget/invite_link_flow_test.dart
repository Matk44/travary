import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travary/app/app.dart';
import 'package:travary/app/bootstrap.dart';
import 'package:travary/data/art_pack_service.dart';
import 'package:travary/data/art_pack_store.dart';
import 'package:travary/data/attachment_store.dart';
import 'package:travary/data/memory_travel_document_repository.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/data/sharing_service.dart';
import 'package:travary/data/smart_import_service.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/sharing/join_trip_sheet.dart';
import 'package:travary/features/trips/trip_screen.dart';

import '../support/art_pack_fixtures.dart';
import '../support/canonical_today.dart';
import '../support/session.dart';

/// Tapping a family invite link opens the app straight onto joining.
class _JoiningSharing implements SharingService {
  _JoiningSharing(this.repository);

  final MemoryTravelRepository repository;
  String? joinedWith;

  @override
  Future<TripInvite> createInvite(String tripId, {String? name}) async => TripInvite('K7MPQ2', DateTime(2026, 10, 30));

  @override
  Future<({String tripId, String title})> join(String code, {required String name}) async {
    joinedWith = code;
    // The server adds them; their trips then include it.
    final start = LocalDate.fromDateTime(DateTime.now()).addDays(20);
    repository.putTrip(
      Trip(
        id: 'kyoto',
        title: 'Kyoto',
        plannedStart: start,
        plannedEnd: start.addDays(4),
        ownerId: 'sam',
        memberIds: [repository.userId, 'sam'],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    return (tripId: 'kyoto', title: 'Kyoto');
  }

  @override
  Future<void> removeMember(String tripId, String memberId) async {}
}

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  late Directory temp;
  setUp(() => temp = Directory.systemTemp.createTempSync('invite_link_'));
  tearDown(() => temp.deleteSync(recursive: true));

  testWidgets('an invite link opens the join sheet with its code; joining opens the trip', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final auth = FakeAuthService(email: 'kim@example.com');
    final links = StreamController<Uri>();
    addTearDown(links.close);
    final repository = MemoryTravelRepository(userId: auth.current!.uid);
    final sharing = _JoiningSharing(repository);
    await tester.pumpWidget(
      TravaryApp(
        dependencies: Dependencies(
          repositoryFor: (_) => repository,
          initialUserId: auth.current!.uid,
          auth: auth,
          signInLinks: links.stream,
          sharing: sharing,
          purchases: TestPurchaseService(),
          smartImport: CloudSmartImportService(ensureSignedIn: () async {}),
          artCatalog: bundledArtCatalog(),
          artPacks: ArtPackManager(
            store: ArtPackStore.at(Directory('${temp.path}/packs')),
            remote: FakeArtPackRemote(),
            appBuild: 1,
          ),
          attachments: AttachmentStore.at(Directory('${temp.path}/attachments')..createSync()),
          travelDocuments: MemoryTravelDocumentRepository(),
          documentLock: FixedDocumentLock(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    links.add(Uri.parse('https://travary.app/join/K7MPQ2'));
    await tester.pumpAndSettle();
    expect(find.byType(JoinTripSheet), findsOneWidget);
    expect(find.text('K7MPQ2'), findsOneWidget, reason: 'filled in from the link');

    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Kim');
    await tester.pump();
    await tester.tap(find.text('Join trip'));
    await tester.pumpAndSettle();
    expect(sharing.joinedWith, 'K7MPQ2');
    expect(find.text('You\'ve joined Kyoto'), findsOneWidget);
    expect(find.byType(TripScreen), findsOneWidget);
  });
}
