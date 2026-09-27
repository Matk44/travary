import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/attachment_store.dart';
import '../../design/kind_style.dart';
import '../../design/tokens.dart';
import '../../domain/domain.dart';
import '../../state/premium_store.dart';
import '../../state/travel_store.dart';
import '../import/smart_import_screen.dart';
import '../premium/premium_gate.dart';
import 'attachment_viewer.dart';
import 'booking_detail_screen.dart';
import 'edit_booking_screen.dart';

/// The add flow: pick a kind, fill in a short form, done. The booking joins
/// the right trip automatically unless [tripId] says otherwise.
Future<void> startAddBooking(
  BuildContext context, {
  LocalDate? date,
  String? tripId,
}) async {
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
    SmartImportChoice() => null,
  };
  if (kind == null) {
    await _startSmartImport(context, tripId: tripId);
    return;
  }
  final result = await Navigator.of(context).push<SaveResult>(
    MaterialPageRoute(
      builder: (_) => EditBookingScreen(kind: kind, initialDate: date, tripId: tripId),
    ),
  );
  if (result == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.newTrip
            ? 'Added to a new trip: ${result.tripTitle}'
            : 'Added to ${result.tripTitle}',
      ),
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

/// Smart Import: premium, with a few free uses. Pick a file, it's read in
/// the cloud, and the traveller checks what was found before it's saved.
Future<void> _startSmartImport(BuildContext context, {String? tripId}) async {
  final travel = context.read<TravelStore>();
  final plan = tripId == null ? travel.focus.plan : travel.plan(tripId);
  final access = await requirePremium(
    context,
    PremiumFeature.smartImport,
    trip: plan,
    source: 'add_sheet',
  );
  if (access == null || !context.mounted) return;
  final file = await pickFile(context, title: 'What shall we read?');
  if (file == null || !context.mounted) return;
  final outcome = await Navigator.of(context).push<SmartImportOutcome>(
    MaterialPageRoute(
      builder: (_) => SmartImportScreen(
        filePath: file.path,
        fileName: file.name,
        access: access,
        tripId: tripId,
      ),
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
    SnackBar(
      content: Text(
        outcome.added == 1 ? 'Added to $where' : 'Added ${outcome.added} bookings to $where',
      ),
    ),
  );
}

void openBooking(BuildContext context, Booking booking) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: booking.id)),
  );
}

/// Straight to the tickets: the first attachment, or the booking details
/// (which show the reference number) when nothing is attached.
void showTickets(BuildContext context, Booking booking) {
  if (booking.attachments.isEmpty) {
    openBooking(context, booking);
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => AttachmentViewer(bookingId: booking.id)),
  );
}

/// The "Show tickets" callback for a card, or null if there's nothing to show.
VoidCallback? ticketsAction(BuildContext context, Booking booking) =>
    booking.hasTickets || (booking.reference?.trim().isNotEmpty ?? false)
    ? () => showTickets(context, booking)
    : null;

/// Asks for a photo/screenshot or a file. Returns its path and name.
Future<({String path, String name})?> pickFile(
  BuildContext context, {
  String? title,
}) async {
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
              child: Align(alignment: Alignment.centerLeft, child: Text(title, style: TravaryText.title)),
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
    allowedExtensions: type == FileType.custom
        ? const ['pdf', 'png', 'jpg', 'jpeg', 'heic', 'webp']
        : null,
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

/// Eight big tiles, one per kind of booking.
class KindPickerSheet extends StatelessWidget {
  const KindPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What have you booked?', style: TravaryText.headline),
            const SizedBox(height: TravarySpace.lg),
            if (PremiumFeature.smartImport.released || kDebugMode) ...[
              const _SmartImportTile(),
              const SizedBox(height: TravarySpace.md),
            ],
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: TravarySpace.md,
              crossAxisSpacing: TravarySpace.md,
              childAspectRatio: 0.82,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final kind in BookingKind.values)
                  _KindTile(kind: kind, onTap: () => Navigator.pop(context, ManualChoice(kind))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Import from a screenshot or PDF", with how many free uses are left.
class _SmartImportTile extends StatelessWidget {
  const _SmartImportTile();

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumStore>();
    final travel = context.watch<TravelStore>();
    final decision = premium.decide(PremiumFeature.smartImport, trip: travel.focus.plan);
    final String status;
    if (!decision.allowed) {
      status = 'Travary Plus';
    } else if (decision.isFreeUse) {
      status = '${decision.freeUsesLeft} free to try';
    } else {
      status = 'Included with Plus';
    }
    return Material(
      color: TravaryColors.ink,
      borderRadius: BorderRadius.circular(TravaryRadius.card),
      child: InkWell(
        onTap: () => Navigator.pop(context, const SmartImportChoice()),
        borderRadius: BorderRadius.circular(TravaryRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(TravarySpace.lg),
          child: Row(
            children: [
              const Icon(Icons.document_scanner_outlined, color: TravaryColors.paper, size: 28),
              const SizedBox(width: TravarySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Import a screenshot or PDF',
                        style: TravaryText.label.copyWith(color: TravaryColors.paper)),
                    Text('We fill in the details for you',
                        style: TravaryText.small.copyWith(color: TravaryColors.paper.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: decision.allowed ? TravaryColors.paper : TravaryColors.mustard,
                  borderRadius: BorderRadius.circular(TravaryRadius.chip),
                ),
                child: Text(status, style: TravaryText.small.copyWith(color: TravaryColors.ink, fontSize: 11.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindTile extends StatelessWidget {
  const _KindTile({required this.kind, required this.onTap});

  final BookingKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = KindStyle.of(kind);
    return Material(
      color: TravaryColors.paper,
      borderRadius: BorderRadius.circular(TravaryRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TravaryRadius.card),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(style.icon, size: 30, color: TravaryColors.ink),
            const SizedBox(height: TravarySpace.sm),
            Text(kind.spec.label, style: TravaryText.small.copyWith(color: TravaryColors.ink)),
          ],
        ),
      ),
    );
  }
}
