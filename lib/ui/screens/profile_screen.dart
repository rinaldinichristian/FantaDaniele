import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/theme_provider.dart';
import '../../logic/auth_provider.dart';
import '../../logic/firestore_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo Personale'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              // Implementa il caricamento foto con image_picker e firebase_storage
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Caricamento foto in arrivo...'))
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Cambia Foto'),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nickname',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (user != null && _nameController.text.isNotEmpty) {
                await ref.read(firestoreRepositoryProvider).updateUserRoles(user.uid, name: _nameController.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profilo aggiornato!'))
                  );
                }
              }
            },
            child: const Text('Salva Profilo'),
          ),
          const Divider(height: 48),
          SwitchListTile(
            title: const Text('Tema Scuro'),
            subtitle: const Text('Attiva la Dark Mode'),
            value: isDark,
            onChanged: (val) {
              ref.read(themeProvider.notifier).toggleTheme(val);
            },
          ),
        ],
      ),
    );
  }
}
