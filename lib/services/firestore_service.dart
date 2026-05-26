import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crea un profilo utente iniziale su Firestore con i campi specificati.
  Future<void> createUserProfile({
    required String uid,
    required String username,
    String? email,
    required String photoUrl,
  }) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      await docRef.set({
        'username': username,
        'email': email ?? '',
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'gamesWon': 0,
      });
      debugPrint('Firestore: Profilo creato con successo per uid: $uid');
    } catch (e) {
      debugPrint('Firestore: Errore nella creazione del profilo: $e');
      rethrow;
    }
  }

  /// Aggiorna campi specifici del profilo utente su Firestore.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      await docRef.update(data);
      debugPrint('Firestore: Profilo aggiornato con successo per uid: $uid');
    } catch (e) {
      debugPrint('Firestore: Errore nell\'aggiornamento del profilo: $e');
      rethrow;
    }
  }

  /// Recupera il profilo utente su Firestore. Ritorna null se non esiste.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Firestore: Errore nel recupero del profilo: $e');
      rethrow;
    }
  }

  /// Incrementa il conteggio dei giochi vinti (gamesWon) in modo atomico.
  Future<void> incrementGamesWon(String uid) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          final current = snapshot.data()?['gamesWon'] ?? 0;
          transaction.update(docRef, {'gamesWon': current + 1});
        } else {
          transaction.set(docRef, {
            'gamesWon': 1,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });
      debugPrint('Firestore: Conteggio gamesWon incrementato per uid: $uid');
    } catch (e) {
      debugPrint('Firestore: Errore nell\'incremento dei giochi vinti: $e');
      rethrow;
    }
  }
}
