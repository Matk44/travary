import 'package:travary/data/countdown_widget_bridge.dart';
import 'package:travary/logic/countdown_widget_setup.dart';

/// What each phone says about the countdown widget before it's been added.
const androidPhone = (supported: true, added: false, canPin: true);
const iPhone = (supported: true, added: false, canPin: false);
const oldiPhone = homeWidgetUnavailable;

/// A phone with no folder to write: just the answers about the home screen,
/// which a test changes as the traveller would (adds the widget, say).
class FakeHomeWidget implements CountdownWidgetBridge {
  FakeHomeWidget([this.phone = androidPhone]);

  HomeWidgetStatus phone;

  /// Whether the launcher agrees to show its dialog.
  bool launcherAsks = true;

  /// The phone can't answer.
  bool failing = false;

  int pins = 0;

  @override
  Future<CountdownWidgetFolder?> folder() async => null;

  @override
  Future<void> reload() async {}

  @override
  Future<HomeWidgetStatus> status() async {
    if (failing) throw StateError('no answer');
    return phone;
  }

  @override
  Future<bool> requestPin() async {
    pins++;
    return launcherAsks;
  }

  /// The traveller put the widget on the home screen.
  void add() => phone = (supported: phone.supported, added: true, canPin: phone.canPin);

  /// ...and took it off again.
  void remove() => phone = (supported: phone.supported, added: false, canPin: phone.canPin);
}
