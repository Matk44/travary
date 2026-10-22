import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A plain `flutter build appbundle` passes no Dart defines: its app had no
/// RevenueCat keys and refused to start. android/app/release_defines.gradle.kts
/// gives every release build what tool/build_release.sh would have passed,
/// as tool/xcode_dart_defines.sh does for iOS (its behaviour was checked
/// with Gradle; this keeps it wired in).
void main() {
  test('the app applies it, and it reads the keys file into the Dart defines', () {
    final app = File('android/app/build.gradle.kts').readAsStringSync();
    expect(app, contains('apply(from = "release_defines.gradle.kts")'));
    final script = File('android/app/release_defines.gradle.kts').readAsStringSync();
    expect(script, contains('gradle.startParameter.taskNames.any { it.contains("Release") }'));
    expect(script, contains('rootProject.file("../config/revenuecat.local.json")'));
    expect(script, contains('"TRAVARY_REVENUECAT_ANDROID_KEY"'));
    expect(script, contains('"TRAVARY_FLIGHT_LOOKUP=true"'));
    // The property Flutter's Gradle plugin reads the defines from.
    expect(script, contains('extra["dart-defines"]'));
  });
}
