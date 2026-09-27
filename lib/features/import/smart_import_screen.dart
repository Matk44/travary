import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/smart_import_service.dart';
import '../../design/cards/booking_card.dart';
import '../../design/tokens.dart';
import '../../design/widgets/common.dart';
import '../../domain/domain.dart';
import '../../logic/access.dart';
import '../../logic/card_text.dart';
import '../../state/analytics.dart';
import '../../state/premium_store.dart';
import '../../state/travel_store.dart';
import '../booking/edit_booking_screen.dart';

/// What happened, for the "Added to Orlando" message.
class SmartImportOutcome {
  const SmartImportOutcome({
    this.added = 0,
    this.trips = const {},
    this.addManually = false,
  });

  final int added;
  final Set<String> trips;

  /// The traveller chose to type the booking in instead.
  final bool addManually;
}

/// Reads a screenshot/photo/PDF, then lets the traveller check what was
/// found. One booking goes straight to a pre-filled form; several show as a
/// list to add together or check one by one. Nothing is saved unchecked.
class SmartImportScreen extends StatefulWidget {
  const SmartImportScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.access,
    this.tripId,
  });

  final String filePath;
  final String fileName;

  /// The gate decision; free uses are counted once something is found.
  final AccessDecision access;
  final String? tripId;

  @override
  State<SmartImportScreen> createState() => _SmartImportScreenState();
}

enum _Phase { reading, failed, empty, review }

class _SmartImportScreenState extends State<SmartImportScreen> {
  _Phase _phase = _Phase.reading;
  SmartImportResult? _result;
  String? _error;
  final _selected = <int>{};
  final _saved = <int>{};
  final _trips = <String>{};
  bool _saving = false;

  List<BookingDraft> get _drafts => _result?.drafts ?? const [];

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    setState(() => _phase = _Phase.reading);
    final service = context.read<SmartImportService>();
    final today = context.read<TravelStore>().today;
    final premium = context.read<PremiumStore>();
    try {
      final result = await service.read(widget.filePath, today: today);
      if (!mounted) return;
      track('smart_import_read', {'bookings': result.drafts.length});
      if (result.drafts.isEmpty) {
        setState(() {
          _result = result;
          _phase = _Phase.empty;
        });
        return;
      }
      await premium.countSmartImport(widget.access);
      if (!mounted) return;
      setState(() {
        _result = result;
        _selected
          ..clear()
          ..addAll(List.generate(result.drafts.length, (i) => i));
        _phase = _Phase.review;
      });
      if (result.drafts.length == 1) await _checkOne(0, closeAfter: true);
    } on SmartImportException catch (e) {
      track('smart_import_failed', {'reason': e.message});
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _phase = _Phase.failed;
      });
    }
  }

  /// Opens the pre-filled form for one draft.
  Future<void> _checkOne(int index, {bool closeAfter = false}) async {
    final draft = _drafts[index];
    final result = await Navigator.of(context).push<SaveResult>(
      MaterialPageRoute(
        builder: (_) => EditBookingScreen(
          kind: draft.booking.kind,
          draft: draft,
          tripId: widget.tripId,
          sourceFilePath: widget.filePath,
          sourceFileName: widget.fileName,
        ),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _saved.add(index);
        _selected.remove(index);
        _trips.add(result.tripTitle);
      });
    }
    if (closeAfter || _saved.length == _drafts.length) _finish();
  }

  Future<void> _addSelected() async {
    setState(() => _saving = true);
    final store = context.read<TravelStore>();
    final bookings = <Booking>[];
    for (final index in _selected.toList()..sort()) {
      final attachment = await store.attachments?.import(
        widget.filePath,
        name: widget.fileName,
      );
      bookings.add(
        _drafts[index].booking.copyWith(
          id: store.repository.newId(),
          tripId: widget.tripId ?? '',
          attachments: [?attachment],
        ),
      );
    }
    final results = await store.saveBookings(bookings);
    if (!mounted) return;
    _trips.addAll(results.map((r) => r.tripTitle));
    _saved.addAll(_selected);
    _selected.clear();
    _finish();
  }

  void _finish() {
    Navigator.of(
      context,
    ).pop(SmartImportOutcome(added: _saved.length, trips: _trips));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Import')),
      body: switch (_phase) {
        _Phase.reading => _Reading(filePath: widget.filePath),
        _Phase.failed => _Problem(
          title: 'Couldn\'t read that',
          message: _error ?? 'Something went wrong.',
          onRetry: _read,
        ),
        _Phase.empty => _Problem(
          title: 'No booking found',
          message:
              _result?.warning ??
              'We couldn\'t find a booking in that file. Try a clearer screenshot, or add it yourself.',
          onRetry: null,
        ),
        _Phase.review => _review(context),
      },
    );
  }

  Widget _review(BuildContext context) {
    final store = context.watch<TravelStore>();
    final art = store.artForAll([for (final d in _drafts) d.booking]);
    final toAdd = _selected.length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              TravarySpace.gutter,
              0,
              TravarySpace.gutter,
              TravarySpace.lg,
            ),
            children: [
              Text(
                _drafts.length == 1
                    ? 'We found 1 booking'
                    : 'We found ${_drafts.length} bookings',
                style: TravaryText.headline,
              ),
              const SizedBox(height: TravarySpace.xs),
              Text(
                'Tap one to check its details, or add them all.',
                style: TravaryText.bodySoft,
              ),
              if (_result?.warning != null) ...[
                const SizedBox(height: TravarySpace.sm),
                Text(
                  _result!.warning!,
                  style: TravaryText.small.copyWith(color: TravaryColors.coral),
                ),
              ],
              const SizedBox(height: TravarySpace.lg),
              for (final (index, draft) in _drafts.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: TravarySpace.sm),
                  child: Row(
                    children: [
                      Checkbox(
                        value:
                            _saved.contains(index) || _selected.contains(index),
                        onChanged: _saved.contains(index)
                            ? null
                            : (on) => setState(
                                () => on == true
                                    ? _selected.add(index)
                                    : _selected.remove(index),
                              ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            BookingCard(
                              text: cardTextForReview(draft.booking),
                              art: art[index],
                              size: CardSize.compact,
                              onTap: _saved.contains(index)
                                  ? null
                                  : () => _checkOne(index),
                            ),
                            if (_saved.contains(index))
                              Text(
                                'Added',
                                style: TravaryText.small.copyWith(
                                  color: TravaryColors.teal,
                                ),
                              )
                            else if (draft.uncertain.isNotEmpty)
                              Text(
                                'Check ${draft.uncertain.length} detail${draft.uncertain.length == 1 ? '' : 's'}',
                                style: TravaryText.small.copyWith(
                                  color: TravaryColors.coral,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TravarySpace.gutter,
              TravarySpace.sm,
              TravarySpace.gutter,
              TravarySpace.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : (toAdd == 0 ? _finish : _addSelected),
                child: Text(
                  toAdd == 0
                      ? 'Done'
                      : 'Add $toAdd booking${toAdd == 1 ? '' : 's'}',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    final isImage =
        smartImportMimeType(filePath)?.startsWith('image/') ?? false;
    return Padding(
      padding: const EdgeInsets.all(TravarySpace.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  color: TravaryColors.paper,
                  borderRadius: BorderRadius.circular(TravaryRadius.card),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: isImage
                    ? Image.file(
                        File(filePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const SizedBox(width: 200, height: 200),
                      )
                    : const SizedBox(
                        width: 200,
                        height: 200,
                        child: Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 64,
                          color: TravaryColors.inkSoft,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: TravarySpace.xl),
          Text(
            'Reading your booking…',
            style: TravaryText.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TravarySpace.sm),
          Text(
            'This usually takes a few seconds.',
            style: TravaryText.bodySoft,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TravarySpace.lg),
          const Center(
            child: SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                color: TravaryColors.coral,
                backgroundColor: TravaryColors.paperEdge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(
              icon: Icons.document_scanner_outlined,
              title: title,
              message: message,
            ),
            if (onRetry != null)
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            const SizedBox(height: TravarySpace.sm),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pop(const SmartImportOutcome(addManually: true)),
              child: const Text('Add it myself'),
            ),
          ],
        ),
      ),
    );
  }
}
