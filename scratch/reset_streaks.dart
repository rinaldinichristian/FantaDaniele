import 'dart:io';

void main() {
  final file = File('lib/logic/firestore_repository.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "Future<void> updateUserPoints(String userId, int points) async {",
    "Future<void> resetAllStreaks() async {\n    final users = await _db.collection('fd_users').get();\n    for (var u in users.docs) {\n      await _db.collection('fd_users').doc(u.id).update({'streak': 0});\n    }\n  }\n\n  Future<void> updateUserPoints(String userId, int points) async {"
  );
  
  file.writeAsStringSync(content);

  final admin = File('lib/ui/screens/admin_screen.dart');
  String adminContent = admin.readAsStringSync();

  final oldAdmin = "const SizedBox(height: 32),\n            FilledButton.icon(";
  final newAdmin = "const SizedBox(height: 32),\n            OutlinedButton.icon(\n              icon: const Icon(Icons.refresh),\n              label: const Text('Azzera tutti gli Streak'),\n              onPressed: () async {\n                await ref.read(firestoreRepositoryProvider).resetAllStreaks();\n                if (context.mounted) {\n                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Streak azzerati!')));\n                }\n              },\n            ),\n            const SizedBox(height: 16),\n            FilledButton.icon(";
  
  adminContent = adminContent.replaceFirst(oldAdmin, newAdmin);
  admin.writeAsStringSync(adminContent);
}
