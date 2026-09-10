import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/bet.dart';
import '../models/daily_session.dart';
import '../models/app_user.dart';

final firestoreRepositoryProvider = Provider((ref) => FirestoreRepository());

class FirestoreRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // L'ID della sessione è la data odierna formattata (es: "2026-09-10")
  String get _todayId => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // ----------------------------------------
  // UTENTI E LEADERBOARD
  // ----------------------------------------
  Stream<List<AppUser>> watchLeaderboard() {
    return _db
        .collection('users')
        .orderBy('points', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ----------------------------------------
  // SESSIONE GIORNALIERA
  // ----------------------------------------
  Stream<DailySession> watchTodaySession() {
    return _db.collection('sessions').doc(_todayId).snapshots().map((doc) {
      if (!doc.exists) {
        // Se non esiste, assumiamo che le scommesse siano aperte di default
        return DailySession(id: _todayId, isOpen: true);
      }
      return DailySession.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> setSessionState(bool isOpen) async {
    await _db.collection('sessions').doc(_todayId).set({
      'isOpen': isOpen,
    }, SetOptions(merge: true));
  }

  // ----------------------------------------
  // SCOMMESSE (BETS)
  // ----------------------------------------
  Stream<List<Bet>> watchTodayBets() {
    return _db
        .collection('sessions')
        .doc(_todayId)
        .collection('bets')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Bet.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> placeBet({required String userId, required String userName, required int hour, required int minute}) async {
    final sessionDoc = await _db.collection('sessions').doc(_todayId).get();
    if (sessionDoc.exists && sessionDoc.data()?['isOpen'] == false) {
      throw Exception('Le scommesse per oggi sono chiuse!');
    }

    final betRef = _db.collection('sessions').doc(_todayId).collection('bets').doc(userId);
    
    final betDoc = await betRef.get();
    if (betDoc.exists) {
      throw Exception('Hai già piazzato la tua scommessa per oggi!');
    }
    
    // In futuro: validazione sulla vicinanza dell'orario con altre scommesse.

    await betRef.set({
      'userId': userId,
      'userName': userName,
      'hour': hour,
      'minute': minute,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
