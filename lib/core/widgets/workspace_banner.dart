import 'package:flutter/material.dart';

import '../../models/commercial_session.dart';
import '../theme/app_theme.dart';

class WorkspaceBanner extends StatelessWidget {
  const WorkspaceBanner({
    super.key,
    required this.session,
    this.compact = true,
  });

  final CommercialSession? session;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final company = session?.branding.displayName.isNotEmpty == true
        ? session!.branding.displayName
        : session?.tenant.companyName ?? 'Daphnex CRM';
    final initials = session?.branding.initials.isNotEmpty == true
        ? session!.branding.initials
        : _initials(company);
    final role = session?.membership.roleLabel.isNotEmpty == true
        ? session!.membership.roleLabel
        : 'Workspace';

    return Semantics(
      label: 'Current company workspace: $company, role $role',
      child: Container(
        key: const Key('workspaceIdentityBanner'),
        padding: EdgeInsets.all(compact ? 14 : 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navy, AppColors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 42 : 52,
              height: compact ? 42 : 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(compact ? 14 : 18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 15 : 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 17 : 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Daphnex CRM Mobile',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  role,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'DX';
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}

class WorkspaceWelcomeBanner extends StatelessWidget {
  const WorkspaceWelcomeBanner({super.key, required this.session});

  final CommercialSession? session;

  @override
  Widget build(BuildContext context) {
    final company = session?.branding.displayName.isNotEmpty == true
        ? session!.branding.displayName
        : session?.tenant.companyName ?? '';
    final user = _firstName(
      session?.user.displayName ?? session?.user.email ?? '',
    );
    final greeting = company.isEmpty
        ? 'Welcome, $user 👋'
        : 'Welcome to $company, $user 👋';
    final message = company.isEmpty
        ? 'Manage your customers, projects, tasks, reminders, invoices, expenses and payments all in one place. Stay on top of outstanding balances, track your monthly turnover and keep your business organised with Daphnex CRM.'
        : 'Your business workspace is ready. Manage customers, projects, tasks, reminders, invoices, expenses and payments, monitor outstanding balances, and track your monthly turnover — all from one place.';

    return Semantics(
      label: greeting,
      child: Container(
        key: const Key('workspaceWelcomeBanner'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.lightBlue),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WorkspaceBanner(session: session, compact: true),
            const SizedBox(height: 16),
            Text(
              greeting,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  String _firstName(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return 'there';
    return clean.split(RegExp(r'\s+|@')).first;
  }
}

class PremiumPageBanner extends StatelessWidget {
  const PremiumPageBanner({
    super.key,
    required this.session,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.metrics = const {},
  });

  final CommercialSession? session;
  final String title;
  final String subtitle;
  final IconData icon;
  final Map<String, String> metrics;

  @override
  Widget build(BuildContext context) {
    final company = session?.branding.displayName.isNotEmpty == true
        ? session!.branding.displayName
        : session?.tenant.companyName ?? 'Daphnex CRM';
    return Container(
      key: Key('${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-premiumBanner'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.4,
            ),
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: metrics.entries
                  .map(
                    (entry) => _PremiumMetric(
                      label: entry.key,
                      value: entry.value,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PremiumMetric extends StatelessWidget {
  const _PremiumMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 118),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        ),
      ],
    ),
  );
}
