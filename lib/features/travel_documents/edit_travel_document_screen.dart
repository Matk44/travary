import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/cards/travel_document_card.dart';
import '../../design/tokens.dart';
import '../../design/widgets/common.dart';
import '../../design/widgets/date_picker.dart';
import '../../design/widgets/readable_width.dart';
import '../../domain/domain.dart';
import '../../logic/destinations.dart';
import '../../logic/formatters.dart';
import '../../logic/travel_documents.dart';
import '../../state/travel_documents_store.dart';
import '../../state/travel_store.dart';
import '../booking/booking_actions.dart' show pickFile;
import '../trips/place_picker_sheet.dart';
import 'document_actions.dart';

/// Add or edit a travel document. Only its kind is needed; everything else
/// is optional. Pops with the saved document.
class EditTravelDocumentScreen extends StatefulWidget {
  const EditTravelDocumentScreen({super.key, this.existing, this.type});

  final TravelDocument? existing;

  /// The kind to start with, for a new document.
  final TravelDocumentType? type;

  @override
  State<EditTravelDocumentScreen> createState() => _EditTravelDocumentScreenState();
}

class _EditTravelDocumentScreenState extends State<EditTravelDocumentScreen> {
  late TravelDocumentType _type;
  late final TextEditingController _holder;
  late final TextEditingController _title;
  late final TextEditingController _number;
  late final TextEditingController _notes;
  LocalDate? _expires;
  String? _issuedBy;
  late List<DocumentFile> _files;
  late final TravelDocumentsStore _store;

  /// Files copied in during this edit, removed again if it's not saved.
  final _added = <DocumentFile>[];
  bool _saved = false;
  bool _saving = false;

  TravelDocument? get _existing => widget.existing;

  /// Kinds that are often one of several, so worth a name of their own.
  bool get _named => const {
    TravelDocumentType.visa,
    TravelDocumentType.insurance,
    TravelDocumentType.health,
    TravelDocumentType.other,
  }.contains(_type);

  @override
  void initState() {
    super.initState();
    _store = context.read<TravelDocumentsStore>();
    final existing = _existing;
    _type = existing?.type ?? widget.type ?? TravelDocumentType.passport;
    _holder = TextEditingController(text: existing?.holder);
    _title = TextEditingController(text: existing?.title);
    _number = TextEditingController(text: existing?.number);
    _notes = TextEditingController(text: existing?.notes);
    _expires = existing?.expiresOn;
    _issuedBy = existing?.issuedBy;
    _files = [...?existing?.files];
  }

  @override
  void dispose() {
    if (!_saved) {
      for (final file in _added) {
        _store.discardFile(file);
      }
    }
    for (final controller in [_holder, _title, _number, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final today = context.read<TravelStore>().today;
    final picked = await showTravaryDatePicker(
      context,
      initialDate: (_expires ?? addMonths(today, 12)).toDateTime(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      helpText: 'When does it expire?',
    );
    if (picked != null) setState(() => _expires = LocalDate.fromDateTime(picked));
  }

  Future<void> _pickCountry() async {
    final place = await showPlacePicker(
      context,
      countriesOnly: true,
      title: 'Issued by',
      subtitle: 'The country on the document.',
    );
    if (place != null) setState(() => _issuedBy = place.countryCode);
  }

  Future<void> _addFile() async {
    final picked = await pickFile(context, title: 'Add a photo or PDF');
    if (picked == null || !mounted) return;
    final file = await _store.importFile(picked.path, name: picked.name);
    if (!mounted) {
      await _store.discardFile(file);
      return;
    }
    setState(() {
      _files.add(file);
      _added.add(file);
    });
  }

  void _removeFile(DocumentFile file) {
    setState(() => _files.remove(file));
    if (_added.remove(file)) _store.discardFile(file);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final now = DateTime.now();
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final document = TravelDocument(
      id: _existing?.id ?? _store.newId(),
      type: _type,
      holder: _holder.text.trim(),
      title: _named ? text(_title) : null,
      number: text(_number),
      issuedBy: _issuedBy,
      expiresOn: _expires,
      notes: text(_notes),
      files: _files,
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _store.save(document);
    _saved = true;
    if (mounted) Navigator.of(context).pop(document);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelDocumentsStore>();
    final title = _existing == null ? 'Add a document' : 'Edit document';
    if (!store.isUnlocked) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const DocumentsLockedView(),
      );
    }
    final holders = knownHolders(store.documents);
    final holder = _holder.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [TextButton(onPressed: _saving ? null : _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: readablePadding(
          context,
          const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.xxl),
        ),
        children: [
          const SectionLabel('What is it?', inset: false),
          Wrap(
            spacing: TravarySpace.sm,
            runSpacing: TravarySpace.sm,
            children: [
              for (final type in TravelDocumentType.values)
                ChoiceChip(
                  avatar: Icon(documentTypeIcon(type), size: 16),
                  label: Text(type.label),
                  selected: _type == type,
                  onSelected: (_) => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: TravarySpace.lg),
          TextField(
            controller: _holder,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Whose is it?', hintText: 'You'),
            onChanged: (_) => setState(() {}),
          ),
          if (holders.isNotEmpty || holder.isNotEmpty) ...[
            const SizedBox(height: TravarySpace.sm),
            Wrap(
              spacing: TravarySpace.sm,
              children: [
                if (holder.isNotEmpty) ActionChip(label: const Text('You'), onPressed: () => _setHolder('')),
                for (final name in holders)
                  if (name != holder) ActionChip(label: Text(name), onPressed: () => _setHolder(name)),
              ],
            ),
          ],
          if (_named) ...[
            const SizedBox(height: TravarySpace.md),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: 'Name (optional)', hintText: _titleHint(_type)),
            ),
          ],
          const SizedBox(height: TravarySpace.md),
          TextField(
            key: const ValueKey('document-number'),
            controller: _number,
            // Never let the keyboard learn or suggest a document number.
            autocorrect: false,
            enableSuggestions: false,
            enableIMEPersonalizedLearning: false,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: '${_type.numberLabel} (optional)'),
          ),
          const SizedBox(height: TravarySpace.md),
          _PickerRow(
            key: const ValueKey('document-expiry'),
            icon: Icons.event_outlined,
            label: _expires == null ? 'Expiry date on it (optional)' : 'Expires ${formatDate(_expires!)}',
            onTap: _pickExpiry,
            onClear: _expires == null ? null : () => setState(() => _expires = null),
          ),
          const SizedBox(height: TravarySpace.sm),
          _PickerRow(
            key: const ValueKey('document-country'),
            icon: Icons.public_rounded,
            label: _issuedBy == null ? 'Issued by (optional)' : 'Issued by ${countryPlace(_issuedBy!).name}',
            onTap: _pickCountry,
            onClear: _issuedBy == null ? null : () => setState(() => _issuedBy = null),
          ),
          const SizedBox(height: TravarySpace.md),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: 'Notes (optional)', hintText: _notesHint(_type)),
          ),
          const SectionLabel('Photos and PDFs', inset: false),
          for (final file in _files)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(file.isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined),
              title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => _removeFile(file),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _addFile,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Add a photo or PDF'),
          ),
          const SizedBox(height: TravarySpace.xl),
          FilledButton(onPressed: _saving ? null : _save, child: const Text('Save on this phone')),
          const SizedBox(height: TravarySpace.sm),
          Text(
            'Kept on this phone only: never uploaded or read by AI.',
            style: TravaryText.small,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _setHolder(String name) {
    _holder.text = name;
    setState(() {});
  }
}

String _titleHint(TravelDocumentType type) => switch (type) {
  TravelDocumentType.visa => 'ESTA (USA)',
  TravelDocumentType.insurance => 'Annual family policy',
  TravelDocumentType.health => 'GHIC',
  _ => 'Birth certificate',
};

String _notesHint(TravelDocumentType type) => switch (type) {
  TravelDocumentType.insurance => '24-hour emergency number, what\'s covered',
  TravelDocumentType.visa => 'Which trips it covers, entries left',
  _ => 'Anything worth having to hand',
};

/// A tappable line that opens a picker, with a way to clear it.
class _PickerRow extends StatelessWidget {
  const _PickerRow({super.key, required this.icon, required this.label, required this.onTap, this.onClear});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TravaryRadius.small),
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          suffixIcon: onClear == null
              ? null
              : IconButton(tooltip: 'Clear', icon: const Icon(Icons.close_rounded), onPressed: onClear),
        ),
        child: Text(label, style: onClear == null ? TravaryText.bodySoft : TravaryText.body),
      ),
    );
  }
}
