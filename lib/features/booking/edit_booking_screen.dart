import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../design/widgets/common.dart';
import '../../domain/domain.dart';
import '../../logic/formatters.dart';
import '../../state/travel_store.dart';
import 'booking_actions.dart';

/// Add or edit a booking. Only the title and date are required; everything
/// else is optional so adding something takes seconds.
class EditBookingScreen extends StatefulWidget {
  const EditBookingScreen({
    super.key,
    required this.kind,
    this.existing,
    this.initialDate,
    this.tripId,
  });

  final BookingKind kind;
  final Booking? existing;
  final LocalDate? initialDate;

  /// Put the booking in this trip. Null lets the app choose.
  final String? tripId;

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
  late String _tripId;
  late List<Attachment> _attachments;
  late final TravelStore _store;

  /// Files copied in during this edit, removed again if it's cancelled.
  final _addedAttachments = <Attachment>[];
  bool _saved = false;
  bool _saving = false;
  String? _titleError;

  KindSpec get _spec => widget.kind.spec;
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _store = context.read<TravelStore>();
    _title = TextEditingController(text: existing?.title);
    _location = TextEditingController(text: existing?.location);
    _reference = TextEditingController(text: existing?.reference);
    _notes = TextEditingController(text: existing?.notes);
    _details = {
      for (final field in _spec.fields)
        field.key: TextEditingController(text: existing?.details[field.key]),
    };
    _startDate = existing?.startDate ?? widget.initialDate ?? _store.today;
    _startTime = existing?.startTime;
    _endDate = existing?.endDate ??
        (existing == null && _spec.endUsuallyLaterDay ? _startDate.addDays(1) : null);
    _endTime = existing?.endTime;
    _tripId = existing?.tripId ?? widget.tripId ?? '';
    _attachments = [...?existing?.attachments];
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

  // ------------------------------------------------------------- pickers

  Future<LocalDate?> _pickDate(LocalDate initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.toDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
    if (choice != null) setState(() => _tripId = choice);
  }

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
    if (endDate == null &&
        _endTime != null &&
        _startTime != null &&
        _endTime!.compareTo(_startTime!) < 0) {
      endDate = _startDate.addDays(1);
    }
    if (endDate == _startDate) endDate = null;

    final store = _store;
    final now = DateTime.now();
    String? clean(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final booking = Booking(
      id: widget.existing?.id ?? store.repository.newId(),
      tripId: _tripId,
      kind: widget.kind,
      title: title,
      startDate: _startDate,
      startTime: _startTime,
      endDate: endDate,
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
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _saving = true);
    final result = await store.saveBooking(booking, previous: widget.existing);
    _saved = true;
    if (mounted) Navigator.of(context).pop(result);
  }

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final tripName = _tripId.isEmpty ? 'Automatic' : store.plan(_tripId)?.trip.title ?? 'Automatic';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit booking' : _spec.label),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text('Save', style: TravaryText.label),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, TravarySpace.sm, TravarySpace.gutter, TravarySpace.xxl),
        children: [
          TextField(
            controller: _title,
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.words,
            style: TravaryText.title,
            decoration: InputDecoration(
              labelText: _spec.titleLabel,
              hintText: _spec.titleHint,
              errorText: _titleError,
            ),
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
          ),
          const SizedBox(height: TravarySpace.lg),
          _DateTimeRow(
            label: _spec.startLabel,
            date: formatDayShort(_startDate),
            time: _startTime == null ? null : formatClock(_startTime!),
            onDate: () async {
              final picked = await _pickDate(_startDate);
              if (picked == null) return;
              setState(() {
                final shift = _startDate.daysUntil(picked);
                _startDate = picked;
                // Keep the length of a stay when its start moves.
                if (_endDate != null) _endDate = _endDate!.addDays(shift);
              });
            },
            onTime: () async {
              final picked = await _pickTime(_startTime);
              if (picked != null) setState(() => _startTime = picked);
            },
            onClearTime: _startTime == null ? null : () => setState(() => _startTime = null),
          ),
          if (_spec.hasEnd) ...[
            const SizedBox(height: TravarySpace.md),
            _DateTimeRow(
              label: _spec.endLabel!,
              date: _endDate == null ? 'Same day' : formatDayShort(_endDate!),
              time: _endTime == null ? null : formatClock(_endTime!),
              onDate: () async {
                final picked = await _pickDate(_endDate ?? _startDate);
                if (picked != null) setState(() => _endDate = picked);
              },
              onTime: () async {
                final picked = await _pickTime(_endTime);
                if (picked != null) setState(() => _endTime = picked);
              },
              onClearTime: _endTime == null ? null : () => setState(() => _endTime = null),
            ),
          ],
          const SizedBox(height: TravarySpace.lg),
          TextField(
            controller: _location,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: '${_spec.locationLabel} (optional)'),
          ),
          for (final field in _spec.fields) ...[
            const SizedBox(height: TravarySpace.md),
            TextField(
              controller: _details[field.key],
              keyboardType: field.numeric ? TextInputType.number : TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: '${field.label} (optional)', hintText: field.hint),
            ),
          ],
          const SizedBox(height: TravarySpace.md),
          TextField(
            controller: _reference,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Booking reference (optional)'),
          ),
          const SizedBox(height: TravarySpace.md),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          const SectionLabel('Tickets & documents', inset: false),
          for (final attachment in _attachments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(attachment.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined),
              title: Text(attachment.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() => _attachments.remove(attachment)),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _addAttachment,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Add ticket or document'),
          ),
          const SectionLabel('Trip', inset: false),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.luggage_outlined),
            title: Text(tripName),
            subtitle: _tripId.isEmpty ? const Text('Joins the trip on the same dates, or starts a new one') : null,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _chooseTrip,
          ),
          const SizedBox(height: TravarySpace.xl),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isEditing ? 'Save changes' : 'Add to my trip'),
          ),
        ],
      ),
    );
  }
}

/// "Check-in   [Wed 14 Oct]  [4:00pm ×]"
class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.label,
    required this.date,
    required this.time,
    required this.onDate,
    required this.onTime,
    this.onClearTime,
  });

  final String label;
  final String date;
  final String? time;
  final VoidCallback onDate;
  final VoidCallback onTime;
  final VoidCallback? onClearTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: TravaryText.label)),
        ActionChip(
          avatar: const Icon(Icons.calendar_today_rounded, size: 16),
          label: Text(date),
          onPressed: onDate,
        ),
        const SizedBox(width: TravarySpace.sm),
        if (time == null)
          ActionChip(
            avatar: const Icon(Icons.schedule_rounded, size: 16),
            label: const Text('Add time'),
            onPressed: onTime,
          )
        else
          InputChip(
            avatar: const Icon(Icons.schedule_rounded, size: 16),
            label: Text(time!),
            onPressed: onTime,
            onDeleted: onClearTime,
          ),
      ],
    );
  }
}
