import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions no está configurado para web. '
        'Registra la app web en Firebase Console.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está disponible para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCZKASFmGIz6XM5nNPAP6xhRM06XDPGsDE',
    appId: '1:789106628921:android:5440d5721773e85c6cb0e8',
    messagingSenderId: '789106628921',
    projectId: 'renova-8c366',
    storageBucket: 'renova-8c366.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCYVlg2SP4t4JxfpepjY-iUhekYkmpzh6Y',
    appId: '1:789106628921:ios:2004d0d9f55435f36cb0e8',
    messagingSenderId: '789106628921',
    projectId: 'renova-8c366',
    storageBucket: 'renova-8c366.firebasestorage.app',
    iosBundleId: 'com.example.renova1',
  );

  // macOS usa la misma configuración que iOS (mismo bundle ID, mismo proyecto)
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCYVlg2SP4t4JxfpepjY-iUhekYkmpzh6Y',
    appId: '1:789106628921:ios:2004d0d9f55435f36cb0e8',
    messagingSenderId: '789106628921',
    projectId: 'renova-8c366',
    storageBucket: 'renova-8c366.firebasestorage.app',
    iosBundleId: 'com.example.renova1',
  );
}
