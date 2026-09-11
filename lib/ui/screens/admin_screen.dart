import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/firestore_repository.dart';
import '../../models/app_user.dart';
import 'leaderboard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pannello Admin'),
          backgroundColor: Colors.red,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Utenti'),
              Tab(icon: Icon(Icons.timer), text: 'Sessione'),
              Tab(icon: Icon(Icons.notifications), text: 'Avvisi'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UsersAdminTab(),
            _SessionAdminTab(),
            _SessionSettingsTab(),
          ],
        ),
      ),
    );
  }
}
class _UsersAdminTab extends ConsumerWidget {
  const _UsersAdminTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(leaderboardProvider); // Requires a provider in logic
    return usersAsync.when(
      data: (users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null),
            title: Text(user.name),
            subtitle: Text('Punti: ${user.points} | Streak: ${user.streak}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.star, color: user.isAdmin ? Colors.amber : Colors.grey),
                  onPressed: () => ref.read(firestoreRepositoryProvider).updateUserRoles(user.id, isAdmin: !user.isAdmin),
                  tooltip: 'Admin',
                ),
                IconButton(
                  icon: Icon(Icons.person_off, color: user.isDaniele ? Colors.red : Colors.grey),
                  onPressed: () => ref.read(firestoreRepositoryProvider).updateUserRoles(user.id, isDaniele: !user.isDaniele),
                  tooltip: 'Daniele',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editPoints(context, ref, user),
                  tooltip: 'Modifica Punti',
                ),
              ],
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Errore: $e')),
    );
  }

  void _editPoints(BuildContext context, WidgetRef ref, AppUser user) {
    final ctrl = TextEditingController(text: user.points.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifica Punti di ${user.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Nuovi Punti'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          TextButton(
            onPressed: () {
              final pts = int.tryParse(ctrl.text) ?? user.points;
              ref.read(firestoreRepositoryProvider).updateUserPoints(user.id, pts);
              Navigator.pop(ctx);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}
class _SessionAdminTab extends ConsumerStatefulWidget {
  const _SessionAdminTab();
  @override
  ConsumerState<_SessionAdminTab> createState() => _SessionAdminTabState();
}

class _SessionAdminTabState extends ConsumerState<_SessionAdminTab> {
  TimeOfDay? _arrivalTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          const Text('Orario di arrivo di Daniele', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                setState(() => _arrivalTime = time);
              }
            },
            child: Text(_arrivalTime != null ? _arrivalTime!.format(context) : 'Seleziona Orario'),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Chiudi Scommesse e Calcola Punti'),
            onPressed: _arrivalTime == null
                ? null
                : () async {
                    await ref.read(firestoreRepositoryProvider).endSession(
                          _arrivalTime!.hour,
                          _arrivalTime!.minute,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sessione chiusa!')));
                    }
                  },
          ),
        ],
      ),
    );
  }
}
class _SessionSettingsTab extends ConsumerStatefulWidget {
  const _SessionSettingsTab();
  @override
  ConsumerState<_SessionSettingsTab> createState() => _SessionSettingsTabState();
}

class _SessionSettingsTabState extends ConsumerState<_SessionSettingsTab> {
  TimeOfDay? _notificationTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications, size: 80, color: Colors.orange),
          const SizedBox(height: 16),
          const Text('Orario di avviso scommesse', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                setState(() => _notificationTime = time);
                FirebaseFirestore.instance.collection('settings').doc('global').set({
                  'notificationHour': time.hour,
                  'notificationMinute': time.minute,
                }, SetOptions(merge: true));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Orario salvato!')));
                }
              }
            },
            child: Text(_notificationTime != null ? _notificationTime!.format(context) : 'Seleziona Orario Avviso'),
          ),
        ],
      ),
    );
  }
}
