import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/crm_api.dart';
import '../documents/documents_screen.dart';
import '../invoices/invoices_screen.dart';
import '../jobs/jobs_screen.dart';
import '../notifications/notifications_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.api});

  final CrmApi api;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ModuleTile(
            title: 'Invoices',
            subtitle: 'View balances, create invoices, mark paid or unpaid',
            icon: Icons.receipt_long_outlined,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => InvoicesScreen(api: api))),
          ),
          _ModuleTile(
            title: 'Jobs',
            subtitle: 'Track active and completed projects',
            icon: Icons.work_outline_rounded,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => JobsScreen(api: api))),
          ),
          _ModuleTile(
            title: 'Documents',
            subtitle: 'Browse, upload and open client documents',
            icon: Icons.folder_copy_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DocumentsScreen(api: api)),
            ),
          ),
          _ModuleTile(
            title: 'Notifications',
            subtitle: 'Review CRM reminders, invoices and tasks',
            icon: Icons.mark_email_unread_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => NotificationsScreen(api: api)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.lightBlue,
          child: Icon(icon, color: AppColors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
