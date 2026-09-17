import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/workspace_banner.dart';
import '../../models/dashboard_data.dart';
import '../../models/invoice.dart';
import '../../models/turnover_report.dart';
import '../../services/crm_api.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({
    super.key,
    required this.api,
    this.initialData,
    this.active = true,
  });

  final CrmApi api;
  final DashboardData? initialData;
  final bool active;

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  DashboardData? _data;
  List<TurnoverReportRow>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _load();
  }

  @override
  void didUpdateWidget(covariant RevenueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await widget.api.fetchDashboard();
      final rows = await widget.api.fetchTurnoverReport();
      if (mounted) {
        setState(() {
          _data = data;
          _rows = rows;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('Turnover / Revenue')),
      body: _error != null && data == null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : data == null
          ? const LoadingView(label: 'Loading revenue summary…')
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  PremiumPageBanner(
                    session: widget.api.currentSession,
                    title: 'Monthly Turnover',
                    subtitle:
                        'Track invoice totals by invoice date. Quotes, expenses and outstanding balances stay out of this turnover view.',
                    icon: Icons.show_chart_rounded,
                    metrics: {
                      'No.': '${(_rows ?? const <TurnoverReportRow>[]).length}',
                      'Focus': 'Invoiced',
                    },
                  ),
                  const SizedBox(height: 12),
                  _MonthlyTurnoverTable(
                    rows: _rows ?? const <TurnoverReportRow>[],
                    currency:
                        widget.api.currentSession?.tenant.currency ?? 'GBP',
                  ),
                ],
              ),
            ),
    );
  }
}

class _MonthlyTurnoverTable extends StatelessWidget {
  const _MonthlyTurnoverTable({required this.rows, required this.currency});

  final List<TurnoverReportRow> rows;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Monthly Turnover',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Turnover is based on valid invoice totals by invoice date. Costs are tracked separately and are not deducted.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (rows.isEmpty)
              const Text(
                'No turnover rows yet.',
                style: TextStyle(color: AppColors.muted),
              )
            else
              ...rows.asMap().entries.map((entry) {
                final row = entry.value;
                return _TurnoverRowCard(
                  index: entry.key + 1,
                  month: _monthLabel(row.month),
                  totalInvoices: row.totalInvoices,
                  totalInvoiced: moneyFromMinorUnits(
                    row.totalInvoiced,
                    currency: currency,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _monthLabel(String value) {
    const labels = {
      '01': 'January',
      '02': 'February',
      '03': 'March',
      '04': 'April',
      '05': 'May',
      '06': 'June',
      '07': 'July',
      '08': 'August',
      '09': 'September',
      '10': 'October',
      '11': 'November',
      '12': 'December',
    };
    if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(value)) return value;
    final parts = value.split('-');
    return '${labels[parts[1]] ?? parts[1]} ${parts[0]}';
  }
}

class _TurnoverRowCard extends StatelessWidget {
  const _TurnoverRowCard({
    required this.index,
    required this.month,
    required this.totalInvoices,
    required this.totalInvoiced,
  });

  final int index;
  final String month;
  final int totalInvoices;
  final String totalInvoiced;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.lightBlue,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD7E6F7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _TurnoverMetric(label: 'No.', value: '$index', compact: true),
            _TurnoverMetric(label: 'Month', value: month),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _TurnoverMetric(label: 'Total Invoices', value: '$totalInvoices'),
            _TurnoverMetric(label: 'Total Invoiced', value: totalInvoiced),
          ],
        ),
      ],
    ),
  );
}

class _TurnoverMetric extends StatelessWidget {
  const _TurnoverMetric({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minWidth: compact ? 54 : 180),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}
