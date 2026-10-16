import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The native settings the store forms and the privacy policy rely on:
/// analytics and crash reports stay off until a release build turns them
/// on (`useFirebaseAnalytics`, `useCrashReporting`), and Crashlytics has
/// what it needs to start (Android) and to read native crashes (iOS).
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

  bool metaOff(String name) => RegExp('android:name="$name"\\s+android:value="false"').hasMatch(manifest);
  bool plistOff(String key) => RegExp('<key>$key</key>\\s*<false/>').hasMatch(infoPlist);

  test('analytics and crash reports are off until a release build turns them on', () {
    expect(metaOff('firebase_analytics_collection_enabled'), isTrue);
    expect(metaOff('firebase_crashlytics_collection_enabled'), isTrue);
    expect(plistOff('FIREBASE_ANALYTICS_COLLECTION_ENABLED'), isTrue);
    expect(plistOff('FirebaseCrashlyticsCollectionEnabled'), isTrue);
  });

  test('no advertising ID on Android', () {
    expect(manifest, contains('android:name="com.google.android.gms.permission.AD_ID" tools:node="remove"'));
    expect(metaOff('google_analytics_adid_collection_enabled'), isTrue);
  });

  test('Android applies the Crashlytics plugin, without which the SDK refuses to start', () {
    expect(File('android/app/build.gradle.kts').readAsStringSync(), contains('id("com.google.firebase.crashlytics")'));
    expect(File('android/settings.gradle.kts').readAsStringSync(), contains('id("com.google.firebase.crashlytics")'));
  });

  test('iOS release builds upload their symbols, so native crashes are readable', () {
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(project, contains('[Crashlytics] Upload symbols'));
    expect(project, contains(r'${PODS_ROOT}/FirebaseCrashlytics/run'));
  });
}
