import 'package:firebase_core/firebase_core.dart';

/// Manually created Firebase options for Android, based on google-services.json.
///
/// This avoids the need for the Google Services Gradle plugin to generate
/// resources and fixes the `Failed to load FirebaseOptions from resource`
/// error you were seeing.
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDITGPZING5HtX7g6lVHPpNSwlc-VlNjmc',
    appId: '1:975125387984:android:6621aeb7a5d06006715cd5',
    messagingSenderId: '975125387984',
    projectId: 'uniplan-b3fcf',
    databaseURL:
        'https://uniplan-b3fcf-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'uniplan-b3fcf.firebasestorage.app',
  );
}

