import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_info.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openWebsite() async {
    final uri = Uri.parse(AppInfo.website);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Daphnex CRM')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(22),
              child: Column(
                children: [
                  DaphnexLogoMark(size: 78),
                  SizedBox(height: 16),
                  DaphnexWordmark(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                const _AboutRow(label: 'App name', value: AppInfo.name),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const _AboutRow(label: 'Company', value: AppInfo.company),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(
                    Icons.public_rounded,
                    color: AppColors.blue,
                  ),
                  title: const Text('Website'),
                  subtitle: const Text(AppInfo.website),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: _openWebsite,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const _AboutRow(
                  label: 'Support',
                  value: AppInfo.supportEmail,
                  icon: Icons.support_agent_rounded,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const _AboutRow(
                  label: 'App version',
                  value: AppInfo.version,
                  icon: Icons.info_outline_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Invoice PDF downloads, richer turnover reports and dedicated task '
            'workflows are prepared in the mobile UI and will connect when the '
            'matching CRM API endpoints are added.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.label,
    required this.value,
    this.icon = Icons.business_rounded,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.blue),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
