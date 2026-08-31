import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/commercial_components.dart';
import '../../models/commercial_session.dart';
import '../../services/crm_api.dart';
import '../invoices/invoices_screen.dart';
import '../revenue/revenue_screen.dart';

class FinanceHubScreen extends StatelessWidget {
  const FinanceHubScreen({super.key, required this.api});

  final CrmApi api;

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

    return CommercialPage(
      title: 'Finance',
      subtitle: _workspaceSubtitle(session),
      children: [
        const CommercialSectionHeader(
          title: 'Money in and money due',
          subtitle:
              'Customer invoices and live dashboard-backed financial summaries.',
        ),
        CommercialHubCard(
          key: const Key('financeInvoicesCard'),
          title: 'Invoices',
          subtitle: 'View invoices, create records, and update paid status.',
          icon: Icons.receipt_long_outlined,
          color: AppColors.warning,
          onTap: () => _push(context, InvoicesScreen(api: api)),
        ),
        CommercialHubCard(
          key: const Key('financePaymentsCard'),
          title: 'Payments',
          subtitle: 'Prepared for customer payment history and links.',
          icon: Icons.payments_outlined,
          color: AppColors.teal,
          badge: const CommercialStatusChip(
            label: 'Coming soon',
            icon: Icons.schedule_rounded,
            color: AppColors.warning,
          ),
          onTap: () => _comingSoon(context, 'Payments'),
        ),
        CommercialHubCard(
          key: const Key('financeRevenueCard'),
          title: 'Revenue / Financial Summary',
          subtitle: 'Outstanding invoice totals from the live dashboard API.',
          icon: Icons.insights_rounded,
          color: AppColors.success,
          onTap: () => _push(context, RevenueScreen(api: api)),
        ),
        const EntitlementNotice(
          title: 'Billing note',
          message:
              'This area is for your customer invoices. Daphnex subscription billing is separate and will not be added in this phase.',
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
