import 'package:provider/provider.dart';
import 'package:travary/data/ai_consent_record.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/ai_consent_store.dart';

/// Whether Smart Import and trip looks may use Google's AI, as the app
/// provides it above everything else.
ChangeNotifierProvider<AiConsentStore> aiConsentProvider({AiConsent consent = AiConsent.undecided}) =>
    ChangeNotifierProvider(create: (_) => AiConsentStore(MemoryAiConsentRecord(consent)));
