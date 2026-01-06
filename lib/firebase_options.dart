// PLACEHOLDER FILE - REPLACE WITH ACTUAL FIREBASE CONFIGURATION
//
// This file needs to be generated using the FlutterFire CLI.
// Run the following command in your terminal:
//
//   flutterfire configure
//
// This will:
// 1. Link your Flutter app to your Firebase project
// 2. Generate the proper Firebase configuration for all platforms
// 3. Replace this placeholder file with the actual configuration
//
// For detailed instructions, see FIREBASE_SETUP.md
//
// DO NOT manually edit this file - it will be overwritten by flutterfire configure.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you must run flutterfire configure to generate firebase_options.dart',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you must run flutterfire configure to generate firebase_options.dart',
        );
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you must run flutterfire configure to generate firebase_options.dart',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you must run flutterfire configure to generate firebase_options.dart',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you must run flutterfire configure to generate firebase_options.dart',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBIb80d0nsA3eG5VO5HDWzu6zcse3g9HEA',
    appId: '1:772845694568:ios:b935125403f5d3f93fd5dd',
    messagingSenderId: '772845694568',
    projectId: 'panci-canvas-2a7dc',
    storageBucket: 'panci-canvas-2a7dc.firebasestorage.app',
    iosBundleId: 'com.example.panci',
  );

}