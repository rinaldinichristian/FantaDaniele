import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

final bugReportServiceProvider = Provider<BugReportService>((ref) {
  return BugReportService();
});

final rootBoundaryKey = GlobalKey();

class BugReportService {
  static const String _githubToken = String.fromEnvironment('GITHUB_TOKEN');
  static const String _repoOwner = 'rinaldinichristian';
  static const String _repoName = 'FantaDaniele';

  static void reportError(dynamic exception, dynamic stack) {
    debugPrint('Uncaught Error: $exception\n$stack');
    // We could automatically fire issues here, but that might spam GitHub.
    // For now we just log it.
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
            'bug_reports/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
        final ref = FirebaseStorage.instance.ref().child(fileName);

        final uploadTask = await ref.putData(
          screenshotBytes,
          SettableMetadata(contentType: 'image/png'),
        );
        screenshotUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        debugPrint('Failed to upload screenshot to Firebase Storage: $e');
        // Continue without screenshot
      }
    }

    // Gather Device Info
    final deviceInfo = DeviceInfoPlugin();
    String deviceModel = 'Unknown';
    String osVersion = 'Unknown';

    if (!kIsWeb) {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceModel = '${info.manufacturer} ${info.model}';
        osVersion =
            'Android ${info.version.release} (API ${info.version.sdkInt})';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceModel = info.model;
        osVersion = '${info.systemName} ${info.systemVersion}';
      }
    }

    final bodyBuffer = StringBuffer();
    bodyBuffer.writeln('### Descrizione\n$description\n');
    bodyBuffer.writeln('### Contesto');
    bodyBuffer.writeln('- **Sezione App**: `$location`');
    bodyBuffer.writeln('- **Dispositivo**: $deviceModel');
    bodyBuffer.writeln('- **Sistema Operativo**: $osVersion\n');

    if (screenshotUrl != null) {
      bodyBuffer.writeln('### Screenshot');
      bodyBuffer.writeln('![Screenshot]($screenshotUrl)');
    } else if (screenshotBytes != null) {
      bodyBuffer.writeln('### Screenshot');
      bodyBuffer.writeln(
        '*(Screenshot catturato ma non caricato per errore di rete o permessi Firebase Storage)*',
      );
    }

    if (_githubToken.isEmpty) {
      debugPrint(
        'No GITHUB_TOKEN provided via --dart-define. Simulating issue creation:',
      );
      debugPrint('Title: [$type] $title');
      debugPrint('Body:\n${bodyBuffer.toString()}');
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      return;
    }

    final response = await http.post(
      Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/issues'),
      headers: {
        'Authorization': 'Bearer $_githubToken',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': '[$type] $title',
        'body': bodyBuffer.toString(),
        'labels': [type],
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create issue: ${response.statusCode} ${response.body}',
      );
    }
  }
}
