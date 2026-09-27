import 'package:flutter/foundation.dart';

/// Funnel events (paywall shown, purchase started, ...). Printed in debug
/// for now; wire to an analytics service before launch so paywall
/// placement and prices can be measured.
void track(String event, [Map<String, Object?> properties = const {}]) {
  if (kDebugMode) {
    final props = properties.entries.map((e) => '${e.key}=${e.value}').join(' ');
    debugPrint('[analytics] $event $props');
  }
}
