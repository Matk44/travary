import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../domain/domain.dart';
import '../../state/travel_store.dart';
import 'ticket_file.dart';

/// Full-screen tickets, on white for easy scanning. Swipe between a
/// booking's attachments; images zoom, PDFs open in the system viewer.
class AttachmentViewer extends StatefulWidget {
  const AttachmentViewer({
    super.key,
    required this.bookingId,
    this.initialIndex = 0,
  });

  final String bookingId;
  final int initialIndex;

  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final booking = store.booking(widget.bookingId);
    final attachments = booking?.attachments ?? const <Attachment>[];
    if (booking == null || attachments.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No tickets attached.')),
      );
    }
    final current = attachments[_index.clamp(0, attachments.length - 1)];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(booking.title, style: TravaryText.label),
        actions: [
          IconButton(
            tooltip: 'Remove from booking',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _remove(store, booking, current),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: attachments.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                final attachment = attachments[index];
                return TicketFileBuilder(
                  attachment: attachment,
                  builder: (context, file, loading) {
                    if (loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (file == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(TravarySpace.xl),
                          child: Text(
                            'This ticket isn\'t on this phone yet. It will download when you\'re online.',
                            style: TravaryText.bodySoft,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    if (attachment.isImage) {
                      return InteractiveViewer(
                        maxScale: 5,
                        child: Center(
                          child: Image.file(
                            file,
                            errorBuilder: (_, _, _) =>
                                const Text('This file can\'t be shown.'),
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 64,
                            color: TravaryColors.inkSoft,
                          ),
                          const SizedBox(height: TravarySpace.md),
                          Text(
                            attachment.name,
                            style: TravaryText.label,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: TravarySpace.lg),
                          FilledButton.icon(
                            onPressed: () => OpenFilex.open(file.path),
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('Open'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (attachments.length > 1)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(TravarySpace.md),
                child: Text(
                  '${_index + 1} of ${attachments.length}',
                  style: TravaryText.small,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _remove(
    TravelStore store,
    Booking booking,
    Attachment attachment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${attachment.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final remaining = [...booking.attachments]..remove(attachment);
    await store.saveBooking(
      booking.copyWith(attachments: remaining),
      previous: booking,
    );
    if (!mounted) return;
    if (remaining.isEmpty) {
      Navigator.of(context).pop();
    } else {
      setState(() => _index = _index.clamp(0, remaining.length - 1));
    }
  }
}
