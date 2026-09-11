import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/bet.dart';
import '../models/daily_session.dart';
import '../models/app_user.dart';
import '../models/app_settings.dart';

final firestoreRepositoryProvider = Provider((ref) => FirestoreRepository());

class FirestoreRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // L'ID della sessione è la data odierna formattata (es: "2026-09-10")
  String get _todayId => DateFormat('yyyy-MM-dd').format(DateTime.now());

    // ----------------------------------------
  // IMPOSTAZIONI GLOBALI
  // ----------------------------------------
  Stream<AppSettings> watchSettings() {
    return _db.collection('fd_settings').doc('global').snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return AppSettings();
      return AppSettings.fromMap(doc.data()!);
    });
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _db.collection('fd_settings').doc('global').set(settings.toMap(), SetOptions(merge: true));
  }

  // ----------------------------------------
  // UTENTI E LEADERBOARD
  // ----------------------------------------
  Stream<List<AppUser>> watchLeaderboard() {
    return _db
        .collection('fd_users')
        .orderBy('points', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> resetAllStreaks() async {
    final users = await _db.collection('fd_users').get();
    for (var u in users.docs) {
      await _db.collection('fd_users').doc(u.id).update({'streak': 0});
    }
  }

  Future<void> updateUserPoints(String userId, int points) async {
    await _db.collection('fd_users').doc(userId).update({'points': points});
  }

  Future<void> updateUserRoles(String userId, {bool? isAdmin, bool? isDaniele, String? name, String? avatarUrl}) async {
    final data = <String, dynamic>{};
    if (isAdmin != null) data['isAdmin'] = isAdmin;
    if (isDaniele != null) data['isDaniele'] = isDaniele;
    if (name != null) data['name'] = name;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (data.isNotEmpty) {
      await _db.collection('fd_users').doc(userId).update(data);
    }
  }

  // ----------------------------------------
  // SESSIONE GIORNALIERA
  // ----------------------------------------
  Stream<DailySession> watchTodaySession() {
    return _db.collection('fd_sessions').doc(_todayId).snapshots().map((doc) {
      if (!doc.exists) {
        // Se non esiste, assumiamo che le scommesse siano aperte di default
        return DailySession(id: _todayId, isOpen: true);
      }
      return DailySession.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> setSessionState(bool isOpen) async {
    await _db.collection('fd_sessions').doc(_todayId).set({
      'isOpen': isOpen,
    }, SetOptions(merge: true));
  }

  Future<void> endSession(int actualHour, int actualMinute, {String? proofImageUrl}) async {
    final sessionRef = _db.collection('fd_sessions').doc(_todayId);
    
    await sessionRef.set({
      'isOpen': false,
      'arrivalHour': actualHour,
      'arrivalMinute': actualMinute,
      if (proofImageUrl != null) 'proofImageUrl': proofImageUrl,
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

    if (minDiff == 0 && winnerId != null) {
      await sessionRef.set({'winnerId': winnerId}, SetOptions(merge: true));
    } else {
      // Nessuno ha indovinato l'orario esatto. Trova Daniele e dagli il punto.
      final usersSnap = await _db.collection('fd_users').where('isDaniele', isEqualTo: true).get();
      if (usersSnap.docs.isNotEmpty) {
        winnerId = usersSnap.docs.first.id;
        await sessionRef.set({'winnerId': winnerId, 'danieleWon': true}, SetOptions(merge: true));
      }
    }

    // Aggiorna punteggi e streak per tutti
    final allUsersSnap = await _db.collection('fd_users').get();
    for (var doc in allUsersSnap.docs) {
      final userId = doc.id;
      final isWinner = (userId == winnerId);
      final userRef = _db.collection('fd_users').doc(userId);
      
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

  // ----------------------------------------
  // SCOMMESSE (BETS)
  // ----------------------------------------
  Stream<List<Bet>> watchTodayBets() {
    return _db
        .collection('fd_sessions')
        .doc(_todayId)
        .collection('bets')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Bet.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> placeBet({required String userId, required String userName, required int hour, required int minute}) async {
    final sessionDoc = await _db.collection('fd_sessions').doc(_todayId).get();
    if (sessionDoc.exists && sessionDoc.data()?['isOpen'] == false) {
      throw Exception('Le scommesse per oggi sono chiuse!');
    }

    final betRef = _db.collection('fd_sessions').doc(_todayId).collection('bets').doc(userId);
    
    final betDoc = await betRef.get();
    if (betDoc.exists) {
      throw Exception('Hai già piazzato la tua scommessa per oggi!');
    }
    
        // In futuro: validazione sulla vicinanza dell'orario con altre scommesse.
    final todayBets = await _db.collection('fd_sessions').doc(_todayId).collection('bets').get();
    for (var d in todayBets.docs) {
      if (d.data()['hour'] == hour && d.data()['minute'] == minute) {
        throw Exception('Orario già inserito! Il primo che arriva decide, scegline un altro.');
      }
    }


    await betRef.set({
      'userId': userId,
      'userName': userName,
      'hour': hour,
      'minute': minute,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ----------------------------------------
  // CHAT
  // ----------------------------------------
  Stream<List<ChatMessage>> watchChatMessages() {
    return _db
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> sendMessage({required String userId, required String userName, required String text, String? imageUrl}) async {
    final data = <String, dynamic>{
      'userId': userId,
      'userName': userName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };
    if (imageUrl != null) {
      data['imageUrl'] = imageUrl;
    }
    await _db.collection('chat').add(data);
  }
}
