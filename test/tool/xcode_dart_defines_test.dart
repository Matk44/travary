import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// An Archive from Xcode builds with whatever the last flutter command left
/// in Generated.xcconfig, often no defines at all: its app had no
/// RevenueCat keys and refused to start. tool/xcode_dart_defines.sh gives
/// every Release build what tool/build_release.sh would have passed.
void main() {
  late Directory project;

  setUp(() {
    project = Directory.systemTemp.createTempSync('xcode_defines_');
    Directory('${project.path}/tool').createSync();
    File('tool/xcode_dart_defines.sh').copySync('${project.path}/tool/xcode_dart_defines.sh');
  });

  tearDown(() => project.deleteSync(recursive: true));

  void writeKeys(String json) {
    Directory('${project.path}/config').createSync(recursive: true);
    File('${project.path}/config/revenuecat.local.json').writeAsStringSync(json);
  }

  String encode(List<String> defines) => defines.map((d) => base64.encode(utf8.encode(d))).join(',');

  ProcessResult run({required String configuration, List<String> defines = const []}) => Process.runSync(
    '/bin/sh',
    ['${project.path}/tool/xcode_dart_defines.sh'],
    environment: {
      'PATH': Platform.environment['PATH'] ?? '/usr/bin:/bin',
      'CONFIGURATION': configuration,
      if (defines.isNotEmpty) 'DART_DEFINES': encode(defines),
    },
    includeParentEnvironment: false,
  );

  List<String> definesFrom(ProcessResult result) {
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final out = result.stdout as String;
    return out.isEmpty ? [] : out.split(',').map((d) => utf8.decode(base64.decode(d))).toList();
  }

  const keys = '''
{
  "TRAVARY_REVENUECAT_IOS_KEY": "appl_publicKey",
  "TRAVARY_REVENUECAT_ANDROID_KEY": "goog_publicKey",
  "TRAVARY_REVENUECAT_OFFERING": "onboarding"
}
''';

  test('a Release build with no defines takes the keys file and flight lookup', () {
    writeKeys(keys);
    expect(definesFrom(run(configuration: 'Release')), [
      'TRAVARY_REVENUECAT_IOS_KEY=appl_publicKey',
      'TRAVARY_REVENUECAT_OFFERING=onboarding',
      'TRAVARY_FLIGHT_LOOKUP=true',
    ]);
  });

  test("tool/build_release.sh's defines are kept exactly", () {
    writeKeys(keys);
    const passed = [
      'TRAVARY_REVENUECAT_IOS_KEY=appl_fromTheCommandLine',
      'TRAVARY_REVENUECAT_ANDROID_KEY=goog_publicKey',
      'TRAVARY_FLIGHT_LOOKUP=false',
    ];
    final result = run(configuration: 'Release', defines: passed);
    expect(result.stdout, encode(passed));
  });

  test('other defines stay and the offering is optional', () {
    writeKeys('{"TRAVARY_REVENUECAT_IOS_KEY": "appl_publicKey"}');
    expect(definesFrom(run(configuration: 'Release', defines: ['TRAVARY_EMAIL_LINKS=true'])), [
      'TRAVARY_EMAIL_LINKS=true',
      'TRAVARY_REVENUECAT_IOS_KEY=appl_publicKey',
      'TRAVARY_FLIGHT_LOOKUP=true',
    ]);
  });

  test('a Release build without the keys fails, not the app on the phone', () {
    final missing = run(configuration: 'Release');
    expect(missing.exitCode, isNot(0));
    expect(missing.stderr, contains('error: config/revenuecat.local.json is missing'));

    writeKeys('{"TRAVARY_REVENUECAT_IOS_KEY": "goog_wrongPlatform"}');
    final wrong = run(configuration: 'Release');
    expect(wrong.exitCode, isNot(0));
    expect(wrong.stderr, contains('no iOS key'));
  });

  test('demo builds need no keys, and Debug builds are left alone', () {
    expect(definesFrom(run(configuration: 'Release', defines: ['TRAVARY_BACKEND=demo'])), [
      'TRAVARY_BACKEND=demo',
      'TRAVARY_FLIGHT_LOOKUP=true',
    ]);
    expect(definesFrom(run(configuration: 'Debug', defines: ['A=1'])), ['A=1']);
    expect(definesFrom(run(configuration: 'Debug')), isEmpty);
  });

  test("the Runner's Flutter build phase uses it", () {
    final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final phase = RegExp(r'/\* Run Script \*/ = \{.*?shellScript = "(.*?)";\n', dotAll: true).firstMatch(pbxproj)!;
    final script = phase.group(1)!;
    final defines = script.indexOf(r'DART_DEFINES=\"$(/bin/sh \"$SRCROOT/../tool/xcode_dart_defines.sh\")\" || exit 1');
    final build = script.indexOf(r'xcode_backend.sh\" build');
    expect(defines, isNot(-1));
    expect(script, contains('export DART_DEFINES'));
    expect(build, greaterThan(defines));
  });
}
