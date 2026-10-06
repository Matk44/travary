import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../design/art/art_slots.dart';
import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/ledger.dart';
import '../../design/widgets/paper_form.dart';
import '../../domain/domain.dart';
import '../../logic/booking_form_text.dart';
import '../../logic/flight_fill.dart';
import '../../logic/formatters.dart';
import '../../logic/trip_assignment.dart';
import '../../logic/trip_plan.dart';
import '../../logic/trip_window.dart';
import '../../state/analytics.dart';
import '../../state/travel_store.dart';
import 'booking_actions.dart';
import 'flight_finder.dart';

/// Add or edit a booking, on a paper ticket (C2): the name and place on
/// ruled lines, dates printed in boxes, the rest folded under "More
/// details", the ticket files below, and one notched button. Only the
/// title and date are required, so adding something takes seconds.
///
/// A new flight starts on the departures board ([FlightFinder]) when live
/// flight data is available: its number and date fill in the rest.
///
/// The booking goes where [placeBooking] says, shown under the title. In a
/// trip with planned dates the date pickers only offer its days (and a
/// travel day either side); tapping the trip line chooses another trip or
/// lets the dates decide.
class EditBookingScreen extends StatefulWidget {
  const EditBookingScreen({
    super.key,
    required this.kind,
    this.existing,
    this.draft,
    this.initialDate,
    this.initialEndDate,
    this.tripId,
    this.sourceFilePath,
    this.sourceFileName,
  });

  final BookingKind kind;
  final Booking? existing;

  /// A booking read by Smart Import: pre-fills a new booking and highlights
  /// what the traveller should check.
  final BookingDraft? draft;
  final LocalDate? initialDate;

  /// Where a stay should end (adding one for a gap in the plan).
  final LocalDate? initialEndDate;

  /// Put the booking in this trip. Null lets the app choose.
  final String? tripId;

  /// The file a draft was read from, attached as the booking's ticket.
  final String? sourceFilePath;
  final String? sourceFileName;

  @override
  State<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _reference;
  late final TextEditingController _notes;
  late final Map<String, TextEditingController> _details;

  late LocalDate _startDate;
  ClockTime? _startTime;
  LocalDate? _endDate;
  ClockTime? _endTime;

  /// The trip the booking is in, was added from or was imported into, or
  /// empty to go by its dates. It keeps that trip while its dates fit.
  late String _tripId;

  /// The traveller picked the trip on this form ("Choose automatically"
  /// included), so it goes there whatever the dates.
  bool _tripChosen = false;
  late List<Attachment> _attachments;
  late final TravelStore _store;

  /// Files copied in during this edit, removed again if it's cancelled.
  final _addedAttachments = <Attachment>[];
  bool _saved = false;
  bool _saving = false;
  String? _titleError;

  /// On the departures board, before the ticket (a new flight).
  late bool _finding;

  /// The ticket was filled in from the airline's schedule.
  bool _fromSchedule = false;

  /// "More details" unfolded.
  late bool _more;

  KindSpec get _spec => widget.kind.spec;
  bool get _isEditing => widget.existing != null;
  bool get _isFlight => widget.kind == BookingKind.flight;

  /// A flight is found by its number and date when the service is there.
  bool get _findsFlights => _isFlight && _store.flightStatus != null;

  Set<String> get _highlight => widget.draft?.highlight ?? const {};

  /// The detail fields under "More details": everything but a flight's
  /// number, which sits with its name.
  List<DetailField> get _moreFields => [
    for (final field in _spec.fields)
      if (!(_isFlight && field.key == DetailKeys.flightNumber)) field,
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing ?? widget.draft?.booking;
    _store = context.read<TravelStore>();
    _title = TextEditingController(text: existing?.title);
    _location = TextEditingController(text: existing?.location);
    _reference = TextEditingController(text: existing?.reference);
    _notes = TextEditingController(text: existing?.notes);
    _details = {for (final field in _spec.fields) field.key: TextEditingController(text: existing?.details[field.key])};
    _startDate = existing?.startDate ?? widget.initialDate ?? _store.today;
    _startTime = existing?.startTime;
    _endDate =
        existing?.endDate ??
        widget.initialEndDate ??
        (existing == null && _spec.endUsuallyLaterDay ? _startDate.addDays(1) : null);
    _endTime = existing?.endTime;
    _tripId = widget.existing?.tripId ?? widget.tripId ?? '';
    _attachments = [...?widget.existing?.attachments];
    _finding = _findsFlights && !_isEditing && widget.draft == null;
    _more =
        [_reference, _notes, for (final field in _moreFields) _details[field.key]!].any((c) => c.text.isNotEmpty) ||
        _highlight.any((field) => field == 'reference' || field == 'notes' || field.startsWith('details.'));
    if (widget.sourceFilePath != null) _attachSource();
  }

  Future<void> _attachSource() async {
    final attachment = await _store.attachments?.import(widget.sourceFilePath!, name: widget.sourceFileName);
    if (attachment == null) return;
    if (!mounted) {
      await _store.attachments?.delete(attachment);
      return;
    }
    setState(() {
      _attachments.add(attachment);
      _addedAttachments.add(attachment);
    });
  }

  @override
  void dispose() {
    if (!_saved) {
      for (final attachment in _addedAttachments) {
        _store.attachments?.delete(attachment);
      }
    }
    for (final controller in [_title, _location, _reference, _notes, ..._details.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Editing, the dates differ from the saved booking's. Only new dates
  /// can move a booking to another trip.
  bool get _datesChanged {
    final existing = widget.existing;
    return existing == null || existing.startDate != _startDate || existing.lastDate != (_endDate ?? _startDate);
  }

  /// Where the booking goes with the form as it stands (ending on [end]).
  TripPlacement _placement(TravelStore store, {LocalDate? end}) => placeBooking(
    start: _startDate,
    end: end ?? _endDate ?? _startDate,
    plans: store.plans,
    tripId: _tripId,
    chosen: _tripChosen,
    editing: widget.existing?.id,
    datesChanged: _datesChanged,
    // Smart Import's dates come off the ticket, so a trip that formed on
    // its own keeps what's within a few weeks of it.
    looseMarginDays: widget.draft == null ? tripMarginDays : sameSourceMarginDays,
  );

  /// The trip as the traveller sees it (with this booking, if it's in it),
  /// for the line under the title.
  TripPlan? _shown(TravelStore store, TripPlacement placement) {
    final plan = placement.plan;
    return plan == null ? null : store.plan(plan.id) ?? plan;
  }

  /// The days the pickers offer: the trip's, while the booking stays in a
  /// trip with planned dates. Null: any day.
  DateWindow? _window(TripPlacement placement) {
    final plan = placement.plan;
    return plan == null || plan.id != _tripId ? null : bookingWindowFor(plan);
  }

  // ------------------------------------------------------------- pickers

  /// A date, inside the trip's days when it keeps to them, and not before
  /// [notBefore] (an end date).
  Future<LocalDate?> _pickDate(LocalDate initial, {LocalDate? notBefore}) async {
    final placement = _placement(_store);
    final window = _window(placement);
    final last = window?.last ?? LocalDate(2100, 12, 31);
    var first = window?.first ?? LocalDate(2000, 1, 1);
    if (notBefore != null && notBefore.isAfter(first)) first = notBefore;
    if (first.isAfter(last)) first = last;
    final range = DateWindow(first, last);
    final picked = await showDatePicker(
      context: context,
      initialDate: range.clamp(initial).toDateTime(),
      firstDate: first.toDateTime(),
      lastDate: last.toDateTime(),
      helpText: window == null ? null : formTripLine(_shown(_store, placement)),
    );
    return picked == null ? null : LocalDate.fromDateTime(picked);
  }

  Future<ClockTime?> _pickTime(ClockTime? initial) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial?.hour ?? 12, minute: initial?.minute ?? 0),
    );
    return picked == null ? null : ClockTime(picked.hour, picked.minute);
  }

  Future<void> _addAttachment() async {
    final attachment = await pickAttachment(context);
    if (attachment == null || !mounted) return;
    setState(() {
      _attachments.add(attachment);
      _addedAttachments.add(attachment);
    });
  }

  Future<void> _chooseTrip() async {
    final store = _store;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: TravaryColors.linen,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Choose automatically'),
              subtitle: const Text('By the dates you entered'),
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final plan in store.plans.reversed)
              ListTile(
                leading: const Icon(Icons.luggage_outlined),
                title: Text(plan.trip.title),
                subtitle: plan.hasDates ? Text(formatDateRange(plan.start!, plan.end!)) : null,
                selected: plan.id == _tripId,
                onTap: () => Navigator.pop(context, plan.id),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final plan = store.plan(choice);
    final editing = widget.existing?.id;
    final window = plan == null ? null : bookingWindowFor(editing == null ? plan : withoutBooking(plan, editing));
    setState(() {
      _tripId = choice;
      _tripChosen = true;
      // Dates outside the chosen trip move to its first day (today during
      // it), keeping the booking's length where they can.
      if (plan != null && window != null) {
        final moved = moveInto(
          window,
          _startDate,
          _endDate,
          preferredStart: plan.contains(store.today) ? store.today : plan.start!,
        );
        _startDate = moved.start;
        _endDate = moved.end;
      }
    });
  }

  void _changeStartDate(LocalDate picked) {
    final window = _window(_placement(_store));
    setState(() {
      final shift = _startDate.daysUntil(picked);
      _startDate = picked;
      // Keep the length of a stay when its start moves, inside the trip.
      if (_endDate != null) {
        final end = _endDate!.addDays(shift);
        _endDate = window == null ? end : window.clamp(end);
      }
    });
  }

  void _useFlight(FlightFill fill) => setState(() {
    _title.text = fill.title;
    _titleError = null;
    _startDate = fill.startDate;
    _startTime = fill.startTime;
    _endDate = fill.endDate;
    _endTime = fill.endTime;
    if (fill.location != null) _location.text = fill.location!;
    _details[DetailKeys.flightNumber]!.text = fill.flightNumber;
    _finding = false;
    _fromSchedule = true;
  });

  // ---------------------------------------------------------------- save

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Give it a name, e.g. "${_spec.titleHint}"');
      return;
    }

    var endDate = _endDate;
    if (endDate != null && endDate.isBefore(_startDate)) {
      _showMessage('${_spec.endLabel} can\'t be before ${_spec.startLabel.toLowerCase()}.');
      return;
    }
    // "Departs 6:40pm, lands 7:10am" means landing the next morning.
    if (endDate == null && _endTime != null && _startTime != null && _endTime!.compareTo(_startTime!) < 0) {
      endDate = _startDate.addDays(1);
    }
    if (endDate == _startDate) endDate = null;

    final store = _store;
    final placement = _placement(store, end: endDate ?? _startDate);
    var tripId = placement.plan?.id ?? '';
    if (placement.stretches) {
      final answer = await _askToStretch(placement, endDate ?? _startDate);
      track('booking_stretch_asked', {
        'kind': widget.kind.name,
        'choice': answer == null ? 'back' : (answer == placement.plan!.id ? 'stretch' : 'elsewhere'),
      });
      if (answer == null || !mounted) return;
      tripId = answer;
    }
    // Taken out of the trip it was in, with nowhere its dates fit: a trip
    // of its own, not back into the one it left.
    final newTrip = tripId.isEmpty && _tripId.isNotEmpty;
    setState(() => _saving = true);
    final result = await store.saveBooking(
      _booking(id: widget.existing?.id ?? store.repository.newId(), endDate: endDate, tripId: tripId),
      previous: widget.existing,
      newTrip: newTrip,
    );
    _saved = true;
    if (mounted) Navigator.of(context).pop(result);
  }

  /// Before a booking stretches a trip that formed from its bookings well
  /// past them: into it anyway, or where its dates put it. Returns the trip
  /// id ('' for a new trip), or null to keep editing.
  Future<String?> _askToStretch(TripPlacement placement, LocalDate end) {
    final question = stretchQuestion(
      placement.plan!,
      _startDate,
      end,
      alternative: placement.alternative,
      editing: _isEditing,
    );
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('stretch-trip'),
        title: Text(question.title),
        content: Text(question.message),
        actions: [
          TextButton(
            key: const ValueKey('stretch-other'),
            onPressed: () => Navigator.pop(context, placement.alternative?.id ?? ''),
            child: Text(question.other),
          ),
          TextButton(
            key: const ValueKey('stretch-keep'),
            onPressed: () => Navigator.pop(context, placement.plan!.id),
            child: Text(question.keep),
          ),
        ],
      ),
    );
  }

  /// The booking as the form stands, going into [tripId].
  Booking _booking({required String id, LocalDate? endDate, required String tripId}) {
    final now = DateTime.now();
    String? clean(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    return Booking(
      id: id,
      tripId: tripId,
      kind: widget.kind,
      title: _title.text.trim(),
      startDate: _startDate,
      startTime: _startTime,
      endDate: endDate ?? _endDate,
      endTime: _endTime,
      location: clean(_location),
      reference: clean(_reference),
      notes: clean(_notes),
      details: {
        for (final entry in _details.entries)
          if (entry.value.text.trim().isNotEmpty) entry.key: entry.value.text.trim(),
      },
      attachments: _attachments,
      artKey: widget.existing?.artKey,
      artSubject: (widget.existing ?? widget.draft?.booking)?.artSubject,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final plan = _shown(store, _placement(store));
    final chromePlan = plan ?? store.focus.plan;
    return TravaryChrome(
      colors: TripColors.of(store.paletteFor(chromePlan)),
      slots: store.chromeArtFor(chromePlan),
      child: Builder(builder: (context) => _screen(context, store, plan)),
    );
  }

  Widget _screen(BuildContext context, TravelStore store, TripPlan? plan) {
    final colors = TravaryChrome.of(context).colors;
    final text = bookingFormText(widget.kind, editing: _isEditing);
    final existing = widget.existing;
    final tripLine = formTripLine(plan, moves: existing != null && plan?.id != existing.tripId);
    return LinenBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _bar(
          AppBar(
            backgroundColor: Colors.transparent,
            // Dark clock and battery on the light linen.
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            centerTitle: true,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_finding ? 'Find your flight' : text.title, style: TravaryText.formTitle),
                InkWell(
                  key: const ValueKey('form-trip'),
                  onTap: _chooseTrip,
                  borderRadius: BorderRadius.circular(TravaryRadius.small),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: TravarySpace.sm, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(tripLine, style: TravaryText.small, overflow: TextOverflow.ellipsis),
                        ),
                        const Icon(Icons.expand_more_rounded, size: 16, color: TravaryColors.inkSoft),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              if (!_finding)
                TextButton(
                  onPressed: _saving ? null : _save,
                  style: TextButton.styleFrom(foregroundColor: colors.ink),
                  child: Text('Save', style: TravaryText.label.copyWith(color: colors.ink)),
                ),
            ],
          ),
        ),
        body: _finding
            ? ListView(
                padding: const EdgeInsets.fromLTRB(
                  TravarySpace.gutter,
                  TravarySpace.md,
                  TravarySpace.gutter,
                  TravarySpace.xxl,
                ),
                children: [
                  FlightFinder(
                    service: store.flightStatus!,
                    number: _details[DetailKeys.flightNumber]!,
                    date: _startDate,
                    onPickDate: () async {
                      final picked = await _pickDate(_startDate);
                      if (picked != null) _changeStartDate(picked);
                    },
                    onUse: _useFlight,
                    onManual: () => setState(() => _finding = false),
                  ),
                ],
              )
            : _ticket(context, store, text, plan),
      ),
    );
  }

  Widget _ticket(BuildContext context, TravelStore store, BookingFormText text, TripPlan? plan) {
    final colors = TravaryChrome.of(context).colors;
    final span = bookingSpanLabel(widget.kind, _startDate, _endDate);
    final preview = _booking(id: widget.existing?.id ?? 'draft', tripId: plan?.id ?? '');
    return ListView(
      padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, TravarySpace.md, TravarySpace.gutter, TravarySpace.xxl),
      children: [
        if (widget.draft != null)
          const _Banner(
            text:
                'Filled in by Smart Import. Please check the outlined details, especially dates and times, then save.',
          ),
        if (_fromSchedule)
          _Banner(
            icon: Icons.check_circle_rounded,
            iconColor: TravaryColors.moss,
            text: 'Filled in from the airline\'s schedule. Check it matches your ticket.',
            action: _findsFlights
                ? TextButton(
                    onPressed: () => setState(() => _finding = true),
                    style: TextButton.styleFrom(foregroundColor: colors.ink),
                    child: const Text('Find another'),
                  )
                : null,
          ),
        FormTicket(
          heading: text.heading,
          art: _title.text.trim().isEmpty ? null : store.artFor(preview),
          children: [
            PaperTextField(
              key: const ValueKey('field-title'),
              label: _spec.titleLabel,
              controller: _title,
              hint: _spec.titleHint,
              autofocus: !_isEditing && widget.draft == null && !_fromSchedule,
              textCapitalization: TextCapitalization.words,
              check: _highlight.contains('title'),
              errorText: _titleError,
              onChanged: (_) => setState(() => _titleError = null),
            ),
            const SizedBox(height: TravarySpace.lg),
            PaperTextField(
              key: const ValueKey('field-location'),
              label: _spec.locationLabel,
              controller: _location,
              textCapitalization: TextCapitalization.words,
              check: _highlight.contains('location'),
            ),
            if (_isFlight) ...[
              const SizedBox(height: TravarySpace.lg),
              PaperTextField(
                key: const ValueKey('field-flightNumber'),
                label: 'Flight number',
                controller: _details[DetailKeys.flightNumber]!,
                hint: 'BA 283',
                textCapitalization: TextCapitalization.characters,
                check: _highlight.contains('details.${DetailKeys.flightNumber}'),
              ),
            ],
            const SizedBox(height: TravarySpace.xl),
            _dates(),
            if (span != null) ...[const SizedBox(height: TravarySpace.md), SpanLabel(span)],
            const SizedBox(height: TravarySpace.lg),
            const Perforation(),
            InkWell(
              key: const ValueKey('more-details'),
              onTap: () => setState(() => _more = !_more),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: TravarySpace.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('More details', style: TravaryText.label.copyWith(color: colors.ink, fontSize: 16)),
                    ),
                    Icon(_more ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: colors.ink),
                  ],
                ),
              ),
            ),
            if (_more) ...[
              for (final field in _moreFields) ...[
                PaperTextField(
                  key: ValueKey('field-${field.key}'),
                  label: field.label,
                  controller: _details[field.key]!,
                  hint: field.hint,
                  small: true,
                  keyboardType: field.numeric ? TextInputType.number : TextInputType.text,
                  check: _highlight.contains('details.${field.key}'),
                ),
                const SizedBox(height: TravarySpace.lg),
              ],
              PaperTextField(
                key: const ValueKey('field-reference'),
                label: 'Booking reference',
                controller: _reference,
                small: true,
                textCapitalization: TextCapitalization.characters,
                check: _highlight.contains('reference'),
              ),
              const SizedBox(height: TravarySpace.lg),
              PaperTextField(
                key: const ValueKey('field-notes'),
                label: 'Notes',
                controller: _notes,
                small: true,
                minLines: 2,
                maxLines: 6,
                check: _highlight.contains('notes'),
              ),
              const SizedBox(height: TravarySpace.sm),
            ],
          ],
        ),
        const SizedBox(height: TravarySpace.lg),
        PaperPanel(
          child: Column(
            children: [
              for (final attachment in _attachments) ...[
                PaperRow(
                  title: attachment.name,
                  titleStyle: TravaryText.label,
                  leading: Icon(
                    attachment.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                    color: colors.ink,
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _attachments.remove(attachment)),
                  ),
                ),
                const PaperDivider(),
              ],
              PaperRow(
                key: const ValueKey('attach-ticket'),
                title: _attachments.isEmpty ? 'Attach your ticket' : 'Attach another',
                subtitle: 'A photo or PDF, ready even offline',
                titleStyle: TravaryText.label.copyWith(fontSize: 16),
                leading: const RowIcon(IconSlot.attach),
                onTap: _addAttachment,
              ),
            ],
          ),
        ),
        const SizedBox(height: TravarySpace.xl),
        TicketButton(key: const ValueKey('save-booking'), label: text.button, busy: _saving, onPressed: _save),
      ],
    );
  }

  /// The ticket's dates: start and end side by side, printed in boxes.
  Widget _dates() {
    final start = TicketDateBox(
      key: const ValueKey('date-start'),
      label: _spec.startLabel,
      date: formatTicketDate(_startDate),
      time: _startTime == null ? null : formatClock(_startTime!),
      checkDate: _highlight.contains('startDate'),
      checkTime: _highlight.contains('startTime'),
      onDate: () async {
        final picked = await _pickDate(_startDate);
        if (picked != null) _changeStartDate(picked);
      },
      onTime: () async {
        final picked = await _pickTime(_startTime);
        if (picked != null) setState(() => _startTime = picked);
      },
      onClearTime: () => setState(() => _startTime = null),
    );
    if (!_spec.hasEnd) return start;
    final end = TicketDateBox(
      key: const ValueKey('date-end'),
      label: _spec.endLabel!,
      date: _endDate == null ? 'SAME DAY' : formatTicketDate(_endDate!),
      time: _endTime == null ? null : formatClock(_endTime!),
      checkDate: _highlight.contains('endDate') && _endDate != null,
      checkTime: _highlight.contains('endTime') && _endTime != null,
      onDate: () async {
        final picked = await _pickDate(_endDate ?? _startDate, notBefore: _startDate);
        if (picked != null) setState(() => _endDate = picked);
      },
      onTime: () async {
        final picked = await _pickTime(_endTime);
        if (picked != null) setState(() => _endTime = picked);
      },
      onClearTime: () => setState(() => _endTime = null),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: start),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: TravarySpace.md),
            color: TravaryColors.line,
          ),
          Expanded(child: end),
        ],
      ),
    );
  }
}

/// A note above the ticket: Smart Import's "please check", or "filled in
/// from the airline's schedule".
class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    this.icon = Icons.auto_awesome_rounded,
    this.iconColor = TravaryColors.coral,
    this.action,
  });

  final String text;
  final IconData icon;
  final Color iconColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TravarySpace.lg),
      child: PaperPanel(
        padding: const EdgeInsets.fromLTRB(TravarySpace.lg, TravarySpace.md, TravarySpace.sm, TravarySpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: TravarySpace.sm),
            // The action goes under the words, so large text never squeezes them.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: TravaryText.bodySoft.copyWith(color: TravaryColors.ink)),
                  ?action,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The top bar with its text kept to [BarText.maxScale].
PreferredSizeWidget _bar(AppBar bar) => PreferredSize(
  preferredSize: bar.preferredSize,
  child: BarText(child: bar),
);
