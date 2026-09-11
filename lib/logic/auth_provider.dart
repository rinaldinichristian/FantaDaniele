import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authControllerProvider = Provider((ref) => AuthController());

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // L'utente ha annullato il login

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Salva il profilo dell'utente su Firestore al primo accesso
      final user = userCredential.user;
      if (user != null) {
        // Richiedi i permessi per le notifiche e ottieni il token FCM
        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission();
        final fcmToken = await messaging.getToken();

        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          // Se è il primissimo utente di tutto il database, lo facciamo Admin
          final usersCount = await _firestore.collection('users').count().get();
          final isFirst = usersCount.count == 0;

          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? 'Utente Sconosciuto',
            'avatarUrl': user.photoURL,
            'points': 0,
            'streak': 0,
            'isAdmin': isFirst,
            'isDaniele': false,
            'fcmToken': fcmToken,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Aggiorna il token se già esiste
          await _firestore.collection('users').doc(user.uid).update({'fcmToken': fcmToken});
        }
      }
    } catch (e) {
      print('Errore durante il login con Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
