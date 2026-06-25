import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../models/invoice.dart';
import '../../services/crm_api.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key, required this.api});

  final CrmApi api;

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<Invoice>? _invoices;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final invoices = await widget.api.fetchInvoices();
      if (mounted) setState(() => _invoices = invoices);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _createInvoice() async {
    final result = await showDialog<_InvoiceFormResult>(
      context: context,
      builder: (_) => const _InvoiceDialog(),
    );
    if (result == null) return;
    try {
      await widget.api.createInvoice(
        CreateInvoiceRequest(
          clientId: result.clientId,
          description: result.description,
          unitAmount: result.amount,
          dueDate: result.dueDate,
          notes: result.notes,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invoice created.')));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('createInvoiceButton'),
        onPressed: _createInvoice,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Invoice'),
      ),
      body: _error != null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : _invoices == null
          ? const LoadingView(label: 'Loading invoices…')
          : _invoices!.isEmpty
          ? const EmptyStateView(
              message: 'No invoices found.',
              icon: Icons.receipt_long_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                itemCount: _invoices!.length,
                itemBuilder: (context, index) {
                  final invoice = _invoices![index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        invoice.invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${invoice.clientName}\nDue ${invoice.dueDate.isEmpty ? 'not set' : invoice.dueDate}',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            moneyFromMinorUnits(invoice.balance),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            invoice.status,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => InvoiceDetailScreen(
                                api: widget.api,
                                invoice: invoice,
                              ),
                            ),
                          )
                          .then((_) => _load()),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({
    super.key,
    required this.api,
    required this.invoice,
  });

  final CrmApi api;
  final Invoice invoice;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  Invoice? _invoice;
  String? _error;
  String? _busyAction;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final invoice = await widget.api.fetchInvoice(widget.invoice.id);
      if (mounted) setState(() => _invoice = invoice);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _updatePaid(bool paid) async {
    try {
      final invoice = paid
          ? await widget.api.markInvoicePaid(widget.invoice.id)
          : await widget.api.markInvoiceUnpaid(widget.invoice.id);
      if (mounted) setState(() => _invoice = invoice);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _viewPdf() async {
    await _runAction('view_pdf', () async {
      final pdf = await widget.api.fetchInvoicePdf(widget.invoice.id);
      final file = await _writePdf(pdf, temporary: true);
      await _openPdfFile(file.path);
    });
  }

  Future<void> _downloadPdf() async {
    await _runAction('download_pdf', () async {
      final pdf = await widget.api.downloadInvoicePdf(widget.invoice.id);
      final file = await _writePdf(pdf, temporary: false);
      await _openPdfFile(file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice PDF saved to ${file.path}')),
      );
    });
  }

  Future<void> _payInvoice() async {
    final current = _invoice;
    if (current != null && current.isPaid) {
      _showMessage('Invoice already paid.');
      return;
    }
    await _runAction('pay_invoice', () async {
      final payment = await widget.api.fetchInvoicePaymentLink(
        widget.invoice.id,
      );
      if (payment.amountDue <= 0) {
        _showMessage('Invoice already paid.');
        await _load();
        return;
      }
      if (!payment.configured || payment.paymentUrl.isEmpty) {
        _showMessage('Card payment is not configured for this invoice.');
        return;
      }
      final uri = Uri.tryParse(payment.paymentUrl);
      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open the payment page.');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment page opened. Refresh after payment.'),
          action: SnackBarAction(label: 'Refresh', onPressed: _load),
        ),
      );
    });
  }

  Future<void> _runAction(
    String action,
    Future<void> Function() operation,
  ) async {
    if (_busyAction != null) return;
    setState(() => _busyAction = action);
    try {
      await operation();
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<File> _writePdf(InvoicePdfFile pdf, {required bool temporary}) async {
    final directory = temporary
        ? await getTemporaryDirectory()
        : await getApplicationDocumentsDirectory();
    final fileName = _safeFileName(pdf.fileName);
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    return file.writeAsBytes(pdf.bytes, flush: true);
  }

  Future<void> _openPdfFile(String path) async {
    final result = await OpenFilex.open(path, type: 'application/pdf');
    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }

  String _safeFileName(String fileName) {
    final cleaned = fileName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return 'invoice-${widget.invoice.id}.pdf';
    return cleaned.toLowerCase().endsWith('.pdf') ? cleaned : '$cleaned.pdf';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _invoice;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice detail'),
        actions: [
          IconButton(
            tooltip: 'Refresh invoice',
            onPressed: _busyAction == null ? _load : null,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _error != null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : invoice == null
          ? const LoadingView(label: 'Loading invoice…')
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  invoice.clientName,
                  style: const TextStyle(color: AppColors.muted),
                ),
                if (invoice.projectName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    invoice.projectName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
                const SizedBox(height: 18),
                _InfoCard(
                  rows: {
                    'Client': invoice.clientName,
                    'Project/service': invoice.projectName.isEmpty
                        ? 'Not linked'
                        : invoice.projectName,
                    'Issue date': invoice.issueDate,
                    'Due date': invoice.dueDate,
                    'Total': moneyFromMinorUnits(invoice.totalAmount),
                    'Paid': moneyFromMinorUnits(invoice.amountPaid),
                    'Outstanding': moneyFromMinorUnits(invoice.balance),
                    'Status': invoice.status,
                    'Notes': invoice.notes.isEmpty
                        ? 'No notes.'
                        : invoice.notes,
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Invoice PDF',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'View, save, or pay this live Daphnex invoice.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _busyAction == null ? _viewPdf : null,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: Text(
                            _busyAction == 'view_pdf'
                                ? 'Opening PDF...'
                                : 'View PDF Invoice',
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _busyAction == null ? _downloadPdf : null,
                          icon: const Icon(Icons.download_rounded),
                          label: Text(
                            _busyAction == 'download_pdf'
                                ? 'Downloading...'
                                : 'Download PDF Invoice',
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _busyAction == null ? _payInvoice : null,
                          icon: const Icon(Icons.payment_rounded),
                          label: Text(
                            _busyAction == 'pay_invoice'
                                ? 'Preparing payment...'
                                : 'Pay Invoice',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _updatePaid(true),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Mark paid'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updatePaid(false),
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('Unpaid'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _InvoiceDialog extends StatefulWidget {
  const _InvoiceDialog();

  @override
  State<_InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<_InvoiceDialog> {
  final _clientId = TextEditingController(text: '1');
  final _description = TextEditingController();
  final _amount = TextEditingController(text: '100.00');
  final _dueDate = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _clientId.dispose();
    _description.dispose();
    _amount.dispose();
    _dueDate.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create invoice'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _clientId,
              decoration: const InputDecoration(labelText: 'Client ID'),
            ),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Line description'),
            ),
            TextField(
              controller: _amount,
              decoration: const InputDecoration(
                labelText: 'Amount, e.g. 100.00',
              ),
            ),
            TextField(
              controller: _dueDate,
              decoration: const InputDecoration(
                labelText: 'Due date YYYY-MM-DD',
              ),
            ),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              _InvoiceFormResult(
                clientId: int.tryParse(_clientId.text) ?? 0,
                description: _description.text,
                amount: _amount.text,
                dueDate: _dueDate.text,
                notes: _notes.text,
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _InvoiceFormResult {
  const _InvoiceFormResult({
    required this.clientId,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.notes,
  });
  final int clientId;
  final String description;
  final String amount;
  final String dueDate;
  final String notes;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: rows.entries
            .map(
              (entry) => ListTile(
                dense: true,
                title: Text(entry.key),
                subtitle: Text(entry.value.isEmpty ? 'Not set' : entry.value),
              ),
            )
            .toList(),
      ),
    ),
  );
}
