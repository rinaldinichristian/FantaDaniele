import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../logic/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: authState.when(
        data: (user) {
          if (user != null) {
            // Utente loggato, reindirizza alla Dashboard
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/dashboard');
            });
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          // Utente non loggato, mostra la UI di login
          return _buildLoginUI(context, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, stack) => Center(
          child: Text('Errore: $err', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildLoginUI(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield, size: 100, color: Colors.white),
          const SizedBox(height: 20),
          const Text(
            'FantaDaniele',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await ref.read(authControllerProvider).signInWithGoogle();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore di accesso: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.login),
            label: const Text('Entra con Google'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
