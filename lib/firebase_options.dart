import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// PLACEHOLDER Firebase configuration.
///
/// TO CONFIGURE FIREBASE:
/// 1. Install FlutterFire CLI: dart pub global activate flutterfire_cli
/// 2. Run: flutterfire configure
/// 3. This file will be automatically regenerated with your project's config
///
/// The configuration below is a placeholder and WILL NOT WORK until you
/// run the FlutterFire CLI to connect to your Firebase project.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'run flutterfire configure to generate your firebase_options.dart file.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'run flutterfire configure to generate your firebase_options.dart file.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'run flutterfire configure to generate your firebase_options.dart file.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'run flutterfire configure to generate your firebase_options.dart file.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // PLACEHOLDER - Replace with your actual Firebase configuration

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC3D-gCpxjNAD-YabJ9gL8BfuRpkMRlPcU',
    appId: '1:315160115482:android:31153bef83b05617e9d4a3',
    messagingSenderId: '315160115482',
    projectId: 'travary-444',
    storageBucket: 'travary-444.firebasestorage.app',
  );

  // Run: flutterfire configure

  // PLACEHOLDER - Replace with your actual Firebase configuration

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBjKJlX6lVvXci11xDDe4frRJ0fp4gDLNc',
    appId: '1:315160115482:ios:f79aacf627ea203fe9d4a3',
    messagingSenderId: '315160115482',
    projectId: 'travary-444',
    storageBucket: 'travary-444.firebasestorage.app',
    iosClientId: '315160115482-tlba7grafhm1vqfbfess7bi8il4jb02m.apps.googleusercontent.com',
    iosBundleId: 'com.travary.travaryTemp',
  );

  // Run: flutterfire configure
}