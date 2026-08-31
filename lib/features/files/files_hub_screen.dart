import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/commercial_components.dart';
import '../../services/crm_api.dart';
import '../documents/documents_screen.dart';

class FilesHubScreen extends StatelessWidget {
  const FilesHubScreen({super.key, required this.api});

  final CrmApi api;

  @override
  Widget build(BuildContext context) {
    final session = api.currentSession;
    final workspace = session?.branding.displayName.isNotEmpty == true
        ? session!.branding.displayName
        : session?.tenant.companyName ?? 'Commercial workspace';

    return CommercialPage(
      title: 'Files',
      subtitle: workspace,
      children: [
        const CommercialSectionHeader(
          title: 'Documents',
          subtitle:
              'Secure CRM files with the existing Stage C1 document-opening protections preserved.',
        ),
        CommercialHubCard(
          key: const Key('filesDocumentsCard'),
          title: 'Documents',
          subtitle: 'Browse and open client documents from the CRM.',
          icon: Icons.folder_copy_outlined,
          color: AppColors.teal,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => DocumentsScreen(api: api)),
          ),
        ),
        const EntitlementNotice(
          title: 'Upload status',
          message:
              'Document browsing and secure opening remain available. Native upload remains controlled by the current Google Play compliant picker policy.',
        ),
      ],
    );
  }
}
