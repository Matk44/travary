import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

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
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
