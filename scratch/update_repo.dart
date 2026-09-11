import 'dart:io';

void main() {
  final file = File('lib/logic/firestore_repository.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "import '../models/app_user.dart';",
    "import '../models/app_user.dart';\nimport '../models/app_settings.dart';"
  );

  content = content.replaceFirst(
    "Future<void> endSession(int actualHour, int actualMinute) async {",
    "Future<void> endSession(int actualHour, int actualMinute, {String? proofImageUrl}) async {"
  );

  content = content.replaceFirst(
    "'arrivalMinute': actualMinute,",
    "'arrivalMinute': actualMinute,\n      if (proofImageUrl != null) 'proofImageUrl': proofImageUrl,"
  );

  // endSession logic: 
  final oldEndSession = '''
    if (winnerId != null) {
      await sessionRef.set({'winnerId': winnerId}, SetOptions(merge: true));

      for (var doc in betsSnapshot.docs) {
        final betUserId = doc.id;
        final isWinner = (betUserId == winnerId);
        final userRef = _db.collection('fd_users').doc(betUserId);
        
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
''';

  final newEndSession = '''
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
''';

  content = content.replaceFirst(oldEndSession, newEndSession);

  final duplicateCheck = '''
    // In futuro: validazione sulla vicinanza dell'orario con altre scommesse.
    final todayBets = await _db.collection('fd_sessions').doc(_todayId).collection('bets').get();
    for (var d in todayBets.docs) {
      if (d.data()['hour'] == hour && d.data()['minute'] == minute) {
        throw Exception('Orario già inserito! Il primo che arriva decide, scegline un altro.');
      }
    }
''';
  content = content.replaceFirst("// In futuro: validazione sulla vicinanza dell'orario con altre scommesse.", duplicateCheck);

  final settingsCode = '''
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
''';

  content = content.replaceFirst("// ----------------------------------------\n  // UTENTI E LEADERBOARD", settingsCode + "\n  // ----------------------------------------\n  // UTENTI E LEADERBOARD");

  file.writeAsStringSync(content);
}
