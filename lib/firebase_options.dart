// File generated from Firebase config files (google-services.json / GoogleService-Info.plist)
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAm_RmJ67GGeLuZEjJw1uWSCZ53Ljxdhfo',
    appId: '1:407637819858:android:041983940e43dfc0b2080b',
    messagingSenderId: '407637819858',
    projectId: 'tiny-log',
    storageBucket: 'tiny-log.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAI9iIdVbiW8cJyRvk8_2prJFMUTE1OkLI',
    appId: '1:407637819858:ios:207262f3e2152c25b2080b',
    messagingSenderId: '407637819858',
    projectId: 'tiny-log',
    storageBucket: 'tiny-log.firebasestorage.app',
    iosBundleId: 'com.studiovanilla.tinylog',
  );
}
