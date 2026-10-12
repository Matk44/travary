import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../design/widgets/common.dart';
import '../../design/widgets/holiday_dates_sheet.dart';
import '../../design/widgets/travi_cameo.dart';
import '../../domain/domain.dart';
import '../../logic/destinations.dart';
import '../../logic/formatters.dart';
import '../../logic/price_text.dart';
import '../../logic/trip_plan.dart';
import '../../logic/travi_cameos.dart';
import '../../logic/trip_window.dart';
import '../../state/analytics.dart';
import '../../state/premium_store.dart';
import '../../state/travel_store.dart';
import '../sharing/join_trip_sheet.dart';
import 'place_picker_sheet.dart';
import 'trip_screen.dart';

/// "New trip": where to and when, then straight into the new trip. Trips
/// still form on their own from bookings; this is for starting one first.
/// Bookings on its dates join it automatically.
Future<void> startNewTrip(BuildContext context) async {
  final outcome = await _showSheet(context, const TripDetailsSheet());
  if (outcome == null || !context.mounted) return;
  switch (outcome) {
    case _Created(:final tripId):
      // Travi cheers the new holiday in.
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => TripScreen(tripId: tripId, celebrate: true)));
    case _OpenInstead(:final tripId):
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TripScreen(tripId: tripId)));
    case _JoinInstead():
      await startJoinTrip(context);
    case _Saved():
      break;
  }
}

/// Edits a trip's name and dates.
Future<void> editTripDetails(BuildContext context, TripPlan plan) =>
    _showSheet(context, TripDetailsSheet(editing: plan));

Future<_Outcome?> _showSheet(BuildContext context, TripDetailsSheet sheet) => showModalBottomSheet<_Outcome>(
  context: context,
  isScrollControlled: true,
  // The sheet draws its own handle: the built-in one would clip Travi,
  // who peeks over the top edge.
  showDragHandle: false,
  backgroundColor: TravaryColors.linen,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: sheet,
  ),
);

sealed class _Outcome {
  const _Outcome();
}

class _Created extends _Outcome {
  const _Created(this.tripId);

  final String tripId;
}

class _Saved extends _Outcome {
  const _Saved();
}

/// The new trip's dates overlap a trip already there: open that instead.
class _OpenInstead extends _Outcome {
  const _OpenInstead(this.tripId);

  final String tripId;
}

/// "Have an invite code?": join someone's trip instead.
class _JoinInstead extends _Outcome {
  const _JoinInstead();
}

/// A trip's name, destination and dates: a new trip, or [editing] an
/// existing one. New dates can't leave a booking out (the trip would only
/// stretch over it); dates overlapping another trip say so first. The destination is read from the name as it's typed
/// ("Japan holiday" is in Japan), with suggestions for a place half typed;
/// the traveller can change or remove it, and it's never required.
class TripDetailsSheet extends StatefulWidget {
  const TripDetailsSheet({super.key, this.editing});

  /// The trip being edited, or null for a new one.
  final TripPlan? editing;

  @override
  State<TripDetailsSheet> createState() => _TripDetailsSheetState();
}

class _TripDetailsSheetState extends State<TripDetailsSheet> {
  late final TextEditingController _title;
  LocalDate? _start;
  LocalDate? _end;

  /// Only dates the traveller chose are saved: an automatic trip keeps
  /// following its bookings until then.
  bool _datesChanged = false;

  /// Where the trip goes. [_detected] while it was read from the name (so a
  /// new name can replace or remove it); [_chosen] once the traveller picked
  /// or removed one, which the name no longer changes.
  TripDestination? _destination;
  bool _detected = false;
  bool _chosen = false;
  List<PlaceSuggestion> _suggestions = const [];
  String? _titleError;
  String? _datesError;
  bool _saving = false;

  TripPlan? get _editing => widget.editing;
  bool get _isEditing => _editing != null;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: _editing?.trip.title);
    _start = _editing?.start;
    _end = _editing?.end;
    _destination = _editing?.trip.destination;
  }

  void _titleChanged(String text) {
    setState(() {
      _titleError = null;
      _suggestions = [
        for (final suggestion in suggestPlaces(text))
          if (suggestion.place.destination != _destination) suggestion,
      ];
      if (_chosen) return;
      final found = detectPlace(text)?.destination;
      if (found != null) {
        _destination = found;
        _detected = true;
      } else if (_detected) {
        _destination = null;
        _detected = false;
      }
    });
  }

  void _useSuggestion(PlaceSuggestion suggestion) {
    _title.value = TextEditingValue(
      text: suggestion.completed,
      selection: TextSelection.collapsed(offset: suggestion.completed.length),
    );
    _choose(suggestion.place);
  }

  Future<void> _pickPlace() async {
    final place = await showPlacePicker(context);
    if (place == null || !mounted) return;
    if (_title.text.trim().isEmpty) _title.text = place.name;
    _choose(place);
  }

  void _choose(Place? place) => setState(() {
    _destination = place?.destination;
    _chosen = true;
    _detected = false;
    _suggestions = const [];
  });

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final today = context.read<TravelStore>().today;
    final picked = await showHolidayDates(
      context,
      today: today,
      start: _start,
      end: _end,
      // It opens on this month (or the trip's); a trip under way, or one
      // being tidied up afterwards, can still reach back a year.
      first: LocalDate.min(_start ?? today, today).addDays(-365),
      title: 'When are you away?',
      confirm: 'Done',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _start = picked.start;
      _end = picked.end;
      _datesChanged = true;
      _datesError = null;
    });
    if (_leftOut.isNotEmpty) track('trip_dates_left_out', {'bookings': _leftOut.length});
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    setState(() {
      _titleError = title.isEmpty ? 'Where are you going? e.g. "Paris"' : null;
      _datesError = !_isEditing && _start == null ? 'Choose your dates' : null;
    });
    if (_titleError != null || _datesError != null || _leftOut.isNotEmpty) return;
    setState(() => _saving = true);
    final store = context.read<TravelStore>();
    final editing = _editing;
    if (editing == null) {
      final overlaps = overlappingTrip(_start!, _end!, store.plans) != null;
      final trip = await store.createTrip(title, start: _start, end: _end, destination: _destination);
      track('trip_created', {
        'days': _start!.daysUntil(_end!) + 1,
        'destination': _destination?.countryCode,
        'overlaps': overlaps,
      });
      if (mounted) Navigator.of(context).pop(_Created(trip.id));
      return;
    }
    await store.updateTrip(
      editing.trip.copyWith(
        title: title,
        plannedStart: _datesChanged ? _start : null,
        plannedEnd: _datesChanged ? _end : null,
        destination: _destination,
        clearDestination: _destination == null,
      ),
    );
    if (mounted) Navigator.of(context).pop(const _Saved());
  }

  /// Bookings the chosen dates would leave out: they can't be saved.
  List<Booking> get _leftOut {
    final editing = _editing;
    if (editing == null || !_datesChanged || _start == null) return const [];
    return bookingsLeftOut(editing.bookings, _start!, _end!);
  }

  @override
  Widget build(BuildContext context) {
    final start = _start;
    final end = _end;
    final days = start == null ? 0 : start.daysUntil(end!) + 1;
    final booked = _editing == null ? null : bookedSpan(_editing!.bookings);
    final leftOut = _leftOut;
    final stretched =
        leftOut.isEmpty && start != null && _editing != null && leavesOutBookings(_editing!.bookings, start, end!);
    // Only for dates that can be saved: a left-out booking comes first.
    final overlap = start == null || leftOut.isNotEmpty
        ? null
        : overlappingTrip(start, end!, context.watch<TravelStore>().plans, except: _editing?.id);
    final premium = context.watch<PremiumStore>();
    final pass = _editing == null || premium.hasPlus ? null : premium.policy.tripPassFor(_editing!);
    final passEnds = leftOut.isEmpty && _datesChanged && pass != null && start != null
        ? tripPassEndsText(pass, start, end!)
        : null;

    final form = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            Text(_isEditing ? 'Edit trip' : 'New trip', style: TravaryText.headline),
            if (!_isEditing) ...[
              const SizedBox(height: TravarySpace.xs),
              Text('Anything you book on these dates joins it automatically.', style: TravaryText.bodySoft),
            ],
            const SizedBox(height: TravarySpace.lg),
            TextField(
              controller: _title,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              style: TravaryText.title,
              decoration: InputDecoration(
                labelText: 'Where to?',
                hintText: 'Paris, Disney World, Grandma\'s',
                hintStyle: TravaryText.bodySoft,
                errorText: _titleError,
              ),
              onChanged: _titleChanged,
            ),
            for (final suggestion in _suggestions)
              InkWell(
                key: ValueKey('place-suggestion-${suggestion.place.label}'),
                onTap: () => _useSuggestion(suggestion),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TravarySpace.md, vertical: TravarySpace.sm + 2),
                  child: Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 18, color: TravaryColors.inkSoft),
                      const SizedBox(width: TravarySpace.sm),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: suggestion.name,
                            children: [
                              if (suggestion.where case final where?)
                                TextSpan(text: '  $where', style: TravaryText.bodySoft),
                            ],
                          ),
                          style: TravaryText.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            _DestinationRow(destination: _destination, onChange: _pickPlace, onRemove: () => _choose(null)),
            const SizedBox(height: TravarySpace.sm),
            InkWell(
              key: const ValueKey('trip-dates'),
              onTap: _pickDates,
              borderRadius: BorderRadius.circular(TravaryRadius.small),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'When?',
                  errorText: _datesError ?? (leftOut.isEmpty ? null : leftOutText(leftOut)),
                  errorMaxLines: 4,
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                ),
                child: Text(
                  start == null
                      ? 'Choose dates'
                      : '${formatDateRange(start, end!)} · $days ${days == 1 ? 'day' : 'days'}',
                  style: start == null ? TravaryText.bodySoft : TravaryText.body,
                ),
              ),
            ),
            if (stretched) ...[
              const SizedBox(height: TravarySpace.sm),
              Text(
                'Your bookings run ${formatDateRange(booked!.start, booked.end)}, so the trip covers those days too.',
                style: TravaryText.small,
              ),
            ],
            if (overlap != null) ...[
              const SizedBox(height: TravarySpace.sm),
              Text(overlapText(overlap), key: const ValueKey('trip-overlap'), style: TravaryText.small),
              if (!_isEditing)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const ValueKey('open-overlapping-trip'),
                    onPressed: () {
                      track('trip_overlap_opened');
                      Navigator.of(context).pop(_OpenInstead(overlap.id));
                    },
                    child: Text('Open ${overlap.trip.title} instead'),
                  ),
                ),
            ],
            if (passEnds != null) ...[
              const SizedBox(height: TravarySpace.sm),
              Text(passEnds, key: const ValueKey('trip-pass-ends'), style: TravaryText.small),
            ],
            const SizedBox(height: TravarySpace.xl),
            FilledButton(
              key: const ValueKey('save-trip'),
              onPressed: _saving || leftOut.isNotEmpty ? null : _save,
              child: Text(
                _isEditing
                    ? 'Save'
                    : overlap == null
                    ? 'Create trip'
                    : 'Create anyway',
              ),
            ),
            if (!_isEditing) ...[
              const SizedBox(height: TravarySpace.sm),
              TextButton(
                onPressed: () => Navigator.of(context).pop(const _JoinInstead()),
                child: const Text('Have an invite code? Join a trip'),
              ),
            ],
          ],
        ),
      ),
    );
    if (_isEditing) return form;
    // A new trip: Travi pops up over the sheet's top edge and waves.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        form,
        Positioned(
          right: TraviCameoLayout.sheetRight,
          top: -TraviCameoLayout.peekSize,
          width: TraviCameoLayout.peekSize,
          height: TraviCameoLayout.peekSize,
          child: const TraviPopUp(key: ValueKey('new-trip-travi'), peek: TraviPeek.wave),
        ),
      ],
    );
  }
}

/// The trip's destination under its name, to change or remove; or a quiet
/// way to add one.
class _DestinationRow extends StatelessWidget {
  const _DestinationRow({required this.destination, required this.onChange, required this.onRemove});

  final TripDestination? destination;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final place = destination;
    if (place == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onChange,
          icon: const Icon(Icons.add_location_alt_outlined, size: 18),
          label: const Text('Add a destination'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: TravarySpace.md, top: TravarySpace.xs),
      child: Row(
        children: [
          const Icon(Icons.place_rounded, size: 18, color: TravaryColors.coral),
          const SizedBox(width: TravarySpace.sm),
          Expanded(
            child: Text(place.label, key: const ValueKey('trip-destination'), style: TravaryText.label),
          ),
          TextButton(onPressed: onChange, child: const Text('Change')),
          IconButton(
            tooltip: 'Not this place',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
