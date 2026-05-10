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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Sostituisci "INSERISCI_API_KEY_QUI" e gli App ID con i valori reali
  // dalla tua Firebase Console -> Impostazioni Progetto -> Generali
  
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBwNowDmuA8NZ791POXpD_Y5e9kKK4iWFk',
    appId: '1:248731957793:web:7a817448e89f899e53c160', // Note: This should ideally be verified from console for web
    messagingSenderId: '248731957793',
    projectId: 'lupus-in-pocket',
    authDomain: 'lupus-in-pocket.firebaseapp.com',
    databaseURL: 'https://lupus-in-pocket-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'lupus-in-pocket.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBwNowDmuA8NZ791POXpD_Y5e9kKK4iWFk',
    appId: '1:248731957793:android:b6ef4d39af1683a053c160',
    messagingSenderId: '248731957793',
    projectId: 'lupus-in-pocket',
    databaseURL: 'https://lupus-in-pocket-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'lupus-in-pocket.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBwNowDmuA8NZ791POXpD_Y5e9kKK4iWFk',
    appId: '1:248731957793:ios:6677f4e8b89e899e53c160', // Generic placeholder, needs manual check
    messagingSenderId: '248731957793',
    projectId: 'lupus-in-pocket',
    databaseURL: 'https://lupus-in-pocket-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'lupus-in-pocket.firebasestorage.app',
    iosBundleId: 'com.gigiux.lupus_in_pocket',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBwNowDmuA8NZ791POXpD_Y5e9kKK4iWFk',
    appId: '1:248731957793:ios:6677f4e8b89e899e53c160',
    messagingSenderId: '248731957793',
    projectId: 'lupus-in-pocket',
    databaseURL: 'https://lupus-in-pocket-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'lupus-in-pocket.firebasestorage.app',
    iosBundleId: 'com.gigiux.lupus_in_pocket',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBwNowDmuA8NZ791POXpD_Y5e9kKK4iWFk',
    appId: '1:248731957793:web:7a817448e89f899e53c160',
    messagingSenderId: '248731957793',
    projectId: 'lupus-in-pocket',
    authDomain: 'lupus-in-pocket.firebaseapp.com',
    databaseURL: 'https://lupus-in-pocket-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'lupus-in-pocket.firebasestorage.app',
  );
}
