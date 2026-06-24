import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../../services/crm_api.dart';
import '../about/about_screen.dart';
import '../documents/documents_screen.dart';
import '../invoices/invoices_screen.dart';
import '../jobs/jobs_screen.dart';
import '../notifications/notifications_screen.dart';
import '../reminders/reminders_screen.dart';
import '../revenue/revenue_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.api,
    this.onOpenTasks,
    this.onOpenSettings,
  });

  final CrmApi api;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenSettings;

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        key: const Key('moreScroll'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy, AppColors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                DaphnexLogoMark(size: 56),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daphnex CRM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Mobile command centre',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Modules',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _ModuleTile(
            title: 'Invoices',
            subtitle: 'View balances, create invoices, mark paid or unpaid',
            icon: Icons.receipt_long_outlined,
            onTap: () => _push(context, InvoicesScreen(api: api)),
          ),
          _ModuleTile(
            title: 'Jobs / Projects',
            subtitle: 'Track active and completed project work',
            icon: Icons.work_outline_rounded,
            onTap: () => _push(context, JobsScreen(api: api)),
          ),
          _ModuleTile(
            title: 'Documents',
            subtitle: 'Browse, upload and open client documents',
            icon: Icons.folder_copy_outlined,
            onTap: () => _push(context, DocumentsScreen(api: api)),
          ),
          _ModuleTile(
            title: 'Notifications',
            subtitle: 'Review CRM reminders, invoices and tasks',
            icon: Icons.mark_email_unread_outlined,
            onTap: () => _push(context, NotificationsScreen(api: api)),
          ),
          _ModuleTile(
            title: 'Turnover / Revenue',
            subtitle: 'Outstanding invoices and future turnover reporting',
            icon: Icons.insights_rounded,
            onTap: () => _push(context, RevenueScreen(api: api)),
          ),
          _ModuleTile(
            title: 'Tasks',
            subtitle: 'Currently maps to Reminders until a task API is added',
            icon: Icons.checklist_rounded,
            onTap:
                onOpenTasks ?? () => _push(context, RemindersScreen(api: api)),
          ),
          const SizedBox(height: 22),
          const Text(
            'App',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _ModuleTile(
            title: 'Settings',
            subtitle: 'Profile, theme placeholder and logout',
            icon: Icons.settings_outlined,
            onTap: onOpenSettings ?? () {},
          ),
          _ModuleTile(
            title: 'About Daphnex CRM',
            subtitle: 'Company, website, support and app version',
            icon: Icons.info_outline_rounded,
            onTap: () => _push(context, const AboutScreen()),
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
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
