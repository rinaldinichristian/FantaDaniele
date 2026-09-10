import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/firestore_repository.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pannello Arbitro'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.gavel, size: 100, color: Colors.red),
            const SizedBox(height: 32),
            const Text(
              'Daniele è appena arrivato?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scegli l\'orario effettivo di arrivo.\nQuesto chiuderà le scommesse e calcolerà il vincitore!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (time != null && context.mounted) {
                  // Chiede conferma prima di eseguire
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confermi?'),
                      content: Text('Daniele è arrivato alle ${time.format(context)}? Questo chiuderà le scommesse.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Conferma', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    try {
                      await ref.read(firestoreRepositoryProvider).endSession(time.hour, time.minute);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sessione chiusa e vincitore calcolato! 🎉')),
                        );
                        Navigator.of(context).pop(); // Torna indietro
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Errore: $e')),
                        );
                      }
                    }
                  }
                }
              },
              icon: const Icon(Icons.stop_circle),
              label: const Text('Registra Arrivo & Calcola Vincitore'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
