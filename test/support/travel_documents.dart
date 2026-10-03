import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_document_repository.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/travel_documents_store.dart';

/// The travel documents store for a test app: [documents] in memory, behind
/// a [lock] that opens at once unless told otherwise.
ChangeNotifierProvider<TravelDocumentsStore> travelDocumentsProvider({
  List<TravelDocument> documents = const [],
  FixedDocumentLock? lock,
  MemoryTravelDocumentRepository? repository,
}) => ChangeNotifierProvider(
  create: (_) => TravelDocumentsStore(
    repository: repository ?? MemoryTravelDocumentRepository(documents),
    lock: lock ?? FixedDocumentLock(),
  ),
);
