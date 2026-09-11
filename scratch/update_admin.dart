import 'dart:io';

void main() {
  final file = File('lib/ui/screens/admin_screen.dart');
  
  final content = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' as io;

import '../../logic/firestore_repository.dart';
import '../../models/app_user.dart';
import '../../models/app_settings.dart';
import 'leaderboard_screen.dart';

// Provides app settings globally
final settingsProvider = StreamProvider((ref) {
  return ref.watch(firestoreRepositoryProvider).watchSettings();
});

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
              Tab(icon: Icon(Icons.settings), text: 'Impostazioni Giro'),
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
    final usersAsync = ref.watch(leaderboardProvider);
    return usersAsync.when(
      data: (users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null),
            title: Text(user.name),
            subtitle: Text('Punti: \${user.points} | Streak: \${user.streak}'),
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
      error: (e, st) => Center(child: Text('Errore: \$e')),
    );
  }

  void _editPoints(BuildContext context, WidgetRef ref, AppUser user) {
    final ctrl = TextEditingController(text: user.points.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifica Punti di \${user.name}'),
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
  String? _uploadedImageUrl;
  bool _uploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (xFile == null) return;

    setState(() => _uploading = true);
    try {
      final ref = FirebaseStorage.instance.ref().child('proof_images/\${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(io.File(xFile.path));
      final url = await ref.getDownloadURL();
      setState(() => _uploadedImageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore upload: \$e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

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
          const SizedBox(height: 24),
          if (_uploadedImageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Image.network(_uploadedImageUrl!, height: 150),
            )
          else if (_uploading)
            const CircularProgressIndicator()
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Carica Foto Prova (Opzionale)'),
              onPressed: _pickAndUploadImage,
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
                          proofImageUrl: _uploadedImageUrl,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sessione chiusa! Punti assegnati.')));
                      setState(() {
                        _arrivalTime = null;
                        _uploadedImageUrl = null;
                      });
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
  final _prizeController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        // Init controllers once
        if (_prizeController.text.isEmpty && settings.prizePool != null) {
          _prizeController.text = settings.prizePool!;
        }
        if (_startDate == null) _startDate = settings.roundStartDate;
        if (_endDate == null) _endDate = settings.roundEndDate;

        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Icon(Icons.settings, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Impostazioni del Giro Attuale', style: TextStyle(fontSize: 20), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            TextField(
              controller: _prizeController,
              decoration: const InputDecoration(
                labelText: 'Montepremi in palio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              title: const Text('Data Inizio Giro'),
              subtitle: Text(_startDate != null ? "\${_startDate!.day}/\${_startDate!.month}/\${_startDate!.year}" : 'Non impostata'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => _startDate = date);
              },
            ),
            ListTile(
              title: const Text('Data Fine Giro'),
              subtitle: Text(_endDate != null ? "\${_endDate!.day}/\${_endDate!.month}/\${_endDate!.year}" : 'Non impostata'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => _endDate = date);
              },
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Salva Impostazioni'),
              onPressed: () async {
                await ref.read(firestoreRepositoryProvider).updateSettings(AppSettings(
                  prizePool: _prizeController.text,
                  roundStartDate: _startDate,
                  roundEndDate: _endDate,
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impostazioni salvate!')));
                }
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Errore caricamento impostazioni: \$e')),
    );
  }
}
''';

  file.writeAsStringSync(content);
}
