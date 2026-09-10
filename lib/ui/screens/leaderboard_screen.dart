import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/firestore_repository.dart';

final leaderboardProvider = StreamProvider((ref) {
  return ref.watch(firestoreRepositoryProvider).watchLeaderboard();
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classifica (Leaderboard)'),
      ),
      body: leaderboardAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Nessun utente registrato.'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              // Medaglie
              String medal = '';
              if (index == 0 && user.points > 0) {
                medal = '🥇';
              } else if (index == 1 && user.points > 0) {
                medal = '🥈';
              } else if (index == 2 && user.points > 0) {
                medal = '🥉';
              } else if (index == users.length - 1 && user.points == 0) {
                medal = '🪵'; // Ultimo posto a 0 punti
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  child: user.avatarUrl == null ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?') : null,
                ),
                title: Row(
                  children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (medal.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(medal, style: const TextStyle(fontSize: 20)),
                    ]
                  ],
                ),
                subtitle: Text('${user.points} Punti'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥 ', style: TextStyle(fontSize: 18)),
                    Text(user.streak.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Errore: $err')),
      ),
    );
  }
}
