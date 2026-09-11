import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../logic/theme_provider.dart';
import '../../logic/auth_provider.dart';
import '../../logic/firestore_repository.dart';
import 'leaderboard_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isUploading = false;

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

  Future<void> _uploadImage() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        final storageRef = FirebaseStorage.instance.ref().child('avatars/${user.uid}.jpg');
        await storageRef.putFile(File(pickedFile.path));
        final downloadUrl = await storageRef.getDownloadURL();

        await ref.read(firestoreRepositoryProvider).updateUserRoles(user.uid, avatarUrl: downloadUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profilo aggiornata!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore caricamento: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final user = ref.watch(authStateProvider).value;
    final leaderboard = ref.watch(leaderboardProvider).value ?? [];
    final appUser = leaderboard.where((u) => u.id == user?.uid).firstOrNull;

    // Use current nickname from AppUser if available instead of default Firebase displayName.
    if (appUser != null && _nameController.text != appUser.name && !FocusScope.of(context).hasFocus) {
      _nameController.text = appUser.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo Personale'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: appUser?.avatarUrl != null ? NetworkImage(appUser!.avatarUrl!) : null,
            child: appUser?.avatarUrl == null ? const Icon(Icons.person, size: 50) : null,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _isUploading ? null : _uploadImage,
            icon: _isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt),
            label: Text(_isUploading ? 'Caricamento...' : 'Cambia Foto'),
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
