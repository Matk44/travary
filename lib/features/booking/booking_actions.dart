import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/attachment_store.dart';
import '../../design/kind_style.dart';
import '../../design/tokens.dart';
import '../../domain/domain.dart';
import '../../state/travel_store.dart';
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
  final kind = await showModalBottomSheet<BookingKind>(
    context: context,
    backgroundColor: TravaryColors.linen,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const KindPickerSheet(),
  );
  if (kind == null || !context.mounted) return;
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

/// Asks for a photo/screenshot or a file and copies it into the app.
Future<Attachment?> pickAttachment(BuildContext context) async {
  final store = context.read<TravelStore>();
  final AttachmentStore? attachments = store.attachments;
  if (attachments == null) return null;

  final type = await showModalBottomSheet<FileType>(
    context: context,
    backgroundColor: TravaryColors.linen,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
  return attachments.import(path, name: files.first.name);
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
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: TravarySpace.md,
              crossAxisSpacing: TravarySpace.md,
              childAspectRatio: 0.82,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final kind in BookingKind.values)
                  _KindTile(kind: kind, onTap: () => Navigator.pop(context, kind)),
              ],
            ),
          ],
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
