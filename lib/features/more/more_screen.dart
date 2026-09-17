import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/commercial_components.dart';
import '../../core/widgets/workspace_banner.dart';
import '../../models/commercial_session.dart';
import '../../services/crm_api.dart';
import '../account/account_screens.dart';
import '../documents/documents_screen.dart';
import '../invoices/invoices_screen.dart';
import '../jobs/jobs_screen.dart';
import '../navigation/commercial_navigation.dart';
import '../notifications/notifications_screen.dart';
import '../reminders/reminders_screen.dart';
import '../revenue/revenue_screen.dart';
import '../settings/settings_screen.dart';
import '../tasks/tasks_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.api,
    required this.onLogout,
    this.rootTitle = 'More',
    this.onOpenWork,
    this.onOpenFinance,
    this.onOpenFiles,
  });

  final CrmApi api;
  final Future<void> Function() onLogout;
  final String rootTitle;
  final VoidCallback? onOpenWork;
  final VoidCallback? onOpenFinance;
  final VoidCallback? onOpenFiles;

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label will be connected in a later phase.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = api.currentSession;
    final policy = CommercialNavigationPolicy(session);

    return Scaffold(
      appBar: AppBar(title: Text(rootTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const Key('moreScroll'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
          children: [
            _WorkspaceHeader(session: session),
            const CommercialSectionHeader(title: 'Business'),
            if (policy.canShowManagementDestination('company_profile'))
              CommercialHubCard(
                key: const Key('moreCompanyProfile'),
                title: 'Company Profile',
                subtitle: 'Business identity and trading details.',
                icon: Icons.business_rounded,
                onTap: () => _push(context, CompanyProfileScreen(api: api)),
              ),
            if (policy.canShowManagementDestination('branding'))
              CommercialHubCard(
                key: const Key('moreBranding'),
                title: 'Branding',
                subtitle: 'Logo and company presentation settings.',
                icon: Icons.palette_outlined,
                color: AppColors.purple,
                onTap: () => _push(context, BrandingScreen(api: api)),
              ),
            if (policy.canShowManagementDestination('team_management'))
              CommercialHubCard(
                key: const Key('moreTeam'),
                title: 'Team',
                subtitle: 'Invite and manage workspace members.',
                icon: Icons.group_outlined,
                color: AppColors.success,
                onTap: () => _push(context, TeamFoundationScreen(api: api)),
              ),
            if (!policy.canManageBusiness)
              const EntitlementNotice(
                title: 'Management restricted',
                message:
                    'Company, branding and team management are hidden for Staff. The server remains authoritative for all access checks.',
              ),
            const CommercialSectionHeader(title: 'Activity'),
            CommercialHubCard(
              key: const Key('moreNotifications'),
              title: 'Notifications',
              subtitle: 'Unread CRM alerts and reminder notices.',
              icon: Icons.mark_email_unread_outlined,
              color: AppColors.purple,
              onTap: () => _push(context, NotificationsScreen(api: api)),
            ),
            CommercialHubCard(
              key: const Key('moreActivityLog'),
              title: 'Activity Log',
              subtitle: 'Prepared for a full audit trail view.',
              icon: Icons.timeline_rounded,
              color: AppColors.teal,
              badge: const CommercialStatusChip(
                label: 'Coming soon',
                icon: Icons.schedule_rounded,
                color: AppColors.warning,
              ),
              onTap: () => _comingSoon(context, 'Activity Log'),
            ),
            const CommercialSectionHeader(title: 'Shortcuts'),
            CommercialHubCard(
              key: const Key('moreInvoices'),
              title: 'Invoices',
              subtitle: 'Open the Finance area or invoice list.',
              icon: Icons.receipt_long_outlined,
              color: AppColors.warning,
              onTap: () => _push(context, InvoicesScreen(api: api)),
            ),
            CommercialHubCard(
              key: const Key('moreJobsProjects'),
              title: 'Jobs / Projects',
              subtitle: 'Open active and completed work.',
              icon: Icons.work_outline_rounded,
              color: AppColors.purple,
              onTap: () => _push(context, JobsScreen(api: api)),
            ),
            CommercialHubCard(
              key: const Key('moreDocuments'),
              title: 'Documents',
              subtitle: 'Open secure CRM files.',
              icon: Icons.folder_copy_outlined,
              color: AppColors.teal,
              onTap: () => _push(context, DocumentsScreen(api: api)),
            ),
            CommercialHubCard(
              key: const Key('moreRevenue'),
              title: 'Turnover / Revenue',
              subtitle: 'Open the live financial summary.',
              icon: Icons.insights_rounded,
              color: AppColors.success,
              onTap: () => _push(context, RevenueScreen(api: api)),
            ),
            CommercialHubCard(
              key: const Key('moreTasks'),
              title: 'Tasks',
              subtitle: 'Real CRM tasks with client and project context.',
              icon: Icons.checklist_rounded,
              color: AppColors.success,
              onTap: () => _push(context, TasksScreen(api: api)),
            ),
            CommercialHubCard(
              key: const Key('moreReminders'),
              title: 'Reminders',
              subtitle: 'Reminder alerts with optional project context.',
              icon: Icons.notifications_active_outlined,
              color: AppColors.blue,
              onTap: () => _push(context, RemindersScreen(api: api)),
            ),
            const CommercialSectionHeader(title: 'Account'),
            CommercialHubCard(
              key: const Key('morePlanAccount'),
              title: 'Plan & Account',
              subtitle: _planSubtitle(session),
              icon: Icons.workspace_premium_outlined,
              badge: _planBadge(session),
              onTap: () => _push(context, PlanAccountScreen(api: api)),
            ),
            CommercialHubCard(
              key: const Key('moreMyProfile'),
              title: 'My Profile',
              subtitle: session?.user.email.isNotEmpty == true
                  ? session!.user.email
                  : 'Personal profile settings are coming soon.',
              icon: Icons.person_outline_rounded,
              onTap: () => _push(context, MyProfileScreen(api: api)),
            ),
            if (policy.canShowManagementDestination('company_profile'))
              CommercialHubCard(
                key: const Key('moreCompanySettings'),
                title: 'Company Settings',
                subtitle: 'Workspace lifecycle, currency and timezone.',
                icon: Icons.admin_panel_settings_outlined,
                color: AppColors.teal,
                onTap: () => _push(context, CompanySettingsScreen(api: api)),
              ),
            CommercialHubCard(
              key: const Key('moreFeatureAccess'),
              title: 'Feature Access',
              subtitle: 'Plan features, locked states and limits.',
              icon: Icons.lock_open_outlined,
              color: AppColors.purple,
              onTap: () => _push(context, FeatureAccessScreen(api: api)),
            ),
            CommercialHubCard(
              key: const Key('moreSettings'),
              title: 'Settings',
              subtitle: 'App preferences, support and logout.',
              icon: Icons.settings_outlined,
              onTap: () => _push(context, SettingsScreen(onLogout: onLogout)),
            ),
            const CommercialSectionHeader(title: 'Help'),
            CommercialHubCard(
              key: const Key('moreHelpSupport'),
              title: 'Help & Support',
              subtitle: 'Support hand-off placeholder for the commercial app.',
              icon: Icons.support_agent_rounded,
              onTap: () => _comingSoon(context, 'Help & Support'),
            ),
            CommercialHubCard(
              key: const Key('moreAbout'),
              title: 'About',
              subtitle: 'Daphnex CRM Mobile and company information.',
              icon: Icons.info_outline_rounded,
              onTap: () => _push(context, const AboutDaphnexCommercialScreen()),
            ),
            const CommercialSectionHeader(title: 'Session'),
            OutlinedButton.icon(
              key: const Key('moreLogoutButton'),
              onPressed: () async => onLogout(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: .32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _planSubtitle(CommercialSession? session) {
    final label = session?.entitlements.plan.label;
    if (label == null || label.isEmpty) {
      return 'Plan state will appear after session validation.';
    }
    return '$label plan · server-authoritative entitlements';
  }

  Widget? _planBadge(CommercialSession? session) {
    final label = session?.entitlements.plan.label;
    if (label == null || label.isEmpty) return null;
    return CommercialStatusChip(
      label: label,
      icon: Icons.verified_outlined,
      color: AppColors.blue,
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({required this.session});

  final CommercialSession? session;

  @override
  Widget build(BuildContext context) => PremiumPageBanner(
    session: session,
    title: 'Settings',
    subtitle:
        'Manage company profile, branding, plan, team access, support and secure account actions.',
    icon: Icons.settings_outlined,
    metrics: {
      'Plan': session?.entitlements.plan.label ?? 'Current',
      'Role': session?.membership.roleLabel ?? 'Workspace',
    },
  );
}
