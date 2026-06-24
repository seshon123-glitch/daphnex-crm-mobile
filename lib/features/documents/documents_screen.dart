import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../models/crm_document.dart';
import '../../services/crm_api.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, required this.api, this.clientId});

  final CrmApi api;
  final int? clientId;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<CrmDocument>? _documents;
  String? _error;
  bool _isUploading = false;

  static const _allowedExtensions = {
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
  };

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _upload() async {
    final result = await showDialog<_DocumentUploadResult>(
      context: context,
      builder: (_) => _DocumentUploadDialog(initialClientId: widget.clientId),
    );
    if (result == null) return;

    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions.toList(),
      withData: false,
    );
    final file = picked?.files.single;
    final path = file?.path;
    final extension = file?.extension?.toLowerCase();
    if (file == null || path == null) return;
    if (!_allowedExtensions.contains(extension)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unsupported file type. Use PDF, DOC, DOCX, JPG or PNG.',
          ),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      await widget.api.uploadClientDocument(
        clientId: result.clientId,
        title: result.title,
        type: result.type,
        description: result.description,
        filePath: path,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Document uploaded.')));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${error.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _open(CrmDocument document) async {
    try {
      final download = await widget.api.fetchDocumentDownload(document.id);
      final uri = Uri.tryParse(download.downloadUrl);
      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open document URL.');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${error.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('uploadDocumentButton'),
        onPressed: _isUploading ? null : _upload,
        icon: _isUploading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_file_rounded),
        label: Text(_isUploading ? 'Uploading' : 'Upload'),
      ),
      body: _error != null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : _documents == null
          ? const LoadingView(label: 'Loading documents…')
          : _documents!.isEmpty
          ? const EmptyStateView(
              message: 'No documents found.',
              icon: Icons.folder_copy_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                itemCount: _documents!.length,
                itemBuilder: (context, index) {
                  final document = _documents![index];
                  return Card(
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
                  );
                },
              ),
            ),
    );
  }
}

class _DocumentUploadDialog extends StatefulWidget {
  const _DocumentUploadDialog({this.initialClientId});

  final int? initialClientId;

  @override
  State<_DocumentUploadDialog> createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<_DocumentUploadDialog> {
  late final _clientId = TextEditingController(
    text: widget.initialClientId?.toString() ?? '1',
  );
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _type = 'other';

  @override
  void dispose() {
    _clientId.dispose();
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Upload document'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _clientId,
            decoration: const InputDecoration(labelText: 'Client ID'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Document title'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(value: 'agreement', child: Text('Agreement')),
              DropdownMenuItem(value: 'proposal', child: Text('Proposal')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (value) => setState(() => _type = value ?? 'other'),
          ),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Next you will choose a PDF, DOC, DOCX, JPG or PNG file.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final title = _title.text.trim();
          final clientId = int.tryParse(_clientId.text) ?? 0;
          if (clientId <= 0 || title.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Enter a valid client ID and document title.'),
              ),
            );
            return;
          }
          Navigator.pop(
            context,
            _DocumentUploadResult(
              clientId: clientId,
              title: title,
              type: _type,
              description: _description.text,
            ),
          );
        },
        child: const Text('Choose file'),
      ),
    ],
  );
}

class _DocumentUploadResult {
  const _DocumentUploadResult({
    required this.clientId,
    required this.title,
    required this.type,
    required this.description,
  });

  final int clientId;
  final String title;
  final String type;
  final String description;
}
