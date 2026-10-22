import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The keyboard is only ever up for a text field that has it.
///
/// iOS 26 drops the keyboard when the app is briefly inactive (a quick app
/// switch, the full-screen screenshot preview) and Flutter lets go of the
/// field, then iOS brings the keyboard straight back. Flutter never hides
/// it again, so it stayed over every screen with nothing to type into
/// (flutter/flutter#189051, fixed in the engine after the 3.38 we build
/// with: this can go once that's in). Whenever the keyboard moves or the
/// app comes back with no field focused, this hides it.
class KeyboardGuard extends StatefulWidget {
  const KeyboardGuard({super.key, required this.child});

  final Widget child;

  @override
  State<KeyboardGuard> createState() => _KeyboardGuardState();
}

class _KeyboardGuardState extends State<KeyboardGuard> with WidgetsBindingObserver {
  late FlutterView _view;

  // Hidden once per stray keyboard: it moves on every frame as it goes down.
  bool _hiding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _view = View.of(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _checkAfterFrame();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAfterFrame();
  }

  /// Once the frame is drawn and focus has settled: a field focused as a
  /// screen opens takes focus just after the frame that builds it.
  void _checkAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => scheduleMicrotask(_check));
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _check() {
    if (!mounted) return;
    if (_view.viewInsets.bottom == 0 || _fieldHasFocus) {
      _hiding = false;
      return;
    }
    if (_hiding) return;
    _hiding = true;
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  static bool get _fieldHasFocus =>
      FocusManager.instance.primaryFocus?.context?.findAncestorStateOfType<EditableTextState>() != null;

  @override
  Widget build(BuildContext context) => widget.child;
}
