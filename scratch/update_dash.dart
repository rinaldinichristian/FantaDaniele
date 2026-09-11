import 'dart:io';

void main() {
  final file = File('lib/ui/screens/dashboard_screen.dart');
  String content = file.readAsStringSync();
  
  final oldSessionBlock = '''
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
''';

  final newSessionBlock = '''
            // Sezione Scommessa
            sessionAsync.when(
              data: (session) {
                if (!session.isOpen) {
                  final leaderboard = ref.read(leaderboardProvider).value ?? [];
                  final winner = leaderboard.where((u) => u.id == session.winnerId).firstOrNull;
                  final winnerName = winner?.name ?? 'Sconosciuto';
                  final winnerText = session.danieleWon 
                      ? 'Nessuno ha indovinato! Il punto va a Daniele! 😈' 
                      : 'Vincitore di oggi: \$winnerName! 🏆';
                  
                  return Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('Scommesse chiuse per oggi! 🛑',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                          const SizedBox(height: 16),
                          if (session.actualArrivalTime != null)
                            Text('Orario d\\'arrivo effettivo: \${session.actualArrivalTime!.format(context)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(winnerText,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                              textAlign: TextAlign.center),
                          if (session.proofImageUrl != null) ...[
                            const SizedBox(height: 16),
                            const Text('Foto Prova:'),
                            const SizedBox(height: 8),
                            Image.network(session.proofImageUrl!, height: 150),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
''';

  content = content.replaceFirst(oldSessionBlock, newSessionBlock);
  file.writeAsStringSync(content);
}
