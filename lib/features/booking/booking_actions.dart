import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/attachment_store.dart';
import '../../design/art/art_slots.dart';
import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/ledger.dart';
import '../../domain/domain.dart';
import '../../logic/card_text.dart';
import '../../state/premium_store.dart';
import '../../state/travel_store.dart';
import '../import/smart_import_screen.dart';
import '../premium/premium_gate.dart';
import '../travel_documents/document_actions.dart';
import 'attachment_viewer.dart';
import 'booking_detail_screen.dart';
import 'edit_booking_screen.dart';

/// The add flow: pick a kind, fill in a short form, done. The booking joins
/// the right trip automatically unless [tripId] says otherwise.
Future<void> startAddBooking(BuildContext context, {LocalDate? date, String? tripId}) async {
  final choice = await showModalBottomSheet<AddChoice>(
    context: context,
    backgroundColor: TravaryColors.linen,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const KindPickerSheet(),
  );
  if (choice == null || !context.mounted) return;
  final kind = switch (choice) {
    ManualChoice(:final kind) => kind,
    SmartImportChoice() || TravelDocumentChoice() => null,
  };
  if (choice is TravelDocumentChoice) {
    await startAddTravelDocument(context);
    return;
  }
  if (kind == null) {
    await _startSmartImport(context, tripId: tripId);
    return;
  }
  await addBookingOfKind(context, kind, date: date, tripId: tripId);
}

/// Straight to the form for [kind] (e.g. "Add your flights" on a new trip),
/// then says where the booking went.
Future<void> addBookingOfKind(
  BuildContext context,
  BookingKind kind, {
  LocalDate? date,
  LocalDate? endDate,
  String? tripId,
}) async {
  final result = await Navigator.of(context).push<SaveResult>(
    MaterialPageRoute(
      builder: (_) => EditBookingScreen(kind: kind, initialDate: date, initialEndDate: endDate, tripId: tripId),
    ),
  );
  if (result == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result.newTrip ? 'Added to a new trip: ${result.tripTitle}' : 'Added to ${result.tripTitle}'),
    ),
  );
}

/// What the traveller picked in the add sheet.
sealed class AddChoice {
  const AddChoice();
}

class ManualChoice extends AddChoice {
  const ManualChoice(this.kind);

  final BookingKind kind;
}

class SmartImportChoice extends AddChoice {
  const SmartImportChoice();
}

/// A passport, visa or insurance: not a booking, kept on this phone only.
class TravelDocumentChoice extends AddChoice {
  const TravelDocumentChoice();
}

/// Smart Import: premium, with a few free uses. Pick a file, it's read in
/// the cloud, and the traveller checks what was found before it's saved.
Future<void> _startSmartImport(BuildContext context, {String? tripId}) async {
  final travel = context.read<TravelStore>();
  final plan = tripId == null ? travel.focus.plan : travel.plan(tripId);
  final access = await requirePremium(context, PremiumFeature.smartImport, trip: plan, source: 'add_sheet');
  if (access == null || !context.mounted) return;
  final file = await pickFile(context, title: 'What shall we read?');
  if (file == null || !context.mounted) return;
  final outcome = await Navigator.of(context).push<SmartImportOutcome>(
    MaterialPageRoute(
      builder: (_) => SmartImportScreen(filePath: file.path, fileName: file.name, access: access, tripId: tripId),
    ),
  );
  if (outcome == null || !context.mounted) return;
  if (outcome.addManually) {
    await startAddBooking(context, tripId: tripId);
    return;
  }
  if (outcome.added == 0) return;
  final where = outcome.trips.length == 1 ? outcome.trips.single : '${outcome.trips.length} trips';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(outcome.added == 1 ? 'Added to $where' : 'Added ${outcome.added} bookings to $where')),
  );
}

void openBooking(BuildContext context, Booking booking) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: booking.id)));
}

/// Straight to the tickets: the first attachment, or the booking details
/// (which show the reference number) when nothing is attached.
void showTickets(BuildContext context, Booking booking) {
  if (booking.attachments.isEmpty) {
    openBooking(context, booking);
    return;
  }
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AttachmentViewer(bookingId: booking.id)));
}

/// The "Show tickets" callback for a card, or null if there's nothing to show.
VoidCallback? ticketsAction(BuildContext context, Booking booking) =>
    showsTickets(booking) ? () => showTickets(context, booking) : null;

/// Asks for a photo/screenshot or a file. Returns its path and name.
Future<({String path, String name})?> pickFile(BuildContext context, {String? title}) async {
  final type = await showModalBottomSheet<FileType>(
    context: context,
    backgroundColor: TravaryColors.linen,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title, style: TravaryText.title),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.photo_outlined),
            title: const Text('Photo or screenshot'),
            onTap: () => Navigator.pop(context, FileType.image),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('PDF or other file'),
            onTap: () => Navigator.pop(context, FileType.custom),
          ),
          const SizedBox(height: TravarySpace.sm),
        ],
      ),
    ),
  );
  if (type == null) return null;

  final files = await FilePicker.pickFiles(
    type: type,
    allowedExtensions: type == FileType.custom ? const ['pdf', 'png', 'jpg', 'jpeg', 'heic', 'webp'] : null,
  );
  final path = files.isEmpty ? null : files.first.path;
  if (path == null) return null;
  return (path: path, name: files.first.name);
}

/// Asks for a photo/screenshot or a file and copies it into the app.
Future<Attachment?> pickAttachment(BuildContext context) async {
  final AttachmentStore? attachments = context.read<TravelStore>().attachments;
  if (attachments == null) return null;
  final file = await pickFile(context);
  if (file == null) return null;
  return attachments.import(file.path, name: file.name);
}

/// "Add a booking": Snap a booking (Smart Import) first, then the four
/// kinds people add most, the other four folded under "More booking
/// types", and passports and other travel documents (kept on this phone)
/// at the end.
class KindPickerSheet extends StatefulWidget {
  const KindPickerSheet({super.key});

  /// The kinds shown straight away; the rest wait under "More booking types".
  static const common = [BookingKind.flight, BookingKind.stay, BookingKind.attraction, BookingKind.dining];

  @override
  State<KindPickerSheet> createState() => _KindPickerSheetState();
}

class _KindPickerSheetState extends State<KindPickerSheet> {
  bool _more = false;

  @override
  Widget build(BuildContext context) {
    final chrome = TravaryChrome.of(context);
    final others = [
      for (final kind in BookingKind.values)
        if (!KindPickerSheet.common.contains(kind)) kind,
    ];
    Widget kindRow(BookingKind kind) => PaperRow(
      key: ValueKey('add-${kind.name}'),
      title: kind.spec.label,
      titleStyle: TravaryText.label.copyWith(fontSize: 16.5),
      leading: RowIcon(IconSlot.forKind(kind)),
      onTap: () => Navigator.pop(context, ManualChoice(kind)),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Add a booking', style: TravaryText.ledgerHeading)),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: chrome.colors.ink),
                ),
              ],
            ),
            const SizedBox(height: TravarySpace.md),
            if (PremiumFeature.smartImport.released || kDebugMode) ...[
              const _SnapRow(),
              const SizedBox(height: TravarySpace.lg),
            ],
            Padding(
              padding: const EdgeInsets.only(left: TravarySpace.xs, bottom: TravarySpace.sm),
              child: Text('Add manually', style: TravaryText.title),
            ),
            PaperPanel(
              child: Column(
                children: [
                  for (final (index, kind) in KindPickerSheet.common.indexed) ...[
                    if (index > 0) const PaperDivider(),
                    kindRow(kind),
                  ],
                  const PaperDivider(),
                  PaperRow(
                    key: const ValueKey('add-more-kinds'),
                    title: 'More booking types',
                    subtitle: _more ? null : others.map((kind) => kind.spec.label).join(', '),
                    titleStyle: TravaryText.label.copyWith(fontSize: 16.5),
                    trailing: Icon(
                      _more ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: TravaryColors.inkSoft,
                    ),
                    onTap: () => setState(() => _more = !_more),
                  ),
                  if (_more)
                    for (final kind in others) ...[const PaperDivider(), kindRow(kind)],
                ],
              ),
            ),
            const SizedBox(height: TravarySpace.lg),
            PaperPanel(
              child: PaperRow(
                key: const ValueKey('add-travel-document'),
                title: 'Passport & documents',
                subtitle: 'Passport, visa or insurance, kept on this phone only',
                leading: RowPicture(
                  image: chrome.slots.surface(SurfaceSlot.addPassport),
                  fallback: Icons.menu_book_rounded,
                ),
                onTap: () => Navigator.pop(context, const TravelDocumentChoice()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Snap a booking": Smart Import, with how many free uses are left.
class _SnapRow extends StatelessWidget {
  const _SnapRow();

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumStore>();
    final travel = context.watch<TravelStore>();
    final chrome = TravaryChrome.of(context);
    final decision = premium.decide(PremiumFeature.smartImport, trip: travel.focus.plan);
    final String status;
    if (!decision.allowed) {
      status = 'Travary Plus';
    } else if (decision.isFreeUse) {
      status = '${decision.freeUsesLeft} free to try';
    } else {
      status = 'Included with Plus';
    }
    return PaperPanel(
      child: PaperRow(
        key: const ValueKey('add-snap'),
        title: 'Snap a booking',
        subtitle: 'Photo, screenshot or PDF\n$status',
        leading: RowPicture(
          image: chrome.slots.surface(SurfaceSlot.addSnap),
          fallback: Icons.document_scanner_outlined,
          size: 72,
        ),
        onTap: () => Navigator.pop(context, const SmartImportChoice()),
      ),
    );
  }
}
