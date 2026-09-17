import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/workspace_banner.dart';
import '../../models/invoice.dart';
import '../../services/crm_api.dart';
import '../invoices/invoices_screen.dart';

class OutstandingScreen extends StatefulWidget {
  const OutstandingScreen({super.key, required this.api, this.active = true});

  final CrmApi api;
  final bool active;

  @override
  State<OutstandingScreen> createState() => _OutstandingScreenState();
}

class _OutstandingScreenState extends State<OutstandingScreen> {
  List<Invoice>? _invoices;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant OutstandingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final invoices = await widget.api.fetchInvoices();
      if (mounted) {
        setState(() {
          _invoices = invoices
              .where(
                (invoice) =>
                    invoice.balance > 0 &&
                    {
                      'unpaid',
                      'sent',
                      'part_paid',
                      'overdue',
                    }.contains(invoice.status.toLowerCase()),
              )
              .toList();
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoices = _invoices;
    final total = invoices?.fold<int>(
      0,
      (sum, invoice) => sum + invoice.balance,
    );
    final currency = widget.api.currentSession?.tenant.currency ?? 'GBP';
    return Scaffold(
      appBar: AppBar(title: const Text('Outstanding')),
      body: _error != null && invoices == null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : invoices == null
          ? const LoadingView(label: 'Loading outstanding balances…')
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                key: const Key('outstandingScroll'),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  PremiumPageBanner(
                    session: widget.api.currentSession,
                    title: 'Live finance snapshot',
                    subtitle:
                        'Live finance snapshot for unpaid, part-paid and overdue invoices. Payments reduce this total as soon as the backend confirms them.',
                    icon: Icons.account_balance_wallet_outlined,
                    metrics: {
                      'Outstanding balance': moneyFromMinorUnits(
                        total ?? 0,
                        currency: currency,
                      ),
                      'Invoices': '${invoices.length} open',
                    },
                  ),
                  const SizedBox(height: 16),
                  if (invoices.isEmpty)
                    const EmptyStateView(
                      message: 'No outstanding balances found.',
                      icon: Icons.account_balance_wallet_outlined,
                    )
                  else
                    ...invoices.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: ListTile(
                            key: Key('outstanding-invoice-${entry.value.id}'),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.lightBlue,
                              child: Text(
                                '${entry.key + 1}.',
                                style: const TextStyle(
                                  color: AppColors.blue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: Text(
                              entry.value.clientName.isEmpty
                                  ? entry.value.invoiceNumber
                                  : entry.value.clientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${entry.value.invoiceNumber}\n${entry.value.projectName.isEmpty ? 'No project' : entry.value.projectName}\nTotal ${moneyFromMinorUnits(entry.value.totalAmount, currency: entry.value.currency)} · Paid ${moneyFromMinorUnits(entry.value.amountPaid, currency: entry.value.currency)} · ${entry.value.status}',
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              moneyFromMinorUnits(
                                entry.value.balance,
                                currency: entry.value.currency,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            onTap: () => Navigator.of(context)
                                .push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => InvoiceDetailScreen(
                                      api: widget.api,
                                      invoice: entry.value,
                                    ),
                                  ),
                                )
                                .then((_) => _load()),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
