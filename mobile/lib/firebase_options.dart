// PLACEHOLDER — regenerate this file once you have a Firebase project.
//
// 1. Create a project at https://console.firebase.google.com
// 2. Install the CLI: `dart pub global activate flutterfire_cli`
// 3. From the `mobile/` directory, run: `flutterfire configure`
//    This overwrites this file with your project's real keys and wires up
//    the native Android/iOS config automatically (no manual Gradle edits
//    needed).
//
// Until then, push notifications silently no-op (see push_service.dart) —
// the rest of the app works normally with these placeholder values.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return android;
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'placeholder',
    appId: 'placeholder',
    messagingSenderId: 'placeholder',
    projectId: 'placeholder',
  );

  static const android = FirebaseOptions(
    apiKey: 'placeholder',
    appId: 'placeholder',
    messagingSenderId: 'placeholder',
    projectId: 'placeholder',
  );

  static const ios = FirebaseOptions(
    apiKey: 'placeholder',
    appId: 'placeholder',
    messagingSenderId: 'placeholder',
    projectId: 'placeholder',
    iosBundleId: 'com.gmaoleger.gmaoMobile',
  );
}
