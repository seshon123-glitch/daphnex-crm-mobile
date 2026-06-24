import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../models/dashboard_data.dart';
import '../../services/crm_api.dart';
import '../dashboard/dashboard_screen.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key, required this.api, this.initialData});

  final CrmApi api;
  final DashboardData? initialData;

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  DashboardData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
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
                  _RevenueHero(data: data),
                  const SizedBox(height: 16),
                  const _PlaceholderCard(),
                ],
              ),
            ),
    );
  }
}

class _RevenueHero extends StatelessWidget {
  const _RevenueHero({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Live finance snapshot',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            moneyLabel(data.outstandingInvoiceAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Outstanding invoice amount',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MiniMetric(label: 'Unpaid', value: '${data.unpaidInvoices}'),
              const SizedBox(width: 12),
              _MiniMetric(label: 'Pending', value: '${data.pendingInvoices}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.insights_rounded, color: AppColors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Paid/completed turnover totals will be connected when the '
                'turnover API is available. The current live figures come from '
                'the dashboard invoice summary.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
