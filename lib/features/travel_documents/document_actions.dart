import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../domain/domain.dart';
import '../../state/travel_documents_store.dart';
import 'edit_travel_document_screen.dart';
import 'travel_document_screen.dart';
import 'travel_documents_screen.dart';

/// Asks the phone's lock (Face ID, fingerprint or passcode) if the travel
/// documents are locked. True once they can be shown.
Future<bool> ensureDocumentsUnlocked(BuildContext context) async {
  final store = context.read<TravelDocumentsStore>();
  if (store.isUnlocked) return true;
  final ok = await store.unlock();
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your travel documents stay locked.')));
  }
  return ok;
}

/// Adds a passport, visa, insurance policy or other document.
Future<void> startAddTravelDocument(BuildContext context, {TravelDocumentType? type}) async {
  if (!await ensureDocumentsUnlocked(context) || !context.mounted) return;
  final saved = await Navigator.of(
    context,
  ).push<TravelDocument>(MaterialPageRoute(builder: (_) => EditTravelDocumentScreen(type: type)));
  if (saved == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${saved.name} saved on this phone')));
}

Future<void> openTravelDocument(BuildContext context, TravelDocument document) async {
  if (!await ensureDocumentsUnlocked(context) || !context.mounted) return;
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => TravelDocumentScreen(documentId: document.id)));
}

/// Every travel document, on a screen of its own (from Profile, or "See
/// all" on the Documents tab).
void openTravelDocuments(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TravelDocumentsScreen()));

/// Shown in place of a document's screen while the documents are locked
/// (the app went to the background), until the traveller unlocks them.
/// "Not now" always leaves, so nobody is stuck without the passcode.
class DocumentsLockedView extends StatelessWidget {
  const DocumentsLockedView({super.key});

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TravarySpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 44, color: TravaryColors.kraft),
            const SizedBox(height: TravarySpace.lg),
            Text('Locked', style: TravaryText.title),
            const SizedBox(height: TravarySpace.sm),
            Text(
              'Your travel documents lock when you leave Travary.',
              style: TravaryText.bodySoft,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TravarySpace.xl),
            FilledButton.icon(
              onPressed: () => ensureDocumentsUnlocked(context),
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Unlock'),
            ),
            if (navigator.canPop()) ...[
              const SizedBox(height: TravarySpace.sm),
              TextButton(
                key: const ValueKey('documents-locked-leave'),
                onPressed: () => navigator.maybePop(),
                child: const Text('Not now'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
