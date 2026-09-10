import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../logic/auth_provider.dart';
import '../../logic/firestore_repository.dart';

// Providers per gli stream della dashboard
final todaySessionProvider = StreamProvider((ref) {
  return ref.watch(firestoreRepositoryProvider).watchTodaySession();
});

final todayBetsProvider = StreamProvider((ref) {
  return ref.watch(firestoreRepositoryProvider).watchTodayBets();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(todaySessionProvider);
    final betsAsync = ref.watch(todayBetsProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FantaDaniele'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => context.push('/leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.gavel),
            onPressed: () => context.push('/admin'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider).signOut();
              context.go('/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Widget Meteo (Placeholder)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wb_sunny, color: Colors.orange, size: 40),
                    const SizedBox(width: 16),
                    const Text('Sole, 22°C', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sezione Scommessa
            sessionAsync.when(
              data: (session) {
                if (!session.isOpen) {
                  return const Center(
                    child: Text('Scommesse chiuse per oggi! 🛑',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                  );
                }

                return Column(
                  children: [
                    const Text('Piazza la tua scommessa:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (user == null) return;

                        final time = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 10, minute: 30),
                        );

                        if (time != null && context.mounted) {
                          try {
                            await ref.read(firestoreRepositoryProvider).placeBet(
                                  userId: user.uid,
                                  userName: user.displayName ?? 'Utente',
                                  hour: time.hour,
                                  minute: time.minute,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Scommessa salvata: ${time.format(context)}')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: const Text("Scegli Orario d'Arrivo"),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                    ),
                  ];
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Errore sessione: $err')),
            ),

            const SizedBox(height: 32),
            const Text('Scommesse di oggi:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Lista Scommesse (Real-time da Firestore)
            Expanded(
              child: betsAsync.when(
                data: (bets) {
                  if (bets.isEmpty) {
                    return const Center(child: Text('Nessuna scommessa piazzata oggi.'));
                  }
                  return ListView.builder(
                    itemCount: bets.length,
                    itemBuilder: (context, index) {
                      final bet = bets[index];
                      final timeString = '${bet.time.hour.toString().padLeft(2, '0')}:${bet.time.minute.toString().padLeft(2, '0')}';
                      final initial = bet.userName.isNotEmpty ? bet.userName[0].toUpperCase() : '?';

                      return ListTile(
                        leading: CircleAvatar(child: Text(initial)),
                        title: Text(bet.userName),
                        trailing: Text(timeString, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Errore caricamento: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
