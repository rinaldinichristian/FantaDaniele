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

  Future<void> endSession(int actualHour, int actualMinute) async {
    final sessionRef = _db.collection('sessions').doc(_todayId);
    
    await sessionRef.set({
      'isOpen': false,
      'arrivalHour': actualHour,
      'arrivalMinute': actualMinute,
    }, SetOptions(merge: true));

    final betsSnapshot = await sessionRef.collection('bets').get();
    if (betsSnapshot.docs.isEmpty) return;

    final actualTotalMinutes = actualHour * 60 + actualMinute;

    String? winnerId;
    int minDiff = 999999;

    for (var doc in betsSnapshot.docs) {
      final bet = Bet.fromMap(doc.id, doc.data());
      final betTotalMinutes = bet.time.hour * 60 + bet.time.minute;
      final diff = (actualTotalMinutes - betTotalMinutes).abs();

      if (diff < minDiff) {
        minDiff = diff;
        winnerId = bet.userId;
      }
    }

    if (winnerId != null) {
      await sessionRef.set({'winnerId': winnerId}, SetOptions(merge: true));

      for (var doc in betsSnapshot.docs) {
        final betUserId = doc.id;
        final isWinner = (betUserId == winnerId);
        final userRef = _db.collection('users').doc(betUserId);
        
        await _db.runTransaction((transaction) async {
          final userSnap = await transaction.get(userRef);
          if (userSnap.exists) {
            int currentPoints = userSnap.data()?['points']?.toInt() ?? 0;
            int currentStreak = userSnap.data()?['streak']?.toInt() ?? 0;

            if (isWinner) {
              transaction.update(userRef, {
                'points': currentPoints + 1,
                'streak': currentStreak + 1,
              });
            } else {
              transaction.update(userRef, {
                'streak': 0,
              });
            }
          }
        });
      }
    }
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
