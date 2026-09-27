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
  try {
    runApp(TravaryApp(dependencies: await bootstrap()));
  } on StartupException catch (e) {
    runApp(StartupErrorApp(message: e.message, hint: e.hint));
  } catch (e) {
    runApp(StartupErrorApp(message: 'Travary couldn\'t start.', hint: '$e'));
  }
}
