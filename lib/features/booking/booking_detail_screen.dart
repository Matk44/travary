import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/art/art_slots.dart';
import '../../design/cards/booking_card.dart';
import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/ledger.dart';
import '../../domain/domain.dart';
import '../../logic/access.dart';
import '../../logic/card_text.dart';
import '../../logic/flight_status_text.dart';
import '../../logic/price_text.dart';
import '../../state/premium_store.dart';
import '../../state/travel_store.dart';
import '../premium/premium_gate.dart';
import '../trips/trip_screen.dart';
import 'attachment_viewer.dart';
import 'booking_actions.dart';
import 'edit_booking_screen.dart';
import 'flight_alerts_row.dart';
import 'flight_status_panel.dart';
import 'ticket_file.dart';

/// A booking's own page: its card, live flight status close to the day and
/// flight alerts (asking for notifications on a paid trip), the details on
/// a paper panel (copy the reference, open the place in maps),
/// its tickets, and the trip it's part of.
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
    final plan = store.plan(booking.tripId) ?? store.focus.plan;
    return TravaryChrome(
      colors: TripColors.of(store.paletteFor(plan)),
      slots: store.chromeArtFor(plan),
      child: Builder(builder: (context) => _Page(booking: booking)),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final colors = TravaryChrome.of(context).colors;
    final spec = booking.kind.spec;
    final trip = store.plan(booking.tripId)?.trip;
    final today = LocalDate.fromDateTime(store.now);
    final ticketsLeft = context.watch<PremiumStore?>()?.policy.ticketFilesLeft(
      store.plan(booking.tripId),
      kept: ticketFilesIn(store.plan(booking.tripId)),
    );
    final flightStatus = store.flightStatus;
    final flightLookup = flightStatus == null ? null : flightLookupFor(booking, today);
    final reference = booking.reference;
    final location = booking.location;

    final rows = <Widget>[
      _InfoRow(label: 'When', value: describeWhen(booking)),
      if (location != null)
        _InfoRow(
          label: spec.locationLabel,
          value: location,
          action: IconButton(
            tooltip: 'Open in maps',
            icon: Icon(Icons.map_outlined, color: colors.ink),
            onPressed: () => _openMaps(location),
          ),
        ),
      if (reference != null)
        _InfoRow(
          label: 'Booking reference',
          value: reference,
          valueStyle: TravaryText.ticketDate.copyWith(fontSize: 18, color: colors.ink),
          action: IconButton(
            tooltip: 'Copy',
            icon: Icon(Icons.copy_rounded, color: colors.ink),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reference));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reference copied')));
            },
          ),
        ),
      for (final field in spec.fields)
        if (booking.detail(field.key) case final value?) _InfoRow(label: field.label, value: value),
      if (booking.notes case final notes?) _InfoRow(label: 'Notes', value: notes),
    ];

    return LinenBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _bar(
          AppBar(
            backgroundColor: Colors.transparent,
            // Dark clock and battery on the light linen.
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditBookingScreen(kind: booking.kind, existing: booking),
                  ),
                ),
                style: TextButton.styleFrom(foregroundColor: colors.ink),
                child: Text('Edit', style: TravaryText.label.copyWith(color: colors.ink)),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') _confirmDelete(context, store);
                },
                itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))],
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.xxl),
          children: [
            BookingCard(
              text: cardTextForBooking(booking),
              art: store.artFor(booking),
              size: CardSize.hero,
              onShowTickets: booking.hasTickets
                  ? () => showTickets(context, booking)
                  : () => _addAttachment(context, store),
            ),
            if (flightLookup != null)
              FlightStatusPanel(service: flightStatus!, lookup: flightLookup, now: () => store.now)
            else if (flightStatus != null && flightStatusComesLater(booking, today))
              Padding(
                padding: const EdgeInsets.only(top: TravarySpace.md),
                child: Text(flightStatusComesLaterText, style: TravaryText.small),
              ),
            if (FlightAlertsRow.showsFor(context, booking, today))
              FlightAlertsRow(booking: booking, plan: store.plan(booking.tripId), now: store.now),
            const SizedBox(height: TravarySpace.lg),
            PaperPanel(
              child: Column(
                children: [
                  for (final (index, row) in rows.indexed) ...[if (index > 0) const PaperDivider(), row],
                ],
              ),
            ),
            const SizedBox(height: TravarySpace.lg),
            Padding(
              padding: const EdgeInsets.only(left: TravarySpace.xs, bottom: TravarySpace.sm),
              child: Text('Tickets & documents', style: TravaryText.title),
            ),
            PaperPanel(
              child: Column(
                children: [
                  for (final (index, attachment) in booking.attachments.indexed) ...[
                    _AttachmentRow(
                      attachment: attachment,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AttachmentViewer(bookingId: booking.id, initialIndex: index),
                        ),
                      ),
                    ),
                    const PaperDivider(),
                  ],
                  PaperRow(
                    key: const ValueKey('attach-ticket'),
                    title: booking.attachments.isEmpty ? 'Attach your ticket' : 'Attach another',
                    subtitle: booking.attachments.isEmpty || ticketsLeft != null ? attachTicketHint(ticketsLeft) : null,
                    titleStyle: TravaryText.label.copyWith(fontSize: 16),
                    leading: const RowIcon(IconSlot.attach),
                    onTap: () => _addAttachment(context, store),
                  ),
                ],
              ),
            ),
            if (trip != null) ...[
              const SizedBox(height: TravarySpace.lg),
              PaperPanel(
                child: PaperRow(
                  title: trip.title,
                  subtitle: 'Part of this trip',
                  leading: const RowIcon(IconSlot.navTrips),
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripScreen(tripId: trip.id))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addAttachment(BuildContext context, TravelStore store) async {
    final plan = store.plan(booking.tripId);
    final room = await requireTicketRoom(context, plan, kept: ticketFilesIn(plan), source: 'attach_ticket');
    if (!room || !context.mounted) return;
    final attachment = await pickAttachment(context);
    if (attachment == null) return;
    await store.saveBooking(booking.copyWith(attachments: [...booking.attachments, attachment]), previous: booking);
  }

  Future<void> _confirmDelete(BuildContext context, TravelStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${booking.title}?'),
        content: booking.hasTickets ? const Text('Its tickets and documents will be deleted too.') : null,
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

/// A detail on the paper panel: its label in small capitals over the value.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueStyle, this.action});

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(TravarySpace.lg, TravarySpace.md, TravarySpace.xs, TravarySpace.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: TravaryText.fieldLabel),
                const SizedBox(height: 3),
                SelectableText(value, style: valueStyle ?? TravaryText.body.copyWith(color: colors.ink)),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.attachment, required this.onTap});

  final Attachment attachment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final icon = Icon(
      attachment.isPdf ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined,
      size: 30,
      color: colors.ink,
    );
    final thumbnail = attachment.isImage
        ? TicketFileBuilder(
            attachment: attachment,
            builder: (context, file, loading) => file == null
                ? (loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_download_outlined))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      file,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          )
        : icon;
    return PaperRow(
      title: attachment.name,
      titleStyle: TravaryText.label,
      leading: SizedBox(width: 44, height: 44, child: Center(child: thumbnail)),
      onTap: onTap,
    );
  }
}

/// The top bar with its text kept to [BarText.maxScale].
PreferredSizeWidget _bar(AppBar bar) => PreferredSize(
  preferredSize: bar.preferredSize,
  child: BarText(child: bar),
);
