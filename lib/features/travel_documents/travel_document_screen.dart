import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../design/cards/travel_document_card.dart';
import '../../design/tokens.dart';
import '../../design/widgets/common.dart';
import '../../domain/domain.dart';
import '../../logic/destinations.dart';
import '../../logic/formatters.dart';
import '../../logic/travel_documents.dart';
import '../../state/travel_documents_store.dart';
import '../../state/travel_store.dart';
import 'document_actions.dart';
import 'edit_travel_document_screen.dart';

/// One travel document: whose it is, when it runs out (and whether that's
/// a problem for the next trip), its number (hidden until asked), notes,
/// and its photos and PDFs. Hidden again whenever the documents lock.
class TravelDocumentScreen extends StatefulWidget {
  const TravelDocumentScreen({super.key, required this.documentId});

  final String documentId;

  @override
  State<TravelDocumentScreen> createState() => _TravelDocumentScreenState();
}

class _TravelDocumentScreenState extends State<TravelDocumentScreen> {
  bool _showNumber = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelDocumentsStore>();
    if (!store.isUnlocked) {
      _showNumber = false;
      return Scaffold(appBar: AppBar(), body: const DocumentsLockedView());
    }
    final document = store.document(widget.documentId);
    if (document == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This document has been deleted.')),
      );
    }
    final travel = context.watch<TravelStore>();
    final status = documentStatus(document, today: travel.today, nextTrip: travel.focus.plan);
    final advice = status == null ? null : documentAdvice(document.type, status.alert);
    final warn = status != null && (status.alert == DocumentAlert.trip || status.alert == DocumentAlert.expired);
    final number = document.number;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(document)),
          IconButton(
            tooltip: 'Send a copy',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _sendCopy(store, document),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => value == 'delete' ? _delete(store, document) : null,
            itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete document'))],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.xxl),
        children: [
          Row(
            children: [
              Icon(documentTypeIcon(document.type), size: 18, color: TravaryColors.inkSoft),
              const SizedBox(width: TravarySpace.xs),
              Text(holderLabel(document).toUpperCase(), style: TravaryText.eyebrow),
            ],
          ),
          const SizedBox(height: TravarySpace.xs),
          Text(document.name, style: TravaryText.display),
          if (status != null) ...[
            const SizedBox(height: TravarySpace.sm),
            Text(
              status.text,
              style: TravaryText.body.copyWith(
                color: warn ? TravaryColors.coral : TravaryColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (advice != null) ...[const SizedBox(height: TravarySpace.sm), Text(advice, style: TravaryText.bodySoft)],
          const SizedBox(height: TravarySpace.md),
          if (number != null)
            _Line(
              label: document.type.numberLabel,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _showNumber ? number : maskDocumentNumber(number),
                      key: const ValueKey('document-number-shown'),
                      style: TravaryText.title.copyWith(letterSpacing: 1.5),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _showNumber = !_showNumber),
                    child: Text(_showNumber ? 'Hide' : 'Show'),
                  ),
                  IconButton(
                    tooltip: 'Copy number',
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    onPressed: () => _copy(number),
                  ),
                ],
              ),
            ),
          if (document.issuedBy case final country?)
            _Line(
              label: 'Issued by',
              child: Text(countryPlace(country).name, style: TravaryText.body),
            ),
          if (document.expiresOn case final expires?)
            _Line(
              label: 'Expires',
              child: Text(formatDate(expires), style: TravaryText.body),
            ),
          if (document.notes case final notes?)
            _Line(
              label: 'Notes',
              child: SelectableText(notes, style: TravaryText.body),
            ),
          const SectionLabel('Photos and PDFs', inset: false),
          if (document.files.isEmpty)
            Text('None yet. Add a photo of it so you have it to hand.', style: TravaryText.bodySoft)
          else
            Wrap(
              spacing: TravarySpace.sm,
              runSpacing: TravarySpace.sm,
              children: [
                for (final file in document.files) _FileTile(file: file, onOpen: () => _open(store, document, file)),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _edit(TravelDocument document) => Navigator.of(
    context,
  ).push<TravelDocument>(MaterialPageRoute(builder: (_) => EditTravelDocumentScreen(existing: document)));

  Future<void> _copy(String number) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Number copied')));
  }

  /// A copy goes wherever the traveller sends it, so ask first.
  Future<void> _sendCopy(TravelDocumentsStore store, TravelDocument document) async {
    final whose = holderLabel(document) == 'You' ? 'your' : '${holderLabel(document)}\'s';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send a copy of $whose ${document.name.toLowerCase()}?'),
        content: const Text(
          'The copy leaves Travary and goes wherever you share it. Only send it to someone you trust.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send a copy')),
        ],
      ),
    );
    if (confirmed != true) return;
    final files = [
      for (final file in document.files)
        if (store.fileFor(file).existsSync()) XFile(store.fileFor(file).path, name: file.name),
    ];
    final lines = [
      '${document.name} · ${holderLabel(document)}',
      if (document.number case final number?) '${document.type.numberLabel}: $number',
      if (document.expiresOn case final expires?) 'Expires ${formatDate(expires)}',
    ];
    await SharePlus.instance.share(
      ShareParams(subject: document.name, text: lines.join('\n'), files: files.isEmpty ? null : files),
    );
  }

  Future<void> _delete(TravelDocumentsStore store, TravelDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${document.name}?'),
        content: const Text('It and its photos are deleted from this phone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    Navigator.of(context).pop();
    await store.delete(document);
  }

  Future<void> _open(TravelDocumentsStore store, TravelDocument document, DocumentFile file) async {
    final stored = store.fileFor(file);
    if (!file.isImage) {
      await OpenFilex.open(stored.path);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ImageViewer(title: document.name, file: stored),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TravarySpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TravaryText.eyebrow),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }
}

/// A photo's thumbnail, or a PDF's tile.
class _FileTile extends StatelessWidget {
  const _FileTile({required this.file, required this.onOpen});

  final DocumentFile file;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final stored = context.read<TravelDocumentsStore>().fileFor(file);
    final shape = BorderRadius.circular(TravaryRadius.small);
    return Semantics(
      button: true,
      label: 'Open ${file.name}',
      child: Material(
        color: TravaryColors.paper,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: SizedBox(
            width: 104,
            height: 104,
            child: file.isImage
                ? Image.file(
                    stored,
                    fit: BoxFit.cover,
                    cacheWidth: 312,
                    errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, color: TravaryColors.inkFaint),
                  )
                : Padding(
                    padding: const EdgeInsets.all(TravarySpace.sm),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf_outlined, size: 32, color: TravaryColors.inkSoft),
                        const SizedBox(height: TravarySpace.xs),
                        Text(
                          file.name,
                          style: TravaryText.small,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// A document's photo full screen, on white, zoomable. Locks with the rest.
class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.title, required this.file});

  final String title;
  final File file;

  @override
  Widget build(BuildContext context) {
    final unlocked = context.watch<TravelDocumentsStore>().isUnlocked;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(title, style: TravaryText.label),
      ),
      body: !unlocked
          ? const DocumentsLockedView()
          : InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: Image.file(file, errorBuilder: (_, _, _) => const Text('This file can\'t be shown.')),
              ),
            ),
    );
  }
}
