import 'package:flutter/material.dart';

import '../../core/config/app_info.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/commercial_components.dart';
import '../../models/commercial_session.dart';
import '../../services/crm_api.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key, required this.api});

  final CrmApi api;

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileState();
}

class BrandingScreen extends StatefulWidget {
  const BrandingScreen({super.key, required this.api});

  final CrmApi api;

  @override
  State<BrandingScreen> createState() => _BrandingState();
}

class PlanAccountScreen extends StatefulWidget {
  const PlanAccountScreen({super.key, required this.api});

  final CrmApi api;

  @override
  State<PlanAccountScreen> createState() => _PlanAccountState();
}

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key, required this.api});

  final CrmApi api;

  @override
  State<MyProfileScreen> createState() => _MyProfileState();
}

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key, required this.api});

  final CrmApi api;

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsState();
}

class TeamFoundationScreen extends StatefulWidget {
  const TeamFoundationScreen({super.key, required this.api});

  final CrmApi api;

  @override
  State<TeamFoundationScreen> createState() => _TeamFoundationState();
}

class FeatureAccessScreen extends StatefulWidget {
  const FeatureAccessScreen({super.key, required this.api});

  final CrmApi api;

  @override
  State<FeatureAccessScreen> createState() => _FeatureAccessState();
}

class _CompanyProfileState
    extends _SessionBackedScreenState<CompanyProfileScreen> {}

class _BrandingState extends _SessionBackedScreenState<BrandingScreen> {}

class _PlanAccountState extends _SessionBackedScreenState<PlanAccountScreen> {}

class _MyProfileState extends _SessionBackedScreenState<MyProfileScreen> {}

class _CompanySettingsState
    extends _SessionBackedScreenState<CompanySettingsScreen> {}

class _TeamFoundationState
    extends _SessionBackedScreenState<TeamFoundationScreen> {}

class _FeatureAccessState
    extends _SessionBackedScreenState<FeatureAccessScreen> {}

class _SessionBackedScreenState<T extends StatefulWidget> extends State<T> {
  bool _refreshing = false;
  Object? _error;

  CrmApi get _api => switch (widget) {
    CompanyProfileScreen(:final api) => api,
    BrandingScreen(:final api) => api,
    PlanAccountScreen(:final api) => api,
    MyProfileScreen(:final api) => api,
    CompanySettingsScreen(:final api) => api,
    TeamFoundationScreen(:final api) => api,
    FeatureAccessScreen(:final api) => api,
    _ => throw StateError('Unsupported account screen'),
  };

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      await _api.bootstrapSession();
    } catch (error) {
      _error = error;
    }
    if (!mounted) return;
    setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = _api.currentSession;
    final actions = [
      IconButton(
        key: const Key('accountRefreshButton'),
        tooltip: 'Refresh account session',
        onPressed: _refreshing ? null : _refresh,
        icon: _refreshing
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh_rounded),
      ),
    ];

    final error = _error;
    final prefix = <Widget>[
      if (error != null)
        EntitlementNotice(
          title: 'Account refresh failed',
          message: CommercialErrorPresenter.friendlyMessage(error),
        ),
      if (session == null)
        const EntitlementNotice(
          title: 'No active company session',
          message: 'Please log in again to load your commercial workspace.',
        ),
    ];

    return switch (widget) {
      CompanyProfileScreen() => _companyProfile(
        context,
        session,
        actions,
        prefix,
      ),
      BrandingScreen() => _branding(context, session, actions, prefix),
      PlanAccountScreen() => _planAccount(context, session, actions, prefix),
      MyProfileScreen() => _myProfile(context, session, actions, prefix),
      CompanySettingsScreen() => _companySettings(
        context,
        session,
        actions,
        prefix,
      ),
      TeamFoundationScreen() => _team(context, session, actions, prefix),
      FeatureAccessScreen() => _featureAccess(
        context,
        session,
        actions,
        prefix,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _companyProfile(
    BuildContext context,
    CommercialSession? session,
    List<Widget> actions,
    List<Widget> prefix,
  ) {
    final profile = session?.companyProfile;
    final role = session?.membership.role;
    return CommercialPage(
      title: 'Company Profile',
      subtitle: 'Business identity',
      actions: actions,
      children: [
        ...prefix,
        _HeaderCard(
          title: profile?.companyName ?? 'Company unavailable',
          subtitle: role == null
              ? 'Commercial workspace'
              : '${_roleLabel(role)} access · server-authoritative',
          icon: Icons.business_rounded,
        ),
        const CommercialSectionHeader(title: 'Company details'),
        _InfoCard(
          rows: [
            _InfoRow('Company name', profile?.companyName),
            _InfoRow('Trading name', profile?.tradingName),
            _InfoRow('Email', profile?.email),
            _InfoRow('Phone', profile?.phone),
            _InfoRow('Website', profile?.website),
            _InfoRow('Currency', profile?.currency),
          ],
        ),
        EntitlementNotice(
          title: profile?.canEdit == true
              ? 'Safe editing prepared'
              : 'Read-only on mobile',
          message: profile?.canEdit == true
              ? 'This screen is ready for small profile edits once the mobile update endpoint is approved.'
              : 'Company profile changes remain controlled by the server until a safe mobile edit endpoint is enabled.',
        ),
      ],
    );
  }

  Widget _branding(
    BuildContext context,
    CommercialSession? session,
    List<Widget> actions,
    List<Widget> prefix,
  ) {
    final branding = session?.branding;
    return CommercialPage(
      title: 'Branding',
      subtitle: 'Workspace presentation',
      actions: actions,
      children: [
        ...prefix,
        Card(
          key: const Key('brandingPreviewCard'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const DaphnexLogoMark(size: 72),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  branding?.displayName.isNotEmpty == true
                      ? branding!.displayName
                      : 'Daphnex CRM',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Accent ${branding?.accentColor ?? '#147DE8'}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
        const CommercialSectionHeader(title: 'Brand assets'),
        _InfoCard(
          rows: [
            _InfoRow('Display name', branding?.displayName),
            _InfoRow('Initials', branding?.initials),
            _InfoRow('Logo URL', branding?.logoUrl),
            _InfoRow('Accent colour', branding?.accentColor),
          ],
        ),
        EntitlementNotice(
          title: branding?.canEdit == true
              ? 'Brand editing prepared'
              : 'Branding is read-only',
          message:
              'Logo upload and colour changes will stay server-authoritative until the commercial branding update endpoint is approved.',
        ),
      ],
    );
  }

  Widget _planAccount(
    BuildContext context,
    CommercialSession? session,
    List<Widget> actions,
    List<Widget> prefix,
  ) {
    final entitlements = session?.entitlements;
    final plan = entitlements?.plan;
    final usage = entitlements?.usage.values.toList(growable: false) ?? [];
    return CommercialPage(
      title: 'Plan & Account',
      subtitle: 'Current access and limits',
      actions: actions,
      children: [
        ...prefix,
        _HeaderCard(
          title: plan?.label.isNotEmpty == true ? plan!.label : 'Plan unknown',
          subtitle: entitlements?.status.isNotEmpty == true
              ? 'Status: ${entitlements!.status}'
              : 'Server-authoritative entitlement state',
          icon: Icons.workspace_premium_outlined,
          badge: plan?.internalOnly == true
              ? const CommercialStatusChip(
                  label: 'Internal',
                  icon: Icons.lock_outline_rounded,
                  color: AppColors.purple,
                )
              : null,
        ),
        if (plan?.description.isNotEmpty == true)
          _PlainCard(text: plan!.description),
        const CommercialSectionHeader(
          title: 'Usage and limits',
          subtitle:
              'The backend remains the authority for all limits and lifecycle checks.',
        ),
        if (usage.isEmpty)
          const EntitlementNotice(
            title: 'Usage data not returned yet',
            message:
                'Usage will appear here when the account API returns limit counters.',
          )
        else
          ...usage.map(_UsageCard.new),
        if (entitlements?.placeholderNotice.isNotEmpty == true)
          EntitlementNotice(
            title: 'Plan note',
            message: entitlements!.placeholderNotice,
          ),
      ],
    );
  }

  Widget _myProfile(
    BuildContext context,
    CommercialSession? session,
    List<Widget> actions,
    List<Widget> prefix,
  ) {
    final user = session?.user;
    final membership = session?.membership;
    return CommercialPage(
      title: 'My Profile',
      subtitle: 'Signed-in CRM user',
      actions: actions,
      children: [
        ...prefix,
        _HeaderCard(
          title: user?.displayName.isNotEmpty == true
              ? user!.displayName
              : 'CRM user',
          subtitle: user?.email ?? 'Email unavailable',
          icon: Icons.person_outline_rounded,
        ),
        const CommercialSectionHeader(title: 'Membership'),
        _InfoCard(
          rows: [
            _InfoRow('Role', membership?.roleLabel ?? membership?.role.name),
            _InfoRow('Membership status', membership?.status),
            _InfoRow(
              'Workspace access',
              membership?.active == true ? 'Active' : 'Inactive',
            ),
          ],
        ),
        const EntitlementNotice(
          title: 'Profile editing is not enabled yet',
          message:
              'Personal profile changes will be added after the backend exposes a safe mobile profile update endpoint.',
        ),
      ],
    );
  }

  Widget _companySettings(
    BuildContext context,
    CommercialSession? session,
    List<Widget> actions,
    List<Widget> prefix,
  ) {
    final tenant = session?.tenant;
    return CommercialPage(
      title: 'Company Settings',
      subtitle: 'Workspace configuration',
      actions: actions,
      children: [
        ...prefix,
        _HeaderCard(
          title: tenant?.companyName ?? 'Workspace unavailable',
          subtitle: tenant?.status.isNotEmpty == true
              ? 'Lifecycle: ${tenant!.status}'
              : 'Lifecycle state unavailable',
          icon: Icons.settings_outlined,
        ),
        const CommercialSectionHeader(title: 'Workspace'),
        _InfoCard(
          rows: [
            _InfoRow('Tenant ID', tenant?.id == null ? null : '${tenant!.id}'),
            _InfoRow('Slug', tenant?.slug),
            _InfoRow('Currency', tenant?.currency),
            _InfoRow('Timezone', tenant?.timezone),
          ],
        ),
        EntitlementNotice(
          title: tenant?.isActive == true
              ? 'Workspace active'
              : 'Workspace inactive',
          message: tenant?.isActive == true
              ? 'Mobile access is available while membership and tenant lifecycle checks remain active.'
              : 'This workspace is not active. Server-side access restrictions remain enforced.',
          reason: tenant?.status,
        ),
      ],
    );
  }

  Widget _team(
    BuildContext context,
    CommercialSession? session,
    List<Widget> actions,
    List<Widget> prefix,
  ) {
    final role = session?.membership.role ?? CommercialRole.staff;
    final canManage = role.canManageTeam;
    return CommercialPage(
      title: 'Team',
      subtitle: 'Membership foundation',
      actions: actions,
      children: [
        ...prefix,
        _HeaderCard(
          title: canManage
              ? 'Team management foundation'
              : 'Team access restricted',
          subtitle: canManage
              ? 'Owner/Admin visibility prepared'
              : 'Staff cannot manage workspace members',
          icon: Icons.group_outlined,
          badge: CommercialStatusChip(
            label: _roleLabel(role),
            icon: Icons.verified_user_outlined,
            color: canManage ? AppColors.success : AppColors.warning,
          ),
        ),
        const CommercialSectionHeader(title: 'Current member'),
        _InfoCard(
          rows: [
            _InfoRow('Name', session?.user.displayName),
            _InfoRow('Email', session?.user.email),
            _InfoRow('Role', session?.membership.roleLabel),
            _InfoRow('Status', session?.membership.status),
          ],
        ),
        EntitlementNotice(
          title: canManage
              ? 'Invite UI pending backend contract'
              : 'Read-only membership',
          message: canManage
              ? 'The mobile team hub is ready to connect once member list, invite and role-change endpoints are approved.'
              : 'Staff users can view their own membership only. Team management remains hidden and server-enforced.',
        ),
      ],
    );
  }

  Widget _featureAccess(
    BuildContext context,
    CommercialSession? session,
    List<Widget> actions,
    List<Widget> prefix,
  ) {
    final features =
        session?.entitlements.features.values.toList(growable: false) ?? [];
    features.sort((a, b) => a.key.compareTo(b.key));
    return CommercialPage(
      title: 'Feature Access',
      subtitle: 'Entitlement visibility',
      actions: actions,
      children: [
        ...prefix,
        const EntitlementNotice(
          title: 'Server-authoritative access',
          message:
              'Unavailable features are shown as locked. The server remains the source of truth for every CRM action.',
        ),
        const CommercialSectionHeader(title: 'Features'),
        if (features.isEmpty)
          const EntitlementNotice(
            title: 'No feature map returned',
            message:
                'Feature access details will appear here when the entitlement API returns a feature map.',
          )
        else
          ...features.map(_FeatureCard.new),
      ],
    );
  }

  String _roleLabel(CommercialRole role) =>
      '${role.name[0].toUpperCase()}${role.name.substring(1)}';
}

class AboutDaphnexCommercialScreen extends StatelessWidget {
  const AboutDaphnexCommercialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommercialPage(
      title: 'About Daphnex CRM',
      subtitle: 'Commercial mobile foundation',
      children: [
        _HeaderCard(
          title: 'Daphnex CRM Mobile',
          subtitle: 'Daphnex Limited · https://daphnex.co.uk',
          icon: Icons.info_outline_rounded,
        ),
        CommercialSectionHeader(title: 'Support'),
        _InfoCard(
          rows: [
            _InfoRow('Company', 'Daphnex Limited'),
            _InfoRow('Website', 'https://daphnex.co.uk'),
            _InfoRow('Support email', 'support@daphnex.co.uk'),
            _InfoRow('App version', AppInfo.version),
          ],
        ),
        EntitlementNotice(
          title: 'Commercial roadmap',
          message:
              'Native registration, billing and subscription changes are intentionally excluded from this phase.',
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Icon(icon, color: AppColors.blue),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: AppSpacing.md),
              badge!,
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (final row in rows.where(
              (row) => row.valueOrFallback.isNotEmpty,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        row.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 3,
                      child: Text(
                        row.valueOrFallback,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String? value;

  String get valueOrFallback => value?.trim() ?? '';
}

class _PlainCard extends StatelessWidget {
  const _PlainCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard(this.limit);

  final UsageLimit limit;

  @override
  Widget build(BuildContext context) {
    final label = limit.label.isNotEmpty
        ? limit.label
        : limit.key.replaceAll('_', ' ');
    final max = limit.limit;
    final value = max == null || max <= 0 ? 0.0 : limit.usage / max;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                CommercialStatusChip(
                  label: max == null ? '${limit.usage}' : '${limit.usage}/$max',
                  color: value >= 1 ? AppColors.danger : AppColors.blue,
                ),
              ],
            ),
            if (max != null && max > 0) ...[
              const SizedBox(height: AppSpacing.md),
              LinearProgressIndicator(value: value.clamp(0, 1)),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(this.feature);

  final FeatureEntitlement feature;

  @override
  Widget build(BuildContext context) {
    final title = feature.label.isNotEmpty
        ? feature.label
        : feature.key.replaceAll('_', ' ');
    return Card(
      child: ListTile(
        leading: Icon(
          feature.allowed
              ? Icons.check_circle_outline_rounded
              : Icons.lock_outline_rounded,
          color: feature.allowed ? AppColors.success : AppColors.warning,
        ),
        title: Text(title),
        subtitle: Text(
          feature.message.isNotEmpty
              ? feature.message
              : feature.allowed
              ? 'Available'
              : 'Unavailable for this workspace',
        ),
        trailing: CommercialStatusChip(
          label: feature.allowed ? 'Available' : 'Locked',
          color: feature.allowed ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }
}
