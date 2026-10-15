import 'package:flutter/foundation.dart';

import '../data/ai_consent_record.dart';
import '../domain/ai_consent.dart';
import '../logic/ai_consent.dart';
import 'analytics.dart';

/// Whether Smart Import and automatic trip looks may use Google's Gemini
/// (`logic/ai_consent.dart`), on this phone whoever is signed in. Nothing
/// goes to Gemini until it's [allowed].
class AiConsentStore extends ChangeNotifier {
  AiConsentStore(this._record) {
    ready = _load();
  }

  final AiConsentRecord _record;
  AiConsent _consent = AiConsent.undecided;
  bool _loaded = false;
  bool _disposed = false;

  /// Completes once the stored answer is read.
  late final Future<void> ready;

  AiConsent get consent => _consent;
  bool get loaded => _loaded;
  bool get allowed => _consent == AiConsent.allowed;

  Future<void> _load() async {
    final consent = await _record.load();
    if (_disposed) return;
    _consent = consent;
    _loaded = true;
    notifyListeners();
  }

  /// "Allow", from wherever it was asked.
  Future<void> allow(AiAsk from) => _answer(AiConsent.allowed, from);

  /// "Not now", or Profile's switch turned off.
  Future<void> decline(AiAsk from) => _answer(AiConsent.declined, from);

  Future<void> _answer(AiConsent consent, AiAsk from) async {
    await ready;
    if (_disposed || _consent == consent) return;
    _consent = consent;
    notifyListeners();
    track('ai_consent', {'choice': consent.name, 'from': from.name});
    await _record.save(consent);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
