// Firebase client configuration. Android is registered for the research
// project; web and iOS retain placeholders because they are outside the
// evaluated platform. Regenerate platform configuration by running:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=reading-app-10118
//
// Firebase client identifiers are not administrative credentials. Security
// is enforced by Authentication, App Check, and the deployed Firestore rules.

// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform. '
          'Run `flutterfire configure` to generate real options for it.',
        );
    }
  }

  // PLACEHOLDER VALUES — replace via `flutterfire configure --project=reading_app`
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'reading_app',
    authDomain: 'reading-app.firebaseapp.com',
    storageBucket: 'reading-app.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCKaimBvmeZdZOnOWQb9-4SIZ6gX2QDKLg',
    appId: '1:126758321312:android:a449ee414a494dc2d2ddc5',
    messagingSenderId: '126758321312',
    projectId: 'reading-app-10118',
    storageBucket: 'reading-app-10118.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'reading_app',
    storageBucket: 'reading-app.appspot.com',
    iosBundleId: 'com.example.readingAssistantApp',
  );
}
