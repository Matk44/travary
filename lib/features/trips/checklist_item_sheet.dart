import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../domain/domain.dart';
import '../../logic/checklist.dart';
import '../../logic/formatters.dart';
import '../../logic/trip_plan.dart';
import '../../state/travel_store.dart';

/// Adds something to do to [plan]'s checklist, or edits [editing]: its
/// words, an optional "by" date and, when editing, removing it (with an
/// undo). Ideas fill the words in with one tap.
Future<void> showChecklistItemSheet(BuildContext context, TripPlan plan, {ChecklistItem? editing}) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: TravaryColors.linen,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ChecklistItemSheet(plan: plan, editing: editing, messenger: messenger),
    ),
  );
}

class ChecklistItemSheet extends StatefulWidget {
  const ChecklistItemSheet({super.key, required this.plan, this.editing, required this.messenger});

  final TripPlan plan;
  final ChecklistItem? editing;

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

  Future<void> _save() async {
    final text = cleanChecklistText(_text.text);
    if (text == null) {
      setState(() => _error = 'What needs doing?');
      return;
    }
    setState(() => _saving = true);
    final store = context.read<TravelStore>();
    final editing = widget.editing;
    if (editing == null) {
      final added = await store.addChecklistItem(widget.plan, text, due: _due, idea: _fromIdea);
      if (added == null && mounted) {
        setState(() {
          _saving = false;
          _error = 'This list is full. Tick off or remove a few first.';
        });
        return;
      }
    } else {
      await store.saveChecklistItem(widget.plan, editing.copyWith(text: text, due: _due, clearDue: _due == null));
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final item = widget.editing!;
    final store = context.read<TravelStore>();
    final plan = widget.plan;
    await store.deleteChecklistItem(plan, item);
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.messenger.showSnackBar(
      SnackBar(
        content: Text('Removed "${item.text}"'),
        action: SnackBarAction(label: 'Undo', onPressed: () => store.saveChecklistItem(plan, item)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ideas = _isEditing ? const <String>[] : checklistIdeas(widget.plan.trip.checklist.values);
    final due = _due;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isEditing ? 'Edit to-do' : 'Something to do', style: TravaryText.headline),
            const SizedBox(height: TravarySpace.lg),
            TextField(
              key: const ValueKey('checklist-text'),
              controller: _text,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              inputFormatters: [LengthLimitingTextInputFormatter(ChecklistItem.maxText)],
              style: TravaryText.title,
              decoration: InputDecoration(
                labelText: 'What needs doing?',
                hintText: 'Apply for the visa',
                hintStyle: TravaryText.bodySoft,
                errorText: _error,
              ),
              onChanged: (_) => setState(() {
                _error = null;
                _fromIdea = false;
              }),
              onSubmitted: (_) => _save(),
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
