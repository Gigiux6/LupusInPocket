import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleSignInInitialized = false;

  User? get currentUser => _auth.currentUser;

  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (kIsWeb) return;
    if (!_googleSignInInitialized) {
      try {
        await GoogleSignIn.instance.initialize();
        _googleSignInInitialized = true;
      } catch (e) {
        debugPrint('Errore durante l\'inizializzazione di GoogleSignIn: $e');
      }
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return credential.user;
    } catch (e) {
      debugPrint('Errore signInAnonymously: $e');
      throw 'Errore durante l\'accesso anonimo: $e';
    }
  }

  Future<User?> linkWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'Nessun utente attualmente autenticato.';
    }

    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({
          'prompt': 'select_account'
        });
        final UserCredential userCredential = await user.linkWithPopup(googleProvider);
        return userCredential.user;
      } else {
        await _ensureGoogleSignInInitialized();
        final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
        if (googleUser == null) {
          return null; // Collegamento annullato dall'utente
        }

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await user.linkWithCredential(credential);
        return userCredential.user;
      }
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('FirebaseAuthException in linkWithGoogle: ${e.code} - ${e.message}\n$stackTrace');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Errore generico in linkWithGoogle: $e\n$stackTrace');
      throw 'Errore generico durante il collegamento Google: $e';
    }
  }

  Future<User?> linkWithProviderCredential(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'Nessun utente attualmente autenticato.';
    }
    try {
      final UserCredential userCredential = await user.linkWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException in linkWithProviderCredential: ${e.code} - ${e.message}');
      if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
        throw 'Questo account è già associato a un altro utente. Impossibile collegarlo.';
      } else if (e.code == 'provider-already-linked') {
        throw 'Questo profilo è già collegato ad un account con lo stesso provider.';
      } else {
        throw 'Errore durante il collegamento: ${e.message}';
      }
    } catch (e) {
      debugPrint('Errore generico in linkWithProviderCredential: $e');
      throw 'Errore generico durante il collegamento: $e';
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({
          'prompt': 'select_account'
        });
        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        return userCredential.user;
      } else {
        await _ensureGoogleSignInInitialized();
        final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
        if (googleUser == null) {
          return null; // Sign-in annullato dall'utente
        }

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } catch (e) {
      debugPrint('Errore in signInWithGoogle: $e');
      throw 'Errore durante l\'accesso con Google: $e';
    }
  }

  Future<dynamic> getGoogleCredential() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        return googleProvider;
      } else {
        await _ensureGoogleSignInInitialized();
        final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        return GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
      }
    } catch (e) {
      debugPrint('Errore in getGoogleCredential: $e');
      throw 'Errore durante l\'ottenimento delle credenziali Google: $e';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _ensureGoogleSignInInitialized();
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (e) {
        debugPrint('Errore durante GoogleSignIn disconnect: $e. Fallback a signOut semplice.');
        try {
          await GoogleSignIn.instance.signOut();
        } catch (signOutError) {
          debugPrint('Errore anche durante GoogleSignIn signOut: $signOutError');
        }
      }
    }
  }
}
