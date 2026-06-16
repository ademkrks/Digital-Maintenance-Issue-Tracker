import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Under normal circumstances, you should run `flutterfire configure` to generate this file.
/// However, we have pre-defined this boilerplate to ensure compilation is successful.
/// Update these placeholders with your actual Firebase project credentials to connect.
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
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC84Hj_79h6-wtR7vHArVlrRvgKCmwKBEY',
    appId: '1:24215592829:web:cddb4824624debba5eb614',
    messagingSenderId: '24215592829',
    projectId: 'digital-maintenance-tracker',
    authDomain: 'digital-maintenance-tracker.firebaseapp.com',
    storageBucket: 'digital-maintenance-tracker.firebasestorage.app',
    measurementId: 'G-Q5H71GLFJL',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAfBN55-2Z9B5srbkx3DehNRTMRKWbp3Xc',
    appId: '1:24215592829:android:b10cef7d283ff5935eb614',
    messagingSenderId: '24215592829',
    projectId: 'digital-maintenance-tracker',
    storageBucket: 'digital-maintenance-tracker.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA0yD38dM7Ul9kvWW7nGAgi4RknlS-122M',
    appId: '1:24215592829:ios:d48542eb493dbcba5eb614',
    messagingSenderId: '24215592829',
    projectId: 'digital-maintenance-tracker',
    storageBucket: 'digital-maintenance-tracker.firebasestorage.app',
    iosBundleId: 'com.tracker.digitalMaintenanceTracker',
  );
}
