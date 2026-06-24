import 'package:flutter/material.dart';

import '../../core/config/app_info.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../about/about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        key: const Key('settingsScroll'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  DaphnexLogoMark(size: 54),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daphnex User',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'demo@daphnex.com',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.blue,
                  ),
                  title: const Text('User profile'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.palette_outlined,
                    color: AppColors.blue,
                  ),
                  title: const Text('Theme'),
                  subtitle: const Text('Light · More options coming soon'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.blue,
                  ),
                  title: const Text('App version'),
                  trailing: const Text(
                    AppInfo.version,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.business_rounded,
                    color: AppColors.blue,
                  ),
                  title: const Text('About Daphnex CRM'),
                  subtitle: const Text(
                    '${AppInfo.company} · ${AppInfo.website}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                const ListTile(
                  leading: Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.blue,
                  ),
                  title: Text('Support'),
                  subtitle: Text(AppInfo.supportEmail),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            key: const Key('logoutButton'),
            onPressed: () async => onLogout(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: Colors.red.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
