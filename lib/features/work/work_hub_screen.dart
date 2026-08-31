import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/commercial_components.dart';
import '../../models/commercial_session.dart';
import '../../services/crm_api.dart';
import '../clients/clients_screen.dart';
import '../jobs/jobs_screen.dart';
import '../reminders/reminders_screen.dart';
import '../navigation/commercial_navigation.dart';

class WorkHubScreen extends StatelessWidget {
  const WorkHubScreen({super.key, required this.api});

  final CrmApi api;

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _showTasksNotice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tasks currently use Reminders until the dedicated task API is connected.',
        ),
      ),
    );
    _push(context, RemindersScreen(api: api));
  }

  @override
  Widget build(BuildContext context) {
    final session = api.currentSession;
    final policy = CommercialNavigationPolicy(session);

    return CommercialPage(
      title: 'Work',
      subtitle: _workspaceSubtitle(session),
      children: [
        const CommercialSectionHeader(
          title: 'Operations',
          subtitle: 'Clients, projects and task-like reminders in one place.',
        ),
        CommercialHubCard(
          key: const Key('workClientsCard'),
          title: 'Clients',
          subtitle: 'Search client profiles, contact details and activity.',
          icon: Icons.people_alt_outlined,
          color: AppColors.blue,
          onTap: () => _push(context, ClientsScreen(api: api)),
        ),
        CommercialHubCard(
          key: const Key('workProjectsCard'),
          title: 'Jobs / Projects',
          subtitle: 'Track active and completed delivery work.',
          icon: Icons.work_outline_rounded,
          color: AppColors.purple,
          onTap: () => _push(context, JobsScreen(api: api)),
        ),
        CommercialHubCard(
          key: const Key('workTasksCard'),
          title: 'Tasks',
          subtitle: 'Foundation route; currently opens Reminders safely.',
          icon: Icons.checklist_rounded,
          color: AppColors.success,
          badge: const CommercialStatusChip(
            label: 'Maps to reminders',
            icon: Icons.info_outline_rounded,
            color: AppColors.warning,
          ),
          onTap: () => _showTasksNotice(context),
        ),
        CommercialHubCard(
          key: const Key('workRemindersCard'),
          title: 'Reminders',
          subtitle: 'Create reminders and mark follow-ups as completed.',
          icon: Icons.notifications_active_outlined,
          color: AppColors.success,
          onTap: () => _push(context, RemindersScreen(api: api)),
        ),
        if (policy.availabilityFor('tasks') != NavigationAvailability.available)
          EntitlementNotice(
            title: 'Task module foundation',
            message: policy.availabilityMessage('tasks'),
            reason: 'future_task_api',
          ),
      ],
    );
  }

  String _workspaceSubtitle(CommercialSession? session) {
    final name = session?.branding.displayName.isNotEmpty == true
        ? session!.branding.displayName
        : session?.tenant.companyName;
    return name == null || name.isEmpty ? 'Commercial workspace' : name;
  }
}
