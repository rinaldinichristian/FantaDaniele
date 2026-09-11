import 'dart:io';

void main() {
  final file = File('lib/services/bug_report_service.dart');
  final content = '''
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

final bugReportServiceProvider = Provider<BugReportService>((ref) {
  return BugReportService();
});

class BugReportService {
  static const String _repoOwner = 'rinaldinichristian';
  static const String _repoName = 'FantaDaniele';

  static void reportError(dynamic exception, dynamic stack) {
    debugPrint('Uncaught Error: \$exception\\n\$stack');
  }

  Future<void> submitIssue({
    required String title,
    required String description,
    required String type,
    required String location,
    Uint8List? screenshotBytes,
  }) async {
    String? screenshotUrl;

    if (screenshotBytes != null) {
      try {
        final fileName =
            'bug_reports/screenshot_\${DateTime.now().millisecondsSinceEpoch}.png';
        final ref = FirebaseStorage.instance.ref().child(fileName);

        final uploadTask = await ref.putData(
          screenshotBytes,
          SettableMetadata(contentType: 'image/png'),
        );
        screenshotUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        debugPrint('Failed to upload screenshot to Firebase Storage: \$e');
      }
    }

    // Gather Device Info
    final deviceInfo = DeviceInfoPlugin();
    String deviceModel = 'Unknown';
    String osVersion = 'Unknown';

    if (!kIsWeb) {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceModel = '\${info.manufacturer} \${info.model}';
        osVersion = 'Android \${info.version.release} (API \${info.version.sdkInt})';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceModel = info.model;
        osVersion = '\${info.systemName} \${info.systemVersion}';
      }
    }

    final bodyBuffer = StringBuffer();
    bodyBuffer.writeln('### Descrizione\\n\$description\\n');
    bodyBuffer.writeln('### Contesto');
    bodyBuffer.writeln('- **Sezione App**: `\$location`');
    bodyBuffer.writeln('- **Dispositivo**: \$deviceModel');
    bodyBuffer.writeln('- **Sistema Operativo**: \$osVersion\\n');

    if (screenshotUrl != null) {
      bodyBuffer.writeln('### Screenshot');
      bodyBuffer.writeln('![Screenshot](\$screenshotUrl)');
    } else if (screenshotBytes != null) {
      bodyBuffer.writeln('### Screenshot');
      bodyBuffer.writeln('*(Screenshot catturato ma non caricato per errore di rete)*');
    }

    final encodedTitle = Uri.encodeComponent('[\$type] \$title');
    final encodedBody = Uri.encodeComponent(bodyBuffer.toString());
    
    final githubUrl = 'https://github.com/\$_repoOwner/\$_repoName/issues/new?title=\$encodedTitle&body=\$encodedBody&labels=\$type';
    final uri = Uri.parse(githubUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Impossibile aprire il link verso GitHub.');
    }
  }
}
''';
  file.writeAsStringSync(content);
}
