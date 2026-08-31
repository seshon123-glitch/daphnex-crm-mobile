import 'package:flutter/material.dart';

import '../errors/api_exception.dart';
import '../theme/app_theme.dart';

class CommercialPage extends StatelessWidget {
  const CommercialPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 112),
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(
        top: false,
        child: ListView(padding: padding, children: children),
      ),
    );
  }
}

class CommercialSectionHeader extends StatelessWidget {
  const CommercialSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class CommercialHubCard extends StatelessWidget {
  const CommercialHubCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.badge,
    this.enabled = true,
    this.color = AppColors.blue,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? badge;
  final bool enabled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: enabled ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  icon,
                  color: enabled ? color : AppColors.muted,
                  semanticLabel: title,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: enabled
                                      ? AppColors.text
                                      : AppColors.muted,
                                ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          badge!,
                        ],
                      ],
                    ),
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
              const SizedBox(width: AppSpacing.sm),
              Icon(
                enabled
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommercialStatusChip extends StatelessWidget {
  const CommercialStatusChip({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.blue,
  });

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EntitlementNotice extends StatelessWidget {
  const EntitlementNotice({
    super.key,
    required this.title,
    required this.message,
    this.reason,
  });

  final String title;
  final String message;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.workspace_premium_outlined, color: AppColors.blue),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  if (reason != null && reason!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    CommercialStatusChip(
                      label: reason!.replaceAll('_', ' '),
                      icon: Icons.info_outline_rounded,
                      color: AppColors.warning,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommercialErrorPresenter {
  const CommercialErrorPresenter._();

  static String friendlyMessage(Object error) {
    if (error is ApiException) {
      switch (error.category) {
        case ApiErrorCategory.networkProblem:
          return 'The live CRM server could not be reached. Check your connection and try again.';
        case ApiErrorCategory.sessionExpired:
          return 'Your session has expired. Please log in again.';
        case ApiErrorCategory.accessRemoved:
          return 'Your access to this company workspace has changed. Please log in again.';
        case ApiErrorCategory.featureUnavailable:
          return 'This feature is not available for your account yet.';
        case ApiErrorCategory.limitReached:
          return 'This account has reached its current usage limit.';
        case ApiErrorCategory.temporaryServiceProblem:
          return 'The CRM service is temporarily unavailable. Please try again shortly.';
        default:
          return error.message;
      }
    }
    return error.toString();
  }
}
