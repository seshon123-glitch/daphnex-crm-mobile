import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/commercial_components.dart';
import '../../models/commercial_session.dart';
import '../../models/crm_notification.dart';
import '../../models/dashboard_data.dart';
import '../../services/crm_api.dart';
import '../documents/documents_screen.dart';
import '../invoices/invoices_screen.dart';
import '../jobs/jobs_screen.dart';
import '../notifications/notifications_screen.dart';
import '../reminders/reminders_screen.dart';
import '../revenue/revenue_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.api,
    this.onOpenClients,
    this.onOpenTasks,
    this.onOpenMore,
  });

  final CrmApi api;
  final VoidCallback? onOpenClients;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenMore;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardData? _data;
  List<CrmNotification> _activity = const [];
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait<Object>([
        widget.api.fetchDashboard(),
        widget.api.fetchNotifications(),
      ]);
      if (!mounted) return;
      setState(() {
        _data = results[0] as DashboardData;
        _activity = (results[1] as List<CrmNotification>).take(3).toList();
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: _CompanyAvatar(session: widget.api.currentSession),
          ),
        ],
      ),
      body: _error != null && data == null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : data == null
          ? const LoadingView(label: 'Loading your dashboard…')
          : RefreshIndicator(
              onRefresh: _load,
              child: _DashboardContent(
                api: widget.api,
                data: data,
                activity: _activity,
                session: widget.api.currentSession,
                onOpenClients: widget.onOpenClients,
                onOpenTasks: widget.onOpenTasks,
                onOpenMore: widget.onOpenMore,
              ),
            ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.api,
    required this.data,
    required this.activity,
    required this.session,
    this.onOpenClients,
    this.onOpenTasks,
    this.onOpenMore,
  });

  final CrmApi api;
  final DashboardData data;
  final List<CrmNotification> activity;
  final CommercialSession? session;
  final VoidCallback? onOpenClients;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenMore;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('dashboardScroll'),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 112),
      children: [
        _DashboardHeader(key: const Key('dashboardHeader'), session: session),
        if (data.isFallback) ...[
          const SizedBox(height: AppSpacing.lg),
          const _FallbackNotice(),
        ],
        const SizedBox(height: AppSpacing.xl),
        _NeedsAttentionSection(
          key: const Key('needsAttentionSection'),
          data: data,
          onOpenInvoices: () => _open(context, InvoicesScreen(api: api)),
          onOpenReminders: () => _open(context, RemindersScreen(api: api)),
          onOpenJobs: () => _open(context, JobsScreen(api: api)),
          onOpenNotifications: () =>
              _open(context, NotificationsScreen(api: api)),
        ),
        const SizedBox(height: AppSpacing.xl),
        _KpiSection(
          key: const Key('kpiSection'),
          data: data,
          onOpenClients: onOpenClients,
          onOpenJobs: () => _open(context, JobsScreen(api: api)),
          onOpenRevenue: () =>
              _open(context, RevenueScreen(api: api, initialData: data)),
          onOpenTasks: onOpenTasks,
        ),
        const SizedBox(height: AppSpacing.xl),
        _QuickActionsSection(
          key: const Key('quickActionsSection'),
          onOpenClients: onOpenClients,
          onOpenTasks: onOpenTasks,
          onOpenInvoices: () => _open(context, InvoicesScreen(api: api)),
          onOpenJobs: () => _open(context, JobsScreen(api: api)),
          onOpenDocuments: () => _open(context, DocumentsScreen(api: api)),
          onOpenMore: onOpenMore,
        ),
        const SizedBox(height: AppSpacing.xl),
        _RecentActivitySection(
          key: const Key('recentActivitySection'),
          activity: activity,
          onOpenNotifications: () =>
              _open(context, NotificationsScreen(api: api)),
        ),
        const SizedBox(height: AppSpacing.xl),
        _RevenueSummaryCard(
          key: const Key('financeSummarySection'),
          data: data,
          onTap: () =>
              _open(context, RevenueScreen(api: api, initialData: data)),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({super.key, required this.session});

  final CommercialSession? session;

  @override
  Widget build(BuildContext context) {
    final company = _companyName(session);
    final user = _userName(session);
    final roleLabel = _roleLabel(session);
    final planLabel = session?.entitlements.plan.label ?? '';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()}, $user',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      company,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: Colors.white, fontSize: 26),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              _CompanyAvatar(session: session, large: true),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              CommercialStatusChip(
                label: roleLabel,
                icon: Icons.verified_user_outlined,
                color: Colors.white,
              ),
              if (planLabel.isNotEmpty)
                CommercialStatusChip(
                  label: planLabel,
                  icon: Icons.workspace_premium_outlined,
                  color: const Color(0xFF9BE6BE),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Here is what needs your attention today.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.90),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedsAttentionSection extends StatelessWidget {
  const _NeedsAttentionSection({
    super.key,
    required this.data,
    required this.onOpenInvoices,
    required this.onOpenReminders,
    required this.onOpenJobs,
    required this.onOpenNotifications,
  });

  final DashboardData data;
  final VoidCallback onOpenInvoices;
  final VoidCallback onOpenReminders;
  final VoidCallback onOpenJobs;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final items = _attentionItems();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CommercialSectionHeader(
          title: 'Needs Attention',
          subtitle: 'The most useful things to look at first.',
        ),
        if (items.isEmpty)
          const EmptyStateView(
            message: 'Nothing urgent right now.',
            icon: Icons.check_circle_outline_rounded,
          )
        else
          ...items.map((item) => _AttentionCard(item: item)),
      ],
    );
  }

  List<_AttentionItem> _attentionItems() {
    final items = <_AttentionItem>[];
    if (data.unpaidInvoices > 0 || data.outstandingInvoiceAmount > 0) {
      items.add(
        _AttentionItem(
          title: 'Invoices need attention',
          detail:
              '${data.unpaidInvoices} unpaid · ${moneyLabel(data.outstandingInvoiceAmount)} outstanding',
          icon: Icons.receipt_long_outlined,
          color: AppColors.warning,
          onTap: onOpenInvoices,
        ),
      );
    }
    if (data.upcomingReminders > 0) {
      items.add(
        _AttentionItem(
          title: 'Tasks due soon',
          detail:
              '${data.upcomingReminders} reminder${_plural(data.upcomingReminders)} coming up',
          icon: Icons.event_available_outlined,
          color: AppColors.success,
          onTap: onOpenReminders,
        ),
      );
    }
    if (data.activeJobs > 0) {
      items.add(
        _AttentionItem(
          title: 'Active jobs / projects',
          detail:
              '${data.activeJobs} open item${_plural(data.activeJobs)} in progress',
          icon: Icons.work_outline_rounded,
          color: AppColors.purple,
          onTap: onOpenJobs,
        ),
      );
    }
    if (data.unreadNotifications > 0) {
      items.add(
        _AttentionItem(
          title: 'Unread notifications',
          detail:
              '${data.unreadNotifications} update${_plural(data.unreadNotifications)} waiting',
          icon: Icons.mark_email_unread_outlined,
          color: AppColors.teal,
          onTap: onOpenNotifications,
        ),
      );
    }
    return items.take(4).toList();
  }
}

class _AttentionItem {
  const _AttentionItem({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.item});

  final _AttentionItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.detail,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiSection extends StatelessWidget {
  const _KpiSection({
    super.key,
    required this.data,
    required this.onOpenClients,
    required this.onOpenJobs,
    required this.onOpenRevenue,
    required this.onOpenTasks,
  });

  final DashboardData data;
  final VoidCallback? onOpenClients;
  final VoidCallback onOpenJobs;
  final VoidCallback onOpenRevenue;
  final VoidCallback? onOpenTasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CommercialSectionHeader(
          title: 'KPI Summary',
          subtitle: 'A short view of the live CRM numbers.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 390;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: compact ? 1 : 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: compact ? 2.0 : 1.25,
              children: [
                _KpiCard(
                  label: 'Clients',
                  value: '${data.totalClients}',
                  detail: 'Live client records',
                  icon: Icons.people_rounded,
                  color: AppColors.blue,
                  onTap: onOpenClients,
                ),
                _KpiCard(
                  label: 'Active Jobs',
                  value: '${data.activeJobs}',
                  detail: '${data.completedJobs} completed',
                  icon: Icons.work_outline_rounded,
                  color: AppColors.purple,
                  onTap: onOpenJobs,
                ),
                _KpiCard(
                  label: 'Outstanding',
                  value: moneyLabel(data.outstandingInvoiceAmount),
                  detail: '${data.unpaidInvoices} unpaid invoices',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.warning,
                  onTap: onOpenRevenue,
                ),
                _KpiCard(
                  label: 'Tasks Today',
                  value: '${data.upcomingReminders}',
                  detail: 'Mapped to reminders',
                  icon: Icons.checklist_rounded,
                  color: AppColors.success,
                  onTap: onOpenTasks,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$label, $value, $detail',
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const Spacer(),
                    if (onTap != null)
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.muted,
                        size: 18,
                      ),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    super.key,
    required this.onOpenClients,
    required this.onOpenTasks,
    required this.onOpenInvoices,
    required this.onOpenJobs,
    required this.onOpenDocuments,
    required this.onOpenMore,
  });

  final VoidCallback? onOpenClients;
  final VoidCallback? onOpenTasks;
  final VoidCallback onOpenInvoices;
  final VoidCallback onOpenJobs;
  final VoidCallback onOpenDocuments;
  final VoidCallback? onOpenMore;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        title: 'Clients',
        detail: 'Find a profile',
        icon: Icons.person_search_rounded,
        onTap: onOpenClients,
      ),
      _QuickAction(
        title: 'Tasks',
        detail: 'Open reminders',
        icon: Icons.add_task_rounded,
        onTap: onOpenTasks,
      ),
      _QuickAction(
        title: 'Invoices',
        detail: 'Create or review',
        icon: Icons.receipt_long_outlined,
        onTap: onOpenInvoices,
      ),
      _QuickAction(
        title: 'Jobs / Projects',
        detail: 'Manage work',
        icon: Icons.work_history_outlined,
        onTap: onOpenJobs,
      ),
      _QuickAction(
        title: 'Documents',
        detail: 'Open files',
        icon: Icons.folder_copy_outlined,
        onTap: onOpenDocuments,
      ),
      _QuickAction(
        title: 'More',
        detail: 'All modules',
        icon: Icons.apps_rounded,
        onTap: onOpenMore,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CommercialSectionHeader(
          title: 'Quick Actions',
          subtitle: 'Jump straight to common CRM work.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 620 ? 3 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: constraints.maxWidth < 360 ? 1.05 : 1.20,
              children: actions
                  .map(
                    (action) => _QuickActionCard(
                      action: action,
                      enabled: action.onTap != null,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.title,
    required this.detail,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String detail;
  final IconData icon;
  final VoidCallback? onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, required this.enabled});

  final _QuickAction action;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                action.icon,
                color: enabled ? AppColors.blue : AppColors.muted,
                size: 28,
              ),
              const Spacer(),
              Text(
                action.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                action.detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({
    super.key,
    required this.activity,
    required this.onOpenNotifications,
  });

  final List<CrmNotification> activity;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: CommercialSectionHeader(
                title: 'Recent Activity',
                subtitle: 'Latest CRM updates from notifications.',
              ),
            ),
            TextButton(
              onPressed: onOpenNotifications,
              child: const Text('Open alerts'),
            ),
          ],
        ),
        if (activity.isEmpty)
          const EmptyStateView(
            message: 'No recent activity yet.',
            icon: Icons.history_rounded,
          )
        else
          Card(
            child: Column(
              children: [
                for (var index = 0; index < activity.length; index++) ...[
                  _ActivityTile(notification: activity[index]),
                  if (index != activity.length - 1)
                    const Divider(height: 1, indent: 68),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.notification});

  final CrmNotification notification;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: CircleAvatar(
        backgroundColor: _activityColor.withValues(alpha: 0.12),
        child: Icon(_activityIcon, color: _activityColor),
      ),
      title: Text(
        notification.title.isEmpty ? 'CRM update' : notification.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        _activityDetail,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: notification.read
          ? const Icon(Icons.done_rounded, color: AppColors.muted)
          : const CommercialStatusChip(label: 'New', color: AppColors.blue),
    );
  }

  String get _activityDetail {
    final message = notification.message.trim();
    final createdAt = _friendlyDate(notification.createdAt);
    if (message.isEmpty) return createdAt;
    return createdAt.isEmpty ? message : '$message · $createdAt';
  }

  Color get _activityColor {
    if (notification.type.contains('invoice')) return AppColors.warning;
    if (notification.type.contains('reminder')) return AppColors.success;
    if (notification.type.contains('job')) return AppColors.purple;
    return AppColors.blue;
  }

  IconData get _activityIcon {
    if (notification.type.contains('invoice')) {
      return Icons.receipt_long_outlined;
    }
    if (notification.type.contains('reminder')) {
      return Icons.event_available_outlined;
    }
    if (notification.type.contains('job')) return Icons.work_outline_rounded;
    return Icons.notifications_none_rounded;
  }
}

class _RevenueSummaryCard extends StatelessWidget {
  const _RevenueSummaryCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  final DashboardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Revenue / Finance Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _RevenueRow(
                label: 'Outstanding invoice amount',
                value: moneyLabel(data.outstandingInvoiceAmount),
              ),
              _RevenueRow(
                label: 'Unpaid invoices',
                value: '${data.unpaidInvoices}',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Paid and completed turnover totals will appear when the '
                'turnover API is available.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  const _RevenueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('dashboardFallback'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.warning),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'CRM unavailable — showing development fallback data.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({required this.session, this.large = false});

  final CommercialSession? session;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(session);
    final size = large ? 58.0 : 42.0;
    return Semantics(
      label: 'Company initials $initials',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: large ? Colors.white : AppColors.lightBlue,
          borderRadius: BorderRadius.circular(large ? AppRadii.lg : 999),
          border: large
              ? Border.all(color: Colors.white.withValues(alpha: 0.45))
              : null,
        ),
        child: Text(
          initials,
          style: TextStyle(
            color: large ? AppColors.blue : AppColors.navy,
            fontSize: large ? 22 : 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

String _companyName(CommercialSession? session) {
  final branding = session?.branding.displayName.trim() ?? '';
  if (branding.isNotEmpty) return branding;
  final profile = session?.companyProfile.companyName.trim() ?? '';
  if (profile.isNotEmpty) return profile;
  final tenant = session?.tenant.companyName.trim() ?? '';
  return tenant.isEmpty ? 'Your company' : tenant;
}

String _userName(CommercialSession? session) {
  final name = session?.user.displayName.trim() ?? '';
  if (name.isEmpty) return 'there';
  return name.split(RegExp(r'\s+')).first;
}

String _roleLabel(CommercialSession? session) {
  final label = session?.membership.roleLabel.trim() ?? '';
  if (label.isNotEmpty) return label;
  final role = session?.membership.role ?? CommercialRole.staff;
  return switch (role) {
    CommercialRole.owner => 'Owner',
    CommercialRole.admin => 'Admin',
    CommercialRole.staff => 'Staff',
  };
}

String _initials(CommercialSession? session) {
  final branding = session?.branding.initials.trim() ?? '';
  if (branding.isNotEmpty) return branding.toUpperCase();
  final company = _companyName(session);
  final words = company
      .split(RegExp(r'\s+'))
      .where((word) => word.trim().isNotEmpty)
      .toList();
  if (words.isEmpty) return 'D';
  return words
      .take(2)
      .map((word) => word.characters.first)
      .join()
      .toUpperCase();
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

String _plural(int count) => count == 1 ? '' : 's';

String _friendlyDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  final local = date.toLocal();
  final now = DateTime.now();
  final sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (sameDay) return 'Today';
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

String moneyLabel(int value) => '£${(value / 100).toStringAsFixed(0)}';
