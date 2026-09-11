import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../logic/auth_provider.dart';
import '../../logic/firestore_repository.dart';
import '../../services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'leaderboard_screen.dart';
import '../../logic/weather_provider.dart';

// Providers per gli stream della dashboard
final todaySessionProvider = StreamProvider((ref) {
  return ref.watch(firestoreRepositoryProvider).watchTodaySession();
});

final todayBetsProvider = StreamProvider((ref) {
  return ref.watch(firestoreRepositoryProvider).watchTodayBets();
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
    });
  }

  final _packageInfoFuture = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(todaySessionProvider);
    final betsAsync = ref.watch(todayBetsProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FantaDaniele'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => context.push('/rules'),
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => context.push('/chat'),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => context.push('/leaderboard'),
          ),
          // We must check if the user is admin. Since leaderboardProvider might still be loading,
          // we'll conditionally show the button if they are admin in the leaderboard.
          if ((ref.watch(leaderboardProvider).value ?? []).where((u) => u.id == user?.uid).firstOrNull?.isAdmin ?? false)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => context.push('/admin'),
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
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
      body: FutureBuilder<PackageInfo>(
        future: _packageInfoFuture,
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '1.0.0';
          final body = Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

            // Widget Meteo (Brescia via Open-Meteo)
            ref.watch(weatherProvider).when(
              data: (weather) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        weather.weatherCode == 0 ? Icons.wb_sunny : Icons.cloud,
                        color: weather.weatherCode == 0 ? Colors.orange : Colors.grey,
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      Text('${weather.description}, ${weather.temperature}°C', style: const TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => const SizedBox(),
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
                  ],
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
                  final leaderboard = ref.watch(leaderboardProvider).value ?? [];
                  final appUser = leaderboard.where((u) => u.id == user?.uid).firstOrNull;
                  final isDaniele = appUser?.isDaniele ?? false;

                  if (isDaniele) {
                    return const Center(
                      child: Text(
                        'Le scommesse sono nascoste per te, Daniele! 😉',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
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
      );

        
        return ClipRect(
          child: Banner(
            message: 'v$version',
            location: BannerLocation.topStart,
            child: body,
          ),
        );
      },
      ),
    );
  }
}
