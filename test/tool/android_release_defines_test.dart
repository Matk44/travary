import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A plain `flutter build appbundle` passes no Dart defines: its app had no
/// RevenueCat keys and refused to start. android/app/build.gradle.kts gives
/// every release build what tool/build_release.sh would have passed, as
/// tool/xcode_dart_defines.sh does for iOS (its behaviour was checked with
/// Gradle; this keeps it wired in).
void main() {
  test('the app reads the keys file into the Dart defines', () {
    final app = File('android/app/build.gradle.kts').readAsStringSync();
    expect(app, contains('gradle.startParameter.taskNames.any { it.contains("Release") }'));
    expect(app, contains('rootProject.file("../config/revenuecat.local.json")'));
    expect(app, contains('"TRAVARY_REVENUECAT_ANDROID_KEY"'));
    expect(app, contains('"TRAVARY_FLIGHT_LOOKUP=true"'));
    // The property Flutter's Gradle plugin reads the defines from.
    expect(app, contains('extra["dart-defines"]'));
  });

  test('no build script is applied from its own .gradle.kts file', () {
    // Release lint can't read one ("Cannot find a KaModule") and fails
    // `flutter build appbundle`.
    final scripts = Directory('android')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.gradle.kts'))
        .where((f) => !f.path.contains('${Platform.pathSeparator}build${Platform.pathSeparator}'))
        .map((f) => f.uri.pathSegments.last);
    expect(scripts.toSet(), {'build.gradle.kts', 'settings.gradle.kts'});
  });
}
