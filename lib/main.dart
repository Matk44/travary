import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/orientation_policy.dart';
import 'design/tokens.dart';

/// Travary: add your bookings and every day of your holiday organises itself.
///
/// Layers (each only depends on the ones above it):
/// - `domain/`   plain data: Booking, Trip, dates
/// - `logic/`    pure rules: day plans, trip grouping, card wording
/// - `data/`     storage: demo (memory) or cloud (Firestore)
/// - `state/`    TravelStore, the single source of truth for screens
/// - `design/`   the look: tokens, cards, art. Restyle here.
/// - `features/` screens
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge to edge on every Android (Android 15 insists), the bars clear.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(TravarySystemBars.onLight);
  // Upright on a phone; a tablet or an open foldable turns.
  await OrientationPolicy.instance.start();
  await _start();
}

/// Starts the app, or says why it couldn't with a way to try again (the
/// first open needs the internet, and a plane or a busy airport may not
/// have it).
Future<void> _start() async {
  try {
    runApp(TravaryApp(dependencies: await bootstrap()));
  } on StartupException catch (e) {
    runApp(StartupErrorApp(message: e.message, hint: e.hint, onRetry: _start));
  } catch (e) {
    runApp(StartupErrorApp(message: 'Travary couldn\'t start.', hint: '$e', onRetry: _start));
  }
}
