import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/smart_import_service.dart';
import '../../design/cards/booking_card.dart';
import '../../design/tokens.dart';
import '../../design/widgets/common.dart';
import '../../design/widgets/onboarding_folio.dart';
import '../../design/widgets/travi_cameo.dart';
import '../../domain/domain.dart';
import '../../domain/onboarding.dart';
import '../../logic/access.dart';
import '../../logic/booking_form_text.dart';
import '../../logic/card_text.dart';
import '../../logic/price_text.dart';
import '../../logic/travi_cameos.dart';
import '../../logic/trip_assignment.dart';
import '../../logic/trip_plan.dart';
import '../../logic/trip_window.dart';
import '../../state/analytics.dart';
import '../../state/premium_store.dart';
import '../../state/travel_store.dart';
import '../booking/edit_booking_screen.dart';

/// What happened, for the "Added to Orlando" message.
class SmartImportOutcome {
  const SmartImportOutcome({this.added = 0, this.trips = const {}, this.addManually = false, this.results = const []});

  final int added;
  final Set<String> trips;

  /// Actual saved identities for handing the same booking into onboarding.
  final List<SaveResult> results;

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
    this.onboardingHoliday,
    this.initialResult,
  });

  final String filePath;
  final String fileName;

  /// The gate decision; free uses are counted once something is found.
  final AccessDecision access;

  /// The trip it was opened from. Bookings on its dates go into it; the
  /// rest find their own trip.
  final String? tripId;
  final OnboardingHoliday? onboardingHoliday;

  /// Already read (onboarding reads on its stage while Travi studies the
  /// file): straight to checking it.
  final SmartImportResult? initialResult;

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
  final _results = <SaveResult>[];
  bool _saving = false;

  List<BookingDraft> get _drafts => _result?.drafts ?? const [];

  @override
  void initState() {
    super.initState();
    final read = widget.initialResult;
    if (read == null) {
      _read();
    } else {
      // Shown as found from the first frame; counted and opened just after.
      _result = read;
      _phase = read.drafts.isEmpty ? _Phase.empty : _Phase.review;
      _selected.addAll(List.generate(read.drafts.length, (i) => i));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _found(read, context.read<PremiumStore>());
      });
    }
  }

  Future<void> _read() async {
    setState(() => _phase = _Phase.reading);
    final service = context.read<SmartImportService>();
    final today = context.read<TravelStore>().today;
    final premium = context.read<PremiumStore>();
    try {
      final result = await service.read(widget.filePath, today: today, tripId: widget.access.tripId);
      if (mounted) await _found(result, premium);
    } on SmartImportException catch (e) {
      track('smart_import_failed', {'reason': e.message});
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _phase = _Phase.failed;
      });
    }
  }

  Future<void> _found(SmartImportResult result, PremiumStore premium) async {
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
          onboardingHoliday: widget.onboardingHoliday,
        ),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _saved.add(index);
        _selected.remove(index);
        _trips.add(result.tripTitle);
        _results.add(result);
      });
    }
    if (closeAfter || _saved.length == _drafts.length) _finish();
  }

  /// Whether [draft] goes into the trip the import was opened from (when it
  /// was): its dates fit it, as far as dates on a ticket go.
  bool _fitsTrip(Booking draft, TripPlan? trip) =>
      trip != null && fitsTrip(draft.startDate, draft.lastDate, trip, looseMarginDays: sameSourceMarginDays);

  /// For a draft outside the trip the import was opened from: that trip,
  /// and where its dates take it instead (null: a new trip). Null when it
  /// goes into the trip after all.
  (TripPlan, TripPlan?)? _elsewhere(Booking draft, TripPlan? trip, TravelStore store) {
    if (trip == null || _fitsTrip(draft, trip)) return null;
    final elsewhere = findTripFor(draft.startDate, draft.lastDate, store.plans);
    return elsewhere?.id == trip.id ? null : (trip, elsewhere);
  }

  Future<void> _addSelected() async {
    setState(() => _saving = true);
    final store = context.read<TravelStore>();
    final trip = widget.tripId == null ? null : store.plan(widget.tripId!);
    final policy = context.read<PremiumStore?>()?.policy;
    final messenger = ScaffoldMessenger.of(context);
    final bookings = <Booking>[];
    // The file becomes each booking's ticket while its holiday has room
    // (free holidays keep Pricing.freeTicketFiles; this one file counts
    // once per holiday, however many bookings it holds).
    final keptIn = <String>{};
    var notKept = 0;
    // The file may be gone by now (a share cleared from the cache): the
    // bookings are still saved, without it, rather than nothing at all.
    var fileLost = false;
    final picked = [
      for (final index in _selected.toList()..sort())
        _drafts[index].booking.copyWith(
          id: store.repository.newId(),
          tripId: _fitsTrip(_drafts[index].booking, trip) ? trip!.id : '',
        ),
    ];
    // Where saving will put each one (a new trip for some, perhaps), so
    // the file is counted against the holiday it actually lands in.
    final places = store.importPlaces(picked);
    for (final (i, booking) in picked.indexed) {
      final key = places[i];
      final target = store.plan(key);
      final room =
          policy == null || keptIn.contains(key) || policy.canAttachTickets(target, kept: ticketFilesIn(target));
      Attachment? attachment;
      if (room && !fileLost) {
        try {
          attachment = await store.attachments?.import(widget.filePath, name: widget.fileName);
          keptIn.add(key);
        } on FileSystemException {
          fileLost = true;
        }
      } else if (!room) {
        notKept++;
      }
      bookings.add(booking.copyWith(attachments: [?attachment]));
    }
    final List<SaveResult> results;
    try {
      results = await store.saveBookings(bookings);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(const SnackBar(content: Text('Couldn’t add those bookings. Please try again.')));
      return;
    }
    if (fileLost) {
      messenger.showSnackBar(const SnackBar(content: Text('Added without the file: it couldn’t be kept.')));
    } else if (notKept > 0) {
      messenger.showSnackBar(SnackBar(content: Text(ticketsNotKeptText(notKept))));
    }
    if (!mounted) return;
    _trips.addAll(results.map((r) => r.tripTitle));
    _results.addAll(results);
    _saved.addAll(_selected);
    _selected.clear();
    _finish();
  }

  void _finish() {
    Navigator.of(
      context,
    ).pop(SmartImportOutcome(added: _saved.length, trips: _trips, results: List.unmodifiable(_results)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onboardingHoliday != null) {
      return OnboardingFolio(
        body: _phase == _Phase.review
            ? _review(context)
            : ListView(
                padding: const EdgeInsets.all(TravarySpace.gutter),
                children: [
                  OnboardingFolioHeading(
                    holiday: widget.onboardingHoliday!,
                    title: _phase == _Phase.reading ? 'Reading your' : 'Let’s try',
                    accent: _phase == _Phase.reading ? 'booking.' : 'again.',
                    subtitle: _phase == _Phase.reading
                        ? 'Getting the details ready for you to check.'
                        : 'Your holiday is still here.',
                  ),
                  if (_phase == _Phase.reading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    Text(
                      _error ?? _result?.warning ?? 'No booking found. Try a clearer screenshot, or enter it yourself.',
                      style: TravaryText.body,
                    ),
                    const SizedBox(height: TravarySpace.lg),
                    if (_phase == _Phase.failed) FilledButton(onPressed: _read, child: const Text('Try again')),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(const SmartImportOutcome(addManually: true)),
                      child: const Text('Enter a booking myself'),
                    ),
                  ],
                ],
              ),
      );
    }
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
    final trip = widget.tripId == null ? null : store.plan(widget.tripId!);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.lg),
            children: [
              Text(
                _drafts.length == 1 ? 'We found 1 booking' : 'We found ${_drafts.length} bookings',
                style: TravaryText.headline,
              ),
              const SizedBox(height: TravarySpace.xs),
              Text('Tap one to check its details, or add them all.', style: TravaryText.bodySoft),
              if (_result?.warning != null) ...[
                const SizedBox(height: TravarySpace.sm),
                Text(_result!.warning!, style: TravaryText.small.copyWith(color: TravaryColors.coral)),
              ],
              const SizedBox(height: TravarySpace.lg),
              for (final (index, draft) in _drafts.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: TravarySpace.sm),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _saved.contains(index) || _selected.contains(index),
                        onChanged: _saved.contains(index)
                            ? null
                            : (on) => setState(() => on == true ? _selected.add(index) : _selected.remove(index)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            BookingCard(
                              text: cardTextForReview(draft.booking),
                              art: art[index],
                              size: CardSize.compact,
                              onTap: _saved.contains(index) ? null : () => _checkOne(index),
                            ),
                            if (_saved.contains(index))
                              Text('Added', style: TravaryText.small.copyWith(color: TravaryColors.teal))
                            else ...[
                              if (_elsewhere(draft.booking, trip, store) case (final asked, final elsewhere))
                                Text(
                                  outsideTripText(asked, elsewhere),
                                  key: ValueKey('outside-trip-$index'),
                                  textAlign: TextAlign.end,
                                  style: TravaryText.small,
                                ),
                              if (draft.uncertain.isNotEmpty)
                                Text(
                                  'Check ${draft.uncertain.length} detail${draft.uncertain.length == 1 ? '' : 's'}',
                                  style: TravaryText.small.copyWith(color: TravaryColors.coral),
                                ),
                            ],
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
                onPressed: _saving ? null : (toAdd == 0 ? _finish : _addSelected),
                child: Text(toAdd == 0 ? 'Done' : 'Add $toAdd booking${toAdd == 1 ? '' : 's'}'),
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
    final isImage = smartImportMimeType(filePath)?.startsWith('image/') ?? false;
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
                  boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4))],
                ),
                clipBehavior: Clip.antiAlias,
                child: isImage
                    ? Image.file(
                        File(filePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(width: 200, height: 200),
                      )
                    : const SizedBox(
                        width: 200,
                        height: 200,
                        child: Icon(Icons.picture_as_pdf_outlined, size: 64, color: TravaryColors.inkSoft),
                      ),
              ),
            ),
          ),
          const SizedBox(height: TravarySpace.xl),
          Text('Reading your booking…', style: TravaryText.title, textAlign: TextAlign.center),
          const SizedBox(height: TravarySpace.sm),
          Text('This usually takes a few seconds.', style: TravaryText.bodySoft, textAlign: TextAlign.center),
          const SizedBox(height: TravarySpace.lg),
          // Travi studies it in place of a spinner.
          const Center(child: TraviCameo(moment: TraviMoment.reading)),
        ],
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.title, required this.message, required this.onRetry});

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
              art: const TraviCameo(moment: TraviMoment.oops),
              title: title,
              message: message,
            ),
            if (onRetry != null) OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            const SizedBox(height: TravarySpace.sm),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(const SmartImportOutcome(addManually: true)),
              child: const Text('Add it myself'),
            ),
          ],
        ),
      ),
    );
  }
}
