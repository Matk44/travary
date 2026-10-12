import 'dart:async';

import '../data/travi_greeting_record.dart';
import '../domain/local_date.dart';
import '../logic/travi_cameos.dart';

/// Whether Travi may greet the traveller on his own (`greetsToday`): at most
/// once a day on this phone, whichever screen asks first (the countdown's
/// wave, the free day's sip).
class TraviGreetings {
  TraviGreetings(this._record) {
    _loaded = _record.load().then((day) => _last = day, onError: (_) => null);
  }

  final TraviGreetingRecord _record;
  late final Future<void> _loaded;
  LocalDate? _last;

  /// True once a day: the caller greets, and nobody else does today.
  Future<bool> claim(LocalDate today) async {
    await _loaded;
    if (!greetsToday(today: today, lastGreeted: _last)) return false;
    _last = today;
    unawaited(_record.save(today));
    return true;
  }
}
