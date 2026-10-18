import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/countdown_widget_bridge.dart';
import '../data/countdown_widget_settings.dart';
import '../logic/countdown_widget_setup.dart';
import 'analytics.dart';

/// Helping the traveller put the countdown widget on their home screen
/// (`logic/countdown_widget_setup.dart`): whether the phone can have it,
/// whether it's there, the offer on Today's countdown and its "Not now",
/// and on Android asking the launcher to place it. What the widget shows is
/// `CountdownWidgetSync`'s job. Free for everyone, like the widget.
///
/// Without a bridge (tests, web) the phone has no widget and nothing offers.
class CountdownWidgetStore extends ChangeNotifier {
  CountdownWidgetStore({required CountdownWidgetBridge? bridge, required CountdownWidgetSettings settings})
    : _bridge = bridge,
      _settings = settings;

  final CountdownWidgetBridge? _bridge;
  final CountdownWidgetSettings _settings;

  bool _loaded = false;
  bool _declined = false;
  bool _everAdded = false;
  HomeWidgetStatus _status = homeWidgetUnavailable;
  bool _disposed = false;

  /// Whether this phone can have the widget at all (not iOS 15 or 16, not
  /// before the phone has answered).
  bool get available => _loaded && _status.supported;

  /// The widget is on the home screen now.
  bool get added => _status.added;

  HomeWidgetStatus get status => _status;

  /// Today's countdown offers it: [offersCountdownWidget].
  bool get offers => _loaded && offersCountdownWidget(status: _status, everAdded: _everAdded, declined: _declined);

  Future<void> start() async {
    if (_bridge == null) return;
    final choice = await _settings.load();
    if (_disposed) return;
    _declined = choice.declined;
    _everAdded = choice.everAdded;
    await _read();
    _loaded = true;
    _changed();
  }

  /// Back from the background (or from the home screen, where it may have
  /// just been placed): asks the phone again.
  Future<void> refresh() async {
    if (_bridge == null || !_loaded) return;
    final before = (_status, _everAdded);
    await _read();
    if (before != (_status, _everAdded)) _changed();
  }

  /// Android: asks the launcher to place the widget. True if its dialog was
  /// asked for; false means showing the steps instead.
  Future<bool> requestPin() async {
    final bridge = _bridge;
    if (bridge == null) return false;
    bool shown;
    try {
      shown = await bridge.requestPin();
    } catch (error) {
      if (kDebugMode) debugPrint('Countdown widget not pinned: $error');
      shown = false;
    }
    track('countdown_widget_pin_asked', {'shown': shown});
    return shown;
  }

  /// "Not now" on Today: it isn't offered there again (Profile keeps it).
  Future<void> decline() async {
    _declined = true;
    await _save();
    track('countdown_widget_declined');
    _changed();
  }

  /// A sheet was opened, from [from] (`today` or `profile`).
  void opened(String from) => track('countdown_widget_sheet_opened', {'from': from});

  Future<void> _read() async {
    final bridge = _bridge;
    if (bridge == null) return;
    try {
      _status = await bridge.status();
    } catch (error) {
      // The phone didn't say: nothing is offered until it does.
      if (kDebugMode) debugPrint('Countdown widget not read: $error');
      _status = homeWidgetUnavailable;
    }
    if (_disposed) return;
    if (_status.added && !_everAdded) {
      // Seen on the home screen for the first time: never offered again,
      // even if it's taken off.
      _everAdded = true;
      track('countdown_widget_added');
      await _save();
    }
  }

  Future<void> _save() => _settings.save((declined: _declined, everAdded: _everAdded));

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
