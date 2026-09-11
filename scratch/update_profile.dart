import 'dart:io';

void main() {
  final file = File('lib/logic/firestore_repository.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "await _db.collection('fd_users').doc(userId).update(data);",
    "await _db.collection('fd_users').doc(userId).set(data, SetOptions(merge: true));"
  );
  
  content = content.replaceFirst(
    "await _db.collection('fd_users').doc(userId).update({'points': points});",
    "await _db.collection('fd_users').doc(userId).set({'points': points}, SetOptions(merge: true));"
  );

  file.writeAsStringSync(content);
}
