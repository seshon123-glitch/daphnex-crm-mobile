import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../models/dashboard_data.dart';
import '../../services/crm_api.dart';
import '../documents/documents_screen.dart';
import '../invoices/invoices_screen.dart';
import '../jobs/jobs_screen.dart';
import '../notifications/notifications_screen.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await widget.api.fetchDashboard();
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text('Daphnex CRM'),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: CircleAvatar(
              backgroundColor: AppColors.lightBlue,
              child: Text(
                'D',
                style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _error != null && _data == null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : _data == null
          ? const LoadingView(label: 'Loading dashboard…')
          : RefreshIndicator(
              onRefresh: _load,
              child: _DashboardContent(
                api: widget.api,
                data: _data!,
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
    this.onOpenClients,
    this.onOpenTasks,
    this.onOpenMore,
  });

  final CrmApi api;
  final DashboardData data;
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navy, AppColors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Business overview',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your live CRM,\nwherever work takes you.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.sync_rounded, color: Color(0xFF9BE6BE), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                onPressed: onOpenMore,
                icon: const Icon(Icons.apps_rounded),
                label: const Text('Open modules'),
              ),
            ],
          ),
        ),
        if (data.isFallback) ...[
          const SizedBox(height: 14),
          Container(
            key: const Key('dashboardFallback'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF9A6700)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'CRM unavailable — showing development fallback data.',
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'At a glance',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.16,
          children: [
            _StatCard(
              label: 'Total Clients',
              value: '${data.totalClients}',
              icon: Icons.people_rounded,
              color: AppColors.blue,
              onTap: onOpenClients,
            ),
            _StatCard(
              label: 'Active Jobs / Projects',
              value: '${data.activeJobs}',
              icon: Icons.work_outline_rounded,
              color: const Color(0xFF7B61D1),
              onTap: () => _open(context, JobsScreen(api: api)),
            ),
            _StatCard(
              label: 'Pending Invoices',
              value: '${data.pendingInvoices}',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFFF59E0B),
              onTap: () => _open(context, InvoicesScreen(api: api)),
            ),
            _StatCard(
              label: 'Upcoming Tasks',
              value: '${data.upcomingReminders}',
              icon: Icons.notifications_active_outlined,
              color: const Color(0xFF10A874),
              onTap: onOpenTasks,
            ),
            _StatCard(
              label: 'Unpaid Invoices',
              value: '${data.unpaidInvoices}',
              icon: Icons.payments_outlined,
              color: const Color(0xFFDC2626),
              onTap: () => _open(context, InvoicesScreen(api: api)),
            ),
            _StatCard(
              label: 'Outstanding',
              value: moneyLabel(data.outstandingInvoiceAmount),
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF0891B2),
              onTap: () =>
                  _open(context, RevenueScreen(api: api, initialData: data)),
            ),
            _StatCard(
              label: 'Completed Jobs / Projects',
              value: '${data.completedJobs}',
              icon: Icons.task_alt_rounded,
              color: const Color(0xFF16A34A),
              onTap: () => _open(context, JobsScreen(api: api)),
            ),
            _StatCard(
              label: 'Unread Alerts',
              value: '${data.unreadNotifications}',
              icon: Icons.mark_email_unread_outlined,
              color: const Color(0xFF9333EA),
              onTap: () => _open(context, NotificationsScreen(api: api)),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          'Quick actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.08,
          children: [
            _ShortcutCard(
              title: 'Clients',
              subtitle: 'Search profiles',
              icon: Icons.people_alt_outlined,
              color: AppColors.blue,
              onTap: onOpenClients,
            ),
            _ShortcutCard(
              title: 'Tasks',
              subtitle: 'Reminders today',
              icon: Icons.checklist_rounded,
              color: const Color(0xFF10A874),
              onTap: onOpenTasks,
            ),
            _ShortcutCard(
              title: 'Invoices',
              subtitle: 'Balances & status',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFFF59E0B),
              onTap: () => _open(context, InvoicesScreen(api: api)),
            ),
            _ShortcutCard(
              title: 'Jobs / Projects',
              subtitle: 'Active delivery',
              icon: Icons.work_outline_rounded,
              color: const Color(0xFF7B61D1),
              onTap: () => _open(context, JobsScreen(api: api)),
            ),
            _ShortcutCard(
              title: 'Documents',
              subtitle: 'Client files',
              icon: Icons.folder_copy_outlined,
              color: const Color(0xFF0891B2),
              onTap: () => _open(context, DocumentsScreen(api: api)),
            ),
            _ShortcutCard(
              title: 'Notifications',
              subtitle: 'Unread alerts',
              icon: Icons.mark_email_unread_outlined,
              color: const Color(0xFF9333EA),
              onTap: () => _open(context, NotificationsScreen(api: api)),
            ),
            _ShortcutCard(
              title: 'Turnover / Revenue',
              subtitle: 'Finance snapshot',
              icon: Icons.insights_rounded,
              color: const Color(0xFF0F766E),
              onTap: () =>
                  _open(context, RevenueScreen(api: api, initialData: data)),
            ),
            _ShortcutCard(
              title: 'More',
              subtitle: 'Full menu',
              icon: Icons.apps_rounded,
              color: AppColors.navy,
              onTap: onOpenMore,
            ),
          ],
        ),
        const SizedBox(height: 26),
        _RevenueSummaryCard(data: data),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueSummaryCard extends StatelessWidget {
  const _RevenueSummaryCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights_rounded, color: AppColors.blue),
                SizedBox(width: 10),
                Text(
                  'Turnover / Revenue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _RevenueRow(
              label: 'Outstanding invoice amount',
              value: moneyLabel(data.outstandingInvoiceAmount),
            ),
            _RevenueRow(
              label: 'Unpaid invoices',
              value: '${data.unpaidInvoices}',
            ),
            const SizedBox(height: 10),
            const Text(
              'Paid/completed financial totals will be connected when the '
              'turnover API is available.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String moneyLabel(int value) => '£${(value / 100).toStringAsFixed(0)}';
