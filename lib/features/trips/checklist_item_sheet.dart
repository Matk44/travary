import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../domain/domain.dart';
import '../../logic/checklist.dart';
import '../../logic/formatters.dart';
import '../../logic/packing.dart';
import '../../logic/trip_plan.dart';
import '../../state/travel_store.dart';

/// Adds something to do to [plan]'s checklist, or edits [editing]: its
/// words, an optional "by" date and, when editing, removing it (with an
/// undo). Ideas fill the words in with one tap. On the packing [list]
/// there's no date, and the keyboard's return adds one thing after
/// another without closing.
Future<void> showChecklistItemSheet(
  BuildContext context,
  TripPlan plan, {
  ChecklistItem? editing,
  TripList list = TripList.checklist,
}) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: TravaryColors.linen,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ChecklistItemSheet(plan: plan, editing: editing, list: list, messenger: messenger),
    ),
  );
}

class ChecklistItemSheet extends StatefulWidget {
  const ChecklistItemSheet({
    super.key,
    required this.plan,
    this.editing,
    this.list = TripList.checklist,
    required this.messenger,
  });

  final TripPlan plan;
  final ChecklistItem? editing;
  final TripList list;

  /// The trip screen's, for "Removed · Undo" once the sheet has closed.
  final ScaffoldMessengerState messenger;

  @override
  State<ChecklistItemSheet> createState() => _ChecklistItemSheetState();
}

class _ChecklistItemSheetState extends State<ChecklistItemSheet> {
  late final TextEditingController _text;
  LocalDate? _due;
  String? _error;
  bool _fromIdea = false;
  bool _saving = false;

  bool get _isEditing => widget.editing != null;
  bool get _packing => widget.list == TripList.packing;
  String get _question => _packing ? 'What to pack?' : 'What needs doing?';

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.editing?.text);
    _due = widget.editing?.due;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final store = context.read<TravelStore>();
    final today = store.today;
    final picked = await showDatePicker(
      context: context,
      initialDate: (_due ?? today).toDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      currentDate: today.toDateTime(),
      helpText: 'Do it by',
    );
    if (picked != null && mounted) setState(() => _due = LocalDate.fromDateTime(picked));
  }

  /// [keepOpen]: the packing list's return key, ready for the next thing.
  Future<void> _save({bool keepOpen = false}) async {
    final text = cleanChecklistText(_text.text);
    if (text == null) {
      if (keepOpen) return Navigator.of(context).pop();
      setState(() => _error = _question);
      return;
    }
    setState(() => _saving = true);
    final store = context.read<TravelStore>();
    final plan = store.plan(widget.plan.id) ?? widget.plan;
    final editing = widget.editing;
    if (editing == null) {
      final added = await store.addChecklistItem(plan, text, due: _due, idea: _fromIdea, list: widget.list);
      if (added == null && mounted) {
        setState(() {
          _saving = false;
          _error = 'This list is full. Tick off or remove a few first.';
        });
        return;
      }
      if (keepOpen && mounted) {
        setState(() {
          _saving = false;
          _fromIdea = false;
          _text.clear();
        });
        return;
      }
    } else {
      await store.saveChecklistItem(
        plan,
        editing.copyWith(text: text, due: _due, clearDue: _due == null),
        list: widget.list,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final item = widget.editing!;
    final store = context.read<TravelStore>();
    final plan = widget.plan;
    final list = widget.list;
    await store.deleteChecklistItem(plan, item, list: list);
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.messenger.showSnackBar(
      SnackBar(
        content: Text('Removed "${item.text}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => store.saveChecklistItem(plan, item, list: list),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // What's on the list now, with anything added while the sheet is open.
    final items = (context.watch<TravelStore>().plan(widget.plan.id) ?? widget.plan).trip.listOf(widget.list).values;
    final ideas = _isEditing
        ? const <String>[]
        : _packing
        ? packingIdeas(items)
        : checklistIdeas(items);
    final due = _due;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _packing
                  ? (_isEditing ? 'Edit item' : 'Something to pack')
                  : (_isEditing ? 'Edit to-do' : 'Something to do'),
              style: TravaryText.headline,
            ),
            const SizedBox(height: TravarySpace.lg),
            TextField(
              key: const ValueKey('checklist-text'),
              controller: _text,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: _packing && !_isEditing ? TextInputAction.next : TextInputAction.done,
              inputFormatters: [LengthLimitingTextInputFormatter(ChecklistItem.maxText)],
              style: TravaryText.title,
              decoration: InputDecoration(
                labelText: _question,
                hintText: _packing ? 'Sun cream' : 'Apply for the visa',
                hintStyle: TravaryText.bodySoft,
                errorText: _error,
              ),
              onChanged: (_) => setState(() {
                _error = null;
                _fromIdea = false;
              }),
              // Adding to the packing list, return keeps the keyboard up
              // for the next thing instead of moving on.
              onEditingComplete: _packing && !_isEditing ? () {} : null,
              onSubmitted: (_) => _save(keepOpen: _packing && !_isEditing),
            ),
            if (ideas.isNotEmpty) ...[
              const SizedBox(height: TravarySpace.md),
              Wrap(
                spacing: TravarySpace.sm,
                runSpacing: TravarySpace.xs,
                children: [
                  for (final idea in ideas)
                    ActionChip(
                      key: ValueKey('checklist-idea-$idea'),
                      label: Text(idea),
                      onPressed: () => setState(() {
                        _text.value = TextEditingValue(
                          text: idea,
                          selection: TextSelection.collapsed(offset: idea.length),
                        );
                        _error = null;
                        _fromIdea = true;
                      }),
                    ),
                ],
              ),
            ],
            if (!_packing) ...[
              const SizedBox(height: TravarySpace.md),
              InkWell(
                key: const ValueKey('checklist-due'),
                onTap: _pickDue,
                borderRadius: BorderRadius.circular(TravaryRadius.small),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'By when? (optional)',
                    suffixIcon: due == null
                        ? const Icon(Icons.event_outlined)
                        : IconButton(
                            tooltip: 'No date',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() => _due = null),
                          ),
                  ),
                  child: Text(
                    due == null ? 'Any time' : formatDate(due),
                    style: due == null ? TravaryText.bodySoft : TravaryText.body,
                  ),
                ),
              ),
            ],
            const SizedBox(height: TravarySpace.xl),
            FilledButton(
              key: const ValueKey('checklist-save'),
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Save' : 'Add'),
            ),
            if (_isEditing) ...[
              const SizedBox(height: TravarySpace.sm),
              TextButton(
                key: const ValueKey('checklist-delete'),
                onPressed: _saving ? null : _delete,
                style: TextButton.styleFrom(foregroundColor: TravaryColors.coral),
                child: const Text('Remove'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
