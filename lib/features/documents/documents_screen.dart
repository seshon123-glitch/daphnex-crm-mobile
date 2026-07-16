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
    final documents = _documents;
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
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
                  const _UploadDisabledNotice(),
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

class _UploadDisabledNotice extends StatelessWidget {
  const _UploadDisabledNotice();

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
                'Document uploads are temporarily disabled in this Android '
                'release while the app uses a Google Play compliant document '
                'picker that does not request photo or video library access. '
                'Existing CRM documents can still be viewed and opened.',
                style: TextStyle(color: AppColors.muted, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
