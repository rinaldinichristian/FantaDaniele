import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FantaDaniele'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => context.push('/leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const Text('Piazza la tua scommessa:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 10, minute: 30),
                  );
                  if (time != null && context.mounted) {
                    // TODO: Save to Firestore
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Scommessa salvata: ${time.format(context)}')),
                    );
                  }
                },
                icon: const Icon(Icons.access_time),
                label: const Text('Scegli Orario d\\'Arrivo'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Scommesse di oggi:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(leading: CircleAvatar(child: Text('M')), title: Text('Matteo'), trailing: Text('10:35')),
                  ListTile(leading: CircleAvatar(child: Text('N')), title: Text('Nicola'), trailing: Text('10:24')),
                  ListTile(leading: CircleAvatar(child: Text('A')), title: Text('Adreatik'), trailing: Text('10:21')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
