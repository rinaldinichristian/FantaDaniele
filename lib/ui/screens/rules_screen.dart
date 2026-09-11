import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regolamento'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          _RuleCard(
            icon: Icons.access_time,
            title: '1. Piazza la tua Scommessa',
            description: 'Ogni mattina le scommesse vengono aperte. Cerca di indovinare a che ora varcherà la porta Daniele!',
          ),
          _RuleCard(
            icon: Icons.wb_sunny,
            title: '2. Studia il Meteo',
            description: 'Tieni sempre d\'occhio le condizioni atmosferiche. Asfalto bagnato o pioggia riducono drasticamente il grip e allungano i tempi di arrivo.',
          ),
          _RuleCard(
            icon: Icons.gavel,
            title: '3. Regole di Inserimento',
            description: 'Non è possibile inserire due orari uguali. Il primo che arriva decide!',
          ),
          _RuleCard(
            icon: Icons.stars,
            title: '4. Punti',
            description: 'Chi indovina l\'orario esatto (o ci si avvicina di più) vince 1 punto. Se nessuno indovina l\'orario esatto, il punto va a Daniele!',
          ),
          _RuleCard(
            icon: Icons.local_fire_department,
            title: '5. Serie di Vittorie (Streak)',
            description: 'Se vinci più giorni consecutivi, il tuo counter 🔥 salirà. Se perdi, la streak tornerà a zero!',
          ),
          _RuleCard(
            icon: Icons.emoji_events,
            title: '6. Il Giro e il Montepremi',
            description: 'Gli amministratori impostano la durata del giro e il montepremi in palio. Il vincitore del giro ottiene la gloria (e il montepremi)!',
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _RuleCard({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
