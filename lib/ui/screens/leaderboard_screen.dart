import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classifica'),
      ),
      body: ListView(
        children: const [
          ListTile(leading: Text('🥇', style: TextStyle(fontSize: 24)), title: Text('Daniele'), trailing: Text('10 pt 🔥🔥🔥🔥')),
          ListTile(leading: Text('🥈', style: TextStyle(fontSize: 24)), title: Text('Adreatik'), trailing: Text('2 pt')),
          ListTile(leading: Text('🥈', style: TextStyle(fontSize: 24)), title: Text('Nicola'), trailing: Text('2 pt')),
          ListTile(leading: Text('🥈', style: TextStyle(fontSize: 24)), title: Text('Samuele'), trailing: Text('2 pt')),
          ListTile(leading: Text('🥉', style: TextStyle(fontSize: 24)), title: Text('Sebastiano'), trailing: Text('1 pt')),
          ListTile(leading: Text('🪵', style: TextStyle(fontSize: 24)), title: Text('Giovanni'), trailing: Text('0 pt')),
        ],
      ),
    );
  }
}
