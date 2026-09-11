import 'dart:io';

void main() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  String content = file.readAsStringSync();
  
  content = content.replaceFirst(
    '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>',
    '<uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>\n    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>'
  );

  content = content.replaceFirst(
    '<intent>\n            <action android:name="android.intent.action.PROCESS_TEXT"/>\n            <data android:mimeType="text/plain"/>\n        </intent>',
    '<intent>\n            <action android:name="android.intent.action.PROCESS_TEXT"/>\n            <data android:mimeType="text/plain"/>\n        </intent>\n        <intent>\n            <action android:name="android.intent.action.VIEW" />\n            <data android:scheme="https" />\n        </intent>'
  );

  file.writeAsStringSync(content);
}
