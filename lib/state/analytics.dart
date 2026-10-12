import 'package:flutter/foundation.dart';

/// Where [track] sends events besides the debug log: Firebase Analytics in
/// cloud release builds (set up by `bootstrap`), nowhere in demo mode and
/// tests.
void Function(String event, Map<String, Object> parameters)? analyticsSink;

/// Funnel events (onboarding steps, paywall shown, purchase started, ...).
/// Action types and counts only: never names, places, documents, booking
/// details or anything typed. Values are sent as numbers or short text.
void track(String event, [Map<String, Object?> properties = const {}]) {
  if (kDebugMode) {
    final props = properties.entries.map((e) => '${e.key}=${e.value}').join(' ');
    debugPrint('[analytics] $event $props');
  }
  final sink = analyticsSink;
  if (sink == null) return;
  sink(event, {
    for (final MapEntry(:key, :value) in properties.entries)
      if (value != null)
        key: switch (value) {
          num() => value,
          _ => '$value'.length > 100 ? '$value'.substring(0, 100) : '$value',
        },
  });
}
