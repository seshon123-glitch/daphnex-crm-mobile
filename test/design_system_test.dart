import 'package:daphnex_crm_mobile/core/errors/api_exception.dart';
import 'package:daphnex_crm_mobile/core/theme/app_theme.dart';
import 'package:daphnex_crm_mobile/core/widgets/async_state_view.dart';
import 'package:daphnex_crm_mobile/core/widgets/commercial_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('commercial theme and state components render clearly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ListView(
            children: [
              CommercialHubCard(
                title: 'Clients',
                subtitle: 'Manage customer records.',
                icon: Icons.people_outline,
                onTap: () {},
              ),
              const CommercialStatusChip(
                label: 'Active',
                icon: Icons.check_circle_outline,
              ),
              const EntitlementNotice(
                title: 'Upgrade required',
                message: 'This feature is available on another plan.',
                reason: 'feature_not_in_plan',
              ),
              const EmptyStateView(
                title: 'No clients yet',
                message: 'Create your first client to get started.',
                icon: Icons.people_outline,
              ),
              ErrorStateView(
                message: const ApiException(
                  'Network failure',
                  category: ApiErrorCategory.networkProblem,
                ),
                onRetry: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Clients'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Upgrade required'), findsOneWidget);
    expect(find.text('No clients yet'), findsOneWidget);
    expect(
      find.textContaining('live CRM server could not be reached'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
