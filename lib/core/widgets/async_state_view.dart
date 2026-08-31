import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'commercial_components.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Loading…'});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: label,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final Object message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: AppColors.muted,
            semanticLabel: 'Unable to load',
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            CommercialErrorPresenter.friendlyMessage(message),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            key: const Key('retryButton'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.message,
    required this.icon,
    this.title,
    this.action,
  });

  final String message;
  final IconData icon;
  final String? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.muted, semanticLabel: title),
          const SizedBox(height: AppSpacing.lg),
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ],
        ],
      ),
    ),
  );
}
