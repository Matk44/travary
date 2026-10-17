import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/logic/countdown_widget.dart';

/// The home-screen countdown is three programs agreeing on one folder: the
/// app writes it (lib/data/countdown_widget_bridge.dart), the iOS widget
/// extension and the Android widget read it. These keep them in step.
void main() {
  String read(String path) => File(path).readAsStringSync();

  test('the file version is the same in Dart, Swift and Kotlin', () {
    expect(read('ios/CountdownWidget/CountdownData.swift'), contains('static let version = $countdownWidgetVersion'));
    expect(
      read('android/app/src/main/kotlin/com/travary/app/widget/CountdownWidgetData.kt'),
      contains('private const val VERSION = $countdownWidgetVersion'),
    );
  });

  test('the app and the widgets use the same channel and folder', () {
    const channel = "'travary/countdown_widget'";
    expect(read('lib/data/countdown_widget_bridge.dart'), contains("MethodChannel($channel)"));
    expect(read('ios/Runner/CountdownWidgetChannel.swift'), contains('name: "travary/countdown_widget"'));
    expect(
      read('android/app/src/main/kotlin/com/travary/app/widget/CountdownWidgetChannel.kt'),
      contains('"travary/countdown_widget"'),
    );
    // iOS: the same folder in the same App Group, on both sides.
    for (final path in ['ios/Runner/CountdownWidgetChannel.swift', 'ios/CountdownWidget/CountdownData.swift']) {
      expect(read(path), contains('"group.com.travary.app"'), reason: path);
      expect(read(path), contains('"CountdownWidget"'), reason: path);
    }
    expect(read('ios/CountdownWidget/CountdownWidget.entitlements'), contains('group.com.travary.app'));
    expect(read('ios/Runner/Runner.entitlements'), contains('group.com.travary.app'));
  });

  test('asking the phone about the widget is the same on both platforms', () {
    const swift = 'ios/Runner/CountdownWidgetChannel.swift';
    const kotlin = 'android/app/src/main/kotlin/com/travary/app/widget/CountdownWidgetChannel.kt';
    // The calls the app makes, answered on each side.
    for (final method in ['status', 'pin']) {
      expect(read('lib/data/countdown_widget_bridge.dart'), contains("'$method'"), reason: method);
      expect(read(swift), contains('case "$method"'), reason: method);
      expect(read(kotlin), contains('"$method" ->'), reason: method);
    }
    // What `status` answers with.
    for (final key in ['supported', 'added', 'canPin']) {
      expect(read('lib/data/countdown_widget_bridge.dart'), contains("answer['$key']"), reason: key);
      expect(read(swift), contains('"$key"'), reason: key);
      expect(read(kotlin), contains('"$key"'), reason: key);
    }
    // iOS finds the widget on the home screen by its kind, the one the widget declares.
    expect(read(swift), contains('static let kind = "CountdownWidget"'));
    expect(read('ios/CountdownWidget/CountdownWidget.swift'), contains('kind: "CountdownWidget"'));
    // iOS has no call that adds a widget: it never claims it can.
    expect(read(swift), contains('result(false)'));
    expect(read(swift), contains('#available(iOS 17.0, *)'), reason: 'the widget needs iOS 17');
    // Android asks the launcher to place it.
    expect(read(kotlin), contains('requestPinAppWidget'));
  });

  test('the iOS widget is built and embedded with the app', () {
    final project = read('ios/Runner.xcodeproj/project.pbxproj');
    expect(project, contains('CountdownWidget.appex in Embed Foundation Extensions'));
    expect(project, contains('PRODUCT_BUNDLE_IDENTIFIER = com.travary.app.CountdownWidget;'));
    expect(project, contains('CountdownWidgetChannel.swift in Sources'));
  });

  test("a tap opens the app on the widget's link, on both platforms", () {
    // iOS opens travary:// links only for an app that registers the scheme.
    expect(read('ios/Runner/Info.plist'), contains('<string>travary</string>'));
    expect(countdownWidgetLink('trip-1').scheme, 'travary');
    final manifest = read('android/app/src/main/AndroidManifest.xml');
    expect(manifest, contains('android:name=".widget.CountdownWidgetProvider"'));
    expect(manifest, contains('android:resource="@xml/countdown_widget_info"'));
  });
}
