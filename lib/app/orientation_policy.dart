import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// A phone stays upright, as Travary is drawn for it. A tablet or an
/// unfolded foldable (a screen whose shorter side is at least
/// [ScreenLayout.rotatesFrom]) turns with the device, the way people hold
/// them. Checked at launch and whenever the screen changes: a foldable
/// opened turns, closed it's a phone again. (An iPad that can share its
/// screen turns whatever an app asks, and Android 16 lets large screens
/// turn too: every screen is laid out for both.)
class OrientationPolicy with WidgetsBindingObserver {
  OrientationPolicy._();

  static final instance = OrientationPolicy._();

  List<DeviceOrientation>? _applied;

  /// The orientations allowed on a screen this size: none listed means
  /// every one the app declares.
  static List<DeviceOrientation> orientationsFor(Size screen) =>
      screen.shortestSide >= ScreenLayout.rotatesFrom ? const [] : const [DeviceOrientation.portraitUp];

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    await _apply();
  }

  @override
  void didChangeMetrics() => _apply();

  Future<void> _apply() async {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;
    final view = views.first;
    // The whole display, not this window: a tablet in a split screen is
    // still a tablet.
    final display = view.display;
    var screen = display.size / display.devicePixelRatio;
    if (screen.isEmpty) screen = view.physicalSize / view.devicePixelRatio;
    if (screen.isEmpty) return;
    final wanted = orientationsFor(screen);
    if (_applied != null && listEquals(_applied, wanted)) return;
    _applied = wanted;
    await SystemChrome.setPreferredOrientations(wanted);
  }
}
