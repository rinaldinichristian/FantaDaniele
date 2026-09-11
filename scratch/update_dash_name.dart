import 'dart:io';

void main() {
  final file = File('lib/ui/screens/dashboard_screen.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "final displayName = betUser?.name ?? bet.userName;",
    "final displayName = (betUser != null && betUser.name.isNotEmpty && betUser.name != 'Utente Sconosciuto') ? betUser.name : bet.userName;"
  );
  
  file.writeAsStringSync(content);
}
