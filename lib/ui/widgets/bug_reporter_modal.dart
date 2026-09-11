import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/bug_report_service.dart';

class BugReporterModal extends ConsumerStatefulWidget {
  final Uint8List? screenshotBytes;
  final String locationContext;

  const BugReporterModal({
    super.key,
    this.screenshotBytes,
    required this.locationContext,
  });

  @override
  ConsumerState<BugReporterModal> createState() => _BugReporterModalState();
}

class _BugReporterModalState extends ConsumerState<BugReporterModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _type = 'bug';
  bool _includeScreenshot = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(bugReportServiceProvider)
          .submitIssue(
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            type: _type,
            location: widget.locationContext,
            screenshotBytes: _includeScreenshot ? widget.screenshotBytes : null,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Segnalazione inviata! Grazie!')),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Errore: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.bug_report, color: Colors.orange, size: 28),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Segnala un Problema',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo Segnalazione',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'bug',
                    child: Text('Bug / Malfunzionamento'),
                  ),
                  DropdownMenuItem(
                    value: 'enhancement',
                    child: Text('Miglioria / Suggerimento'),
                  ),
                  DropdownMenuItem(
                    value: 'ui',
                    child: Text('Problema Visivo (UI)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _type = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titolo breve',
                  hintText: 'Es. Il pulsante salva non funziona',
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Campo richiesto' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descrizione dettagliata',
                  hintText: 'Cosa stavi facendo? Cosa ti aspettavi accadesse?',
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Campo richiesto' : null,
              ),
              const SizedBox(height: 16),
              if (widget.screenshotBytes != null) ...[
                CheckboxListTile(
                  title: const Text('Includi Screenshot'),
                  value: _includeScreenshot,
                  onChanged: (val) =>
                      setState(() => _includeScreenshot = val ?? true),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_includeScreenshot)
                  Container(
                    height: 150,
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(widget.screenshotBytes!),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              Text(
                'Contesto automatico: ${widget.locationContext}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('INVIA A GITHUB'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
