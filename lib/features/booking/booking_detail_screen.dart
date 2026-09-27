import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/cards/booking_card.dart';
import '../../design/tokens.dart';
import '../../design/widgets/common.dart';
import '../../domain/domain.dart';
import '../../logic/card_text.dart';
import '../../state/travel_store.dart';
import '../trips/trip_screen.dart';
import 'attachment_viewer.dart';
import 'booking_actions.dart';
import 'edit_booking_screen.dart';

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final booking = store.booking(bookingId);
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This booking has been deleted.')),
      );
    }
    final spec = booking.kind.spec;
    final trip = store.plan(booking.tripId)?.trip;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditBookingScreen(kind: booking.kind, existing: booking),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _confirmDelete(context, store, booking);
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.xxl),
        children: [
          BookingCard(
            text: cardTextForBooking(booking),
            art: store.artFor(booking),
            size: CardSize.hero,
            onShowTickets: booking.hasTickets ? () => showTickets(context, booking) : null,
          ),
          const SizedBox(height: TravarySpace.lg),
          _InfoRow(icon: Icons.schedule_rounded, label: 'When', value: describeWhen(booking)),
          if (booking.location != null)
            _InfoRow(
              icon: Icons.place_outlined,
              label: spec.locationLabel,
              value: booking.location!,
              actionIcon: Icons.map_outlined,
              actionTooltip: 'Open in maps',
              onAction: () => _openMaps(booking.location!),
            ),
          if (booking.reference != null)
            _InfoRow(
              icon: Icons.confirmation_number_outlined,
              label: 'Booking reference',
              value: booking.reference!,
              valueStyle: TravaryText.title.copyWith(letterSpacing: 1.5),
              actionIcon: Icons.copy_rounded,
              actionTooltip: 'Copy',
              onAction: () {
                Clipboard.setData(ClipboardData(text: booking.reference!));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Reference copied')));
              },
            ),
          for (final field in spec.fields)
            if (booking.detail(field.key) != null)
              _InfoRow(icon: Icons.info_outline_rounded, label: field.label, value: booking.detail(field.key)!),
          if (booking.notes != null)
            _InfoRow(icon: Icons.notes_rounded, label: 'Notes', value: booking.notes!),
          SectionLabel(
            'Tickets & documents',
            inset: false,
            trailing: TextButton.icon(
              onPressed: () => _addAttachment(context, store, booking),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ),
          if (booking.attachments.isEmpty)
            Text(
              'Add a photo or PDF of your tickets so they\'re ready, even offline.',
              style: TravaryText.bodySoft,
            ),
          for (final (index, attachment) in booking.attachments.indexed)
            _AttachmentTile(
              attachment: attachment,
              file: store.attachments?.fileFor(attachment),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AttachmentViewer(bookingId: booking.id, initialIndex: index),
                ),
              ),
            ),
          if (trip != null) ...[
            const SectionLabel('Trip', inset: false),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.luggage_outlined),
              title: Text(trip.title, style: TravaryText.label),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TripScreen(tripId: trip.id)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addAttachment(BuildContext context, TravelStore store, Booking booking) async {
    final attachment = await pickAttachment(context);
    if (attachment == null) return;
    await store.saveBooking(
      booking.copyWith(attachments: [...booking.attachments, attachment]),
      previous: booking,
    );
  }

  Future<void> _confirmDelete(BuildContext context, TravelStore store, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${booking.title}?'),
        content: booking.hasTickets
            ? const Text('Its tickets and documents will be deleted too.')
            : null,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.of(context).pop();
    await store.deleteBooking(booking);
  }

  Future<void> _openMaps(String place) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': place});
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
    this.actionIcon,
    this.actionTooltip,
    this.onAction,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TravarySpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: TravaryColors.inkSoft),
          ),
          const SizedBox(width: TravarySpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TravaryText.small),
                const SizedBox(height: 2),
                SelectableText(value, style: valueStyle ?? TravaryText.body),
              ],
            ),
          ),
          if (actionIcon != null)
            IconButton(tooltip: actionTooltip, icon: Icon(actionIcon), onPressed: onAction),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment, required this.file, required this.onTap});

  final Attachment attachment;
  final File? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumbnail = attachment.isImage && file != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(file!, width: 44, height: 44, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined)),
          )
        : Icon(attachment.isPdf ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined, size: 32);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(width: 44, height: 44, child: Center(child: thumbnail)),
      title: Text(attachment.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
