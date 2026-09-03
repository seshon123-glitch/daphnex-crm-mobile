import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/document_url_resolver.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../models/client.dart';
import '../../models/crm_document.dart';
import '../../services/crm_api.dart';
import '../../services/document_picker_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({
    super.key,
    required this.api,
    this.clientId,
    this.documentPicker = const AndroidDocumentPickerService(),
  });

  final CrmApi api;
  final int? clientId;
  final DocumentPickerService documentPicker;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<CrmDocument>? _documents;
  String? _error;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _upload() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final clients = widget.clientId == null
          ? await widget.api.fetchClients()
          : <Client>[];
      if (!mounted) return;
      final clientId = widget.clientId;
      if (clientId == null && clients.isEmpty) {
        _showMessage('Add a client before uploading a document.');
        return;
      }
      final form = await showDialog<_DocumentUploadForm>(
        context: context,
        builder: (_) => _DocumentUploadDialog(
          clients: clients,
          initialClientId: clientId,
          picker: widget.documentPicker,
        ),
      );
      if (form == null) return;
      await widget.api.uploadClientDocument(
        clientId: form.clientId,
        title: form.title,
        type: form.type,
        filePath: form.document.filePath,
        description: form.description,
      );
      if (!mounted) return;
      _showMessage('Document uploaded.');
      await _load();
      await _deleteTemporaryFile(form.document.filePath);
    } catch (error) {
      if (mounted) _showMessage('Upload failed: $error');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final documents = widget.clientId == null
          ? await widget.api.fetchDocuments()
          : await widget.api.fetchClientDocuments(widget.clientId!);
      if (mounted) setState(() => _documents = documents);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _open(CrmDocument document) async {
    try {
      final download = await widget.api.fetchDocumentDownload(document.id);
      final uri = DocumentUrlResolver.resolve(download.downloadUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open document URL.');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${error.toString()}')),
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteTemporaryFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Temporary picker files are safe to leave in app cache if cleanup fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = _documents;
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('uploadDocumentButton'),
        onPressed: _uploading ? null : _upload,
        icon: const Icon(Icons.upload_file_rounded),
        label: Text(_uploading ? 'Uploading…' : 'Upload'),
      ),
      body: _error != null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : documents == null
          ? const LoadingView(label: 'Loading documents…')
          : documents.isEmpty
          ? const EmptyStateView(
              message: 'No documents found.',
              icon: Icons.folder_copy_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  const _UploadReadyNotice(),
                  const SizedBox(height: 12),
                  ...documents.map(
                    (document) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.lightBlue,
                            child: Icon(
                              Icons.description_outlined,
                              color: AppColors.blue,
                            ),
                          ),
                          title: Text(
                            document.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${document.clientName}\n${document.fileName} • ${document.type}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new_rounded),
                            onPressed: () => _open(document),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _UploadReadyNotice extends StatelessWidget {
  const _UploadReadyNotice();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Upload PDFs, Word documents, JPGs or PNGs using Android’s '
                'system document picker. The app does not request broad photo, '
                'video, audio or storage access.',
                style: TextStyle(color: AppColors.muted, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentUploadDialog extends StatefulWidget {
  const _DocumentUploadDialog({
    required this.clients,
    required this.initialClientId,
    required this.picker,
  });

  final List<Client> clients;
  final int? initialClientId;
  final DocumentPickerService picker;

  @override
  State<_DocumentUploadDialog> createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<_DocumentUploadDialog> {
  static const _maxFileSize = 10 * 1024 * 1024;
  static const _allowedTypes = {
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'image/jpeg',
    'image/png',
  };

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _type = 'general';
  late int _clientId;
  PickedCrmDocument? _document;
  String? _pickerError;

  @override
  void initState() {
    super.initState();
    _clientId = widget.initialClientId ?? widget.clients.first.id;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _pickerError = null);
    final picked = await widget.picker.pickDocument();
    if (picked == null) return;
    final validationError = _validateDocument(picked);
    if (validationError != null) {
      setState(() {
        _document = null;
        _pickerError = validationError;
      });
      return;
    }
    setState(() {
      _document = picked;
      if (_title.text.trim().isEmpty) {
        _title.text = picked.fileName.replaceFirst(RegExp(r'\.[^.]+$'), '');
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final document = _document;
    if (document == null) {
      setState(() => _pickerError = 'Choose a supported document first.');
      return;
    }
    Navigator.of(context).pop(
      _DocumentUploadForm(
        clientId: _clientId,
        title: _title.text.trim(),
        type: _type,
        description: _description.text.trim(),
        document: document,
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? _validateDocument(PickedCrmDocument document) {
    final mimeType = document.mimeType.toLowerCase();
    final name = document.fileName.toLowerCase();
    final extensionAllowed =
        name.endsWith('.pdf') ||
        name.endsWith('.doc') ||
        name.endsWith('.docx') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png');
    if (!_allowedTypes.contains(mimeType) && !extensionAllowed) {
      return 'Unsupported file type. Use PDF, DOC, DOCX, JPG or PNG.';
    }
    if (document.fileSize <= 0) return 'The selected file is empty.';
    if (document.fileSize > _maxFileSize) {
      return 'File too large. The current mobile limit is 10 MB.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Upload document'),
    content: SizedBox(
      width: double.maxFinite,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.initialClientId == null) ...[
                DropdownButtonFormField<int>(
                  key: const Key('documentClientField'),
                  initialValue: _clientId,
                  decoration: const InputDecoration(labelText: 'Client'),
                  items: widget.clients
                      .map(
                        (client) => DropdownMenuItem(
                          value: client.id,
                          child: Text(
                            client.company.isEmpty
                                ? client.name
                                : client.company,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _clientId = value);
                  },
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                key: const Key('documentTypeField'),
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(
                    value: 'agreement',
                    child: Text('Agreement'),
                  ),
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('documentTitleField'),
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('pickDocumentButton'),
                onPressed: _pick,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(_document == null ? 'Choose file' : 'Change file'),
              ),
              if (_document != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${_document!.fileName} • ${(_document!.fileSize / 1024).ceil()} KB',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
              if (_pickerError != null) ...[
                const SizedBox(height: 8),
                Text(_pickerError!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        key: const Key('cancelDocumentUpload'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('confirmDocumentUpload'),
        onPressed: _submit,
        child: const Text('Upload'),
      ),
    ],
  );
}

class _DocumentUploadForm {
  const _DocumentUploadForm({
    required this.clientId,
    required this.title,
    required this.type,
    required this.description,
    required this.document,
  });

  final int clientId;
  final String title;
  final String type;
  final String description;
  final PickedCrmDocument document;
}
