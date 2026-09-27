import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/attachment_backup.dart';
import 'package:travary/data/attachment_store.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/data/sharing_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

class _FakeBackup implements AttachmentBackup {
  final uploads = <String>[];
  final cloud = <String, List<int>>{};

  @override
  Future<String> upload(String tripId, Attachment attachment, File file) async {
    final path = 'trips/$tripId/attachments/${attachment.fileName}';
    uploads.add(path);
    cloud[path] = await file.readAsBytes();
    return path;
  }

  @override
  Future<void> download(Attachment attachment, File target) async {
    await target.writeAsBytes(cloud[attachment.remotePath]!);
  }

  @override
  Future<void> delete(Attachment attachment) async => cloud.remove(attachment.remotePath);
}

class _FakeSharing implements SharingService {
  final removed = <String>[];

  @override
  Future<TripInvite> createInvite(String tripId, {String? name}) async =>
      TripInvite('K7MPQ2', DateTime(2026, 10, 30));

  @override
  Future<({String tripId, String title})> join(String code, {required String name}) async =>
      (tripId: 'orlando', title: 'Orlando');

  @override
  Future<void> removeMember(String tripId, String memberId) async => removed.add(memberId);
}

Trip sharedTrip({String owner = 'me', List<String> members = const ['me', 'sam']}) => Trip(
  id: 'orlando',
  title: 'Orlando',
  ownerId: owner,
  memberIds: members,
  memberNames: const {'me': 'Alex', 'sam': 'Sam', 'kim': 'Kim'},
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late Directory dir;
  late AttachmentStore files;
  late MemoryTravelRepository repository;
  late _FakeBackup backup;
  late TravelStore store;

  Future<Attachment> ticketFile(String name) async {
    final source = File('${dir.path}/$name')..writeAsStringSync('ticket $name');
    return files.import(source.path);
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('travary_sharing');
    files = AttachmentStore.at(Directory('${dir.path}/attachments')..createSync());
    repository = MemoryTravelRepository(userId: 'me');
    backup = _FakeBackup();
    store = TravelStore(
      repository: repository,
      artCatalog: const ArtCatalog.empty(),
      attachments: files,
      backup: backup,
      sharing: _FakeSharing(),
    );
    await pumpEventQueue();
  });

  tearDown(() {
    store.dispose();
    dir.deleteSync(recursive: true);
  });

  group('ticket backup', () {
    test('tickets on a shared trip are backed up and the booking remembers where', () async {
      repository.putTrip(sharedTrip());
      final ticket = await ticketFile('park.png');
      await store.saveBooking(booking('park', BookingKind.attraction, d(10, 14), tripId: 'orlando')
          .copyWith(attachments: [ticket]));
      await pumpEventQueue();
      await store.syncTickets();
      await pumpEventQueue();

      expect(backup.uploads, ['trips/orlando/attachments/${ticket.fileName}']);
      expect(store.booking('park')!.attachments.single.remotePath, backup.uploads.single);
    });

    test('a private trip without Plus stays on this phone', () async {
      repository.putTrip(sharedTrip(members: const ['me']));
      final ticket = await ticketFile('park.png');
      await store.saveBooking(booking('park', BookingKind.attraction, d(10, 14), tripId: 'orlando')
          .copyWith(attachments: [ticket]));
      await pumpEventQueue();
      await store.syncTickets();
      expect(backup.uploads, isEmpty);
    });

    test('a family member\'s phone downloads tickets it does not have', () async {
      repository.putTrip(sharedTrip());
      const remote = 'trips/orlando/attachments/abc.png';
      backup.cloud[remote] = 'from the family'.codeUnits;
      const attachment = Attachment(id: 'abc', name: 'Tickets', fileName: 'abc.png', sizeBytes: 15, remotePath: remote);

      final file = await store.ticketFile(attachment);
      expect(await file!.readAsString(), 'from the family');
    });

    test('removing a ticket removes its cloud copy', () async {
      repository.putTrip(sharedTrip());
      final ticket = await ticketFile('park.png');
      await store.saveBooking(booking('park', BookingKind.attraction, d(10, 14), tripId: 'orlando')
          .copyWith(attachments: [ticket]));
      await pumpEventQueue();
      await store.syncTickets();
      await pumpEventQueue();
      await store.deleteBooking(store.booking('park')!);
      expect(backup.cloud, isEmpty);
    });
  });

  group('members', () {
    test('names read "You" for yourself', () async {
      repository.putTrip(sharedTrip());
      await pumpEventQueue();
      final plan = store.plan('orlando')!;
      expect(store.memberName(plan, 'me'), 'You');
      expect(store.memberName(plan, 'sam'), 'Sam');
      expect(store.memberName(plan, 'stranger'), 'Traveller');
    });

    test('leaving removes yourself', () async {
      repository.putTrip(sharedTrip(owner: 'sam'));
      await pumpEventQueue();
      await store.leaveTrip(store.plan('orlando')!);
      expect((store.sharing! as _FakeSharing).removed, ['me']);
    });

    test('a family member emptying a trip does not try to delete it', () async {
      repository.putTrip(sharedTrip(owner: 'sam'));
      await store.saveBooking(booking('x', BookingKind.dining, d(10, 14), tripId: 'orlando'));
      await pumpEventQueue();
      await store.deleteBooking(store.booking('x')!);
      await pumpEventQueue();
      expect(store.plan('orlando'), isNotNull);
    });
  });

  group('trip screen', () {
    setUpAll(() => TravaryText.useGoogleFonts = false);

    Future<void> pumpTrip(WidgetTester tester, Trip trip) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final repo = MemoryTravelRepository(userId: 'me')..putTrip(trip);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TravelStore(repository: repo, artCatalog: const ArtCatalog.empty(), sharing: _FakeSharing()),
          ),
          ChangeNotifierProvider(create: (_) => PremiumStore(purchases: TestPurchaseService())),
        ],
        child: MaterialApp(theme: buildTravaryTheme(), home: TripScreen(tripId: trip.id)),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('shows who is coming, with the organiser marked', (tester) async {
      await pumpTrip(tester, sharedTrip(members: const ['me', 'sam', 'kim']));
      expect(find.text('WHO\'S COMING'), findsOneWidget);
      expect(find.textContaining('You'), findsWidgets);
      expect(find.textContaining('Organiser'), findsOneWidget);
      expect(find.textContaining('Kim'), findsOneWidget);
      expect(find.byTooltip('Remove from trip'), findsNWidgets(2));
      expect(find.text('Invite more'), findsOneWidget);
    });

    testWidgets('family members can leave but not remove others', (tester) async {
      await pumpTrip(tester, sharedTrip(owner: 'sam'));
      expect(find.byTooltip('Remove from trip'), findsNothing);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Leave trip'), findsOneWidget);
      expect(find.text('Delete trip'), findsNothing);
    });
  });
}
