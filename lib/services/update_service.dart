import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/version_utils.dart';

class UpdateService {
  static const String _githubOwner = 'rinaldinichristian';
  static const String _githubRepo = 'FantaDaniele';

  static Future<void> checkForUpdates(BuildContext context) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      final apiUrl =
          'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final remoteVersionTag = data['tag_name'] as String;
        final releaseNotes =
            data['body'] as String? ?? 'Nessuna nota di rilascio disponibile.';
        final cleanRemoteVersion = remoteVersionTag.replaceAll('v', '');

        final packageInfo = await PackageInfo.fromPlatform();
        final localVersion = packageInfo.version;

        if (VersionUtils.isNewerVersion(cleanRemoteVersion, localVersion)) {
          final assets = data['assets'] as List<dynamic>;
          String? downloadUrl;

          if (Platform.isAndroid) {
            final apkAsset = assets.firstWhere(
              (asset) => (asset['name'] as String).endsWith('.apk'),
              orElse: () => null,
            );
            if (apkAsset != null) {
              downloadUrl = apkAsset['browser_download_url'] as String;
            }
          }

          // Fallback to release page se non troviamo l'APK
          downloadUrl ??= data['html_url'] as String;

          if (context.mounted) {
            showUpdateDialogExternal(
              context,
              cleanRemoteVersion,
              downloadUrl,
              releaseNotes,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  static void showUpdateDialogExternal(
    BuildContext context,
    String newVersion,
    String downloadUrl,
    String releaseNotes,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _UpdateDialogWidget(
          newVersion: newVersion,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes,
        );
      },
    );
  }
}

class _UpdateDialogWidget extends StatefulWidget {
  final String newVersion;
  final String downloadUrl;
  final String releaseNotes;

  const _UpdateDialogWidget({
    required this.newVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  @override
  State<_UpdateDialogWidget> createState() => _UpdateDialogWidgetState();
}

class _UpdateDialogWidgetState extends State<_UpdateDialogWidget> {
  bool _isDownloading = false;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Aggiornamento v${widget.newVersion} Disponibile!'),
      content: _isDownloading
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Scaricamento in corso, non chiudere l\'app...'),
                const SizedBox(height: 20),
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 10),
                Text('${(_progress * 100).toStringAsFixed(0)}%'),
              ],
            )
          : SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Novità in questa versione:'),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          widget.releaseNotes,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Vuoi installarla ora?'),
                ],
              ),
            ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Più tardi'),
          ),
        if (!_isDownloading)
          FilledButton(
            onPressed: () => _downloadAndInstall(context),
            child: const Text('Aggiorna ora'),
          ),
      ],
    );
  }

  Future<void> _downloadAndInstall(BuildContext context) async {
    if (!Platform.isAndroid || !widget.downloadUrl.endsWith('.apk')) {
      _fallbackToBrowser(context, widget.downloadUrl);
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    try {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/FantaDaniele_update_${widget.newVersion}.apk';

      // Always start fresh
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      final request = http.Request('GET', Uri.parse(widget.downloadUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed with status ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 1;
      int downloadedLength = 0;

      final sink = file.openWrite();

      await response.stream
          .map((chunk) {
            downloadedLength += chunk.length;
            setState(() {
              _progress = downloadedLength / contentLength;
            });
            return chunk;
          })
          .pipe(sink);

      await sink.flush();
      await sink.close();

      // Chiudi il popup
      if (context.mounted) Navigator.pop(context);

      // Apri l'installer
      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done && context.mounted) {
        // Se c'è stato un problema nell'apertura (es: permessi), proviamo con browser
        _fallbackToBrowser(context, widget.downloadUrl);
      }
    } catch (e) {
      debugPrint('Download/Install error: $e');
      if (context.mounted) {
        Navigator.pop(context);
        _fallbackToBrowser(context, widget.downloadUrl);
      }
    }
  }

  Future<void> _fallbackToBrowser(
    BuildContext context,
    String downloadUrl,
  ) async {
    final uri = Uri.parse(downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (context.mounted) Navigator.pop(context);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile aprire il link di download.'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}
