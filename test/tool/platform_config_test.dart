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

  test('Android has predictive back on every version, as Android 16 does', () {
    expect(manifest, contains('android:enableOnBackInvokedCallback="true"'));
  });

  test('iPads keep every orientation, so they can share the screen (Split View, windows)', () {
    final ipad = RegExp(
      r'<key>UISupportedInterfaceOrientations~ipad</key>\s*<array>([\s\S]*?)</array>',
    ).firstMatch(infoPlist);
    expect(ipad, isNotNull);
    for (final orientation in ['Portrait', 'PortraitUpsideDown', 'LandscapeLeft', 'LandscapeRight']) {
      expect(ipad![1], contains('UIInterfaceOrientation$orientation'));
    }
    expect(infoPlist, isNot(contains('UIRequiresFullScreen')));
  });

  test('iOS release builds upload their symbols, so native crashes are readable', () {
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(project, contains('[Crashlytics] Upload symbols'));
    expect(project, contains(r'${PODS_ROOT}/FirebaseCrashlytics/run'));
  });
}
