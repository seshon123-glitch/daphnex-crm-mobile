import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/document_url_resolver.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/date_time_picker_fields.dart';
import '../../core/widgets/workspace_banner.dart';
import '../../models/client.dart';
import '../../models/invoice.dart';
import '../../models/job.dart';
import '../../services/crm_api.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key, required this.api, this.client});

  final CrmApi api;
  final Client? client;

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
      final invoices = await widget.api.fetchInvoices(
        clientId: widget.client?.id,
      );
      if (mounted) {
        setState(() => _invoices = invoices);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _createInvoice() async {
    final clients = widget.client == null
        ? await widget.api.fetchClients()
        : <Client>[widget.client!];
    final jobs = await widget.api.fetchJobs(clientId: widget.client?.id);
    if (!mounted) return;
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a client before creating an invoice.'),
        ),
      );
      return;
    }
    final result = await showDialog<_InvoiceFormResult>(
      context: context,
      builder: (_) => _InvoiceDialog(
        clients: clients,
        jobs: jobs,
        lockedClient: widget.client,
      ),
    );
    if (result == null) return;
    try {
      await widget.api.createInvoice(
        CreateInvoiceRequest(
          clientId: result.clientId,
          projectId: result.projectId,
          status: result.status,
          issueDate: result.issueDate,
          dueDate: result.dueDate,
          notes: result.notes,
          items: result.items
              .map(
                (item) => CreateInvoiceItemRequest(
                  description: item.description,
                  quantity: item.quantity,
                  unitAmount: item.unitAmount,
                ),
              )
              .toList(growable: false),
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
      appBar: AppBar(
        title: Text(
          widget.client == null
              ? 'Invoices'
              : '${widget.client!.name} invoices',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('createInvoiceButton'),
        heroTag: 'invoices-add-invoice-fab',
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
                itemCount: _invoices!.length + (widget.client == null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (widget.client == null && index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: WorkspaceBanner(
                        session: widget.api.currentSession,
                      ),
                    );
                  }
                  final invoiceIndex = index - (widget.client == null ? 1 : 0);
                  final invoice = _invoices![invoiceIndex];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.lightBlue,
                        child: Text(
                          '${invoiceIndex + 1}.',
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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
      final uri = DocumentUrlResolver.resolve(payment.paymentUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
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

  Future<void> _shareOnWhatsApp() async {
    final current = _invoice;
    if (current == null) return;
    await _runAction('share_whatsapp', () async {
      final payment = await widget.api.fetchInvoicePaymentLink(
        widget.invoice.id,
      );
      final shareUrl = payment.publicInvoiceUrl.isNotEmpty
          ? payment.publicInvoiceUrl
          : payment.paymentUrl;
      if (shareUrl.isEmpty || payment.requiresBearer) {
        _showMessage(
          'A secure shareable invoice link is not available for this invoice.',
        );
        return;
      }
      final resolved = DocumentUrlResolver.resolve(shareUrl);
      if (resolved.scheme != 'https') {
        _showMessage('Only secure HTTPS invoice links can be shared.');
        return;
      }
      final company =
          widget.api.currentSession?.branding.displayName ??
          widget.api.currentSession?.tenant.companyName ??
          'Daphnex CRM';
      final message = Uri.encodeComponent(
        'Hello ${current.clientName},\n\n'
        'Please find your invoice ${current.invoiceNumber} from $company.\n\n'
        '$resolved\n\n'
        'Thank you.',
      );
      final whatsapp = Uri.parse('whatsapp://send?text=$message');
      final webFallback = Uri.parse('https://wa.me/?text=$message');
      if (await canLaunchUrl(whatsapp) &&
          await launchUrl(whatsapp, mode: LaunchMode.externalApplication)) {
        return;
      }
      if (!await launchUrl(webFallback, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open WhatsApp sharing.');
      }
    });
  }

  Future<void> _addPayment() async {
    final current = _invoice;
    if (current == null || current.balance <= 0) {
      _showMessage('This invoice has no outstanding balance.');
      return;
    }
    final request = await showDialog<CreateInvoicePaymentRequest>(
      context: context,
      builder: (_) => _AddPaymentDialog(invoice: current),
    );
    if (request == null) return;
    await _runAction('add_payment', () async {
      final updated = await widget.api.addInvoicePayment(current.id, request);
      if (mounted) {
        setState(() => _invoice = updated);
        _showMessage('Payment recorded.');
        await _load();
      }
    });
  }

  Future<void> _deleteInvoice() async {
    final current = _invoice;
    if (current == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: Text(
          'Delete invoice ${current.invoiceNumber}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction('delete_invoice', () async {
      await widget.api.deleteInvoice(current.id);
      if (!mounted) return;
      _showMessage('Invoice deleted.');
      Navigator.of(context).pop();
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
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          key: const Key('shareInvoiceWhatsAppButton'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _busyAction == null
                              ? _shareOnWhatsApp
                              : null,
                          icon: const Icon(Icons.chat_rounded),
                          label: Text(
                            _busyAction == 'share_whatsapp'
                                ? 'Preparing share...'
                                : 'Share via WhatsApp',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('addPaymentButton'),
                  onPressed: _busyAction == null ? _addPayment : null,
                  icon: const Icon(Icons.add_card_rounded),
                  label: Text(
                    _busyAction == 'add_payment'
                        ? 'Recording payment...'
                        : 'Add Payment',
                  ),
                ),
                const SizedBox(height: 16),
                _PaymentHistoryCard(invoice: invoice),
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
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('deleteInvoiceButton'),
                  onPressed: _busyAction == null ? _deleteInvoice : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(
                    _busyAction == 'delete_invoice'
                        ? 'Deleting...'
                        : 'Delete Invoice',
                  ),
                ),
              ],
            ),
    );
  }
}

class _InvoiceDialog extends StatefulWidget {
  const _InvoiceDialog({
    required this.clients,
    required this.jobs,
    required this.lockedClient,
  });

  final List<Client> clients;
  final List<Job> jobs;
  final Client? lockedClient;

  @override
  State<_InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<_InvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _issueDate = TextEditingController();
  final _dueDate = TextEditingController();
  final _notes = TextEditingController();
  final _items = <_InvoiceLineItemForm>[
    _InvoiceLineItemForm(
      description: TextEditingController(),
      quantity: TextEditingController(text: '1'),
      unitAmount: TextEditingController(text: '100.00'),
    ),
  ];
  late int _clientId;
  int _projectId = 0;
  String _status = 'draft';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final due = now.add(const Duration(days: 14));
    _clientId = widget.lockedClient?.id ?? widget.clients.first.id;
    _issueDate.text = formatCrmDate(now);
    _dueDate.text = formatCrmDate(due);
  }

  @override
  void dispose() {
    _issueDate.dispose();
    _dueDate.dispose();
    _notes.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _InvoiceFormResult(
        clientId: _clientId,
        projectId: _projectId,
        status: _status,
        issueDate: _issueDate.text.trim(),
        dueDate: _dueDate.text.trim(),
        notes: _notes.text.trim(),
        items: _items
            .map(
              (item) => _InvoiceLineItemResult(
                description: item.description.text.trim(),
                quantity: item.quantity.text.trim(),
                unitAmount: item.unitAmount.text.trim(),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? _money(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Required';
    final parsed = num.tryParse(trimmed);
    if (parsed == null || parsed <= 0) return 'Enter a positive amount';
    return null;
  }

  String? _date(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)
        ? null
        : 'Use YYYY-MM-DD';
  }

  List<Job> get _clientJobs =>
      widget.jobs.where((job) => job.clientId == _clientId).toList();

  void _addItem() {
    setState(() {
      _items.add(
        _InvoiceLineItemForm(
          description: TextEditingController(),
          quantity: TextEditingController(text: '1'),
          unitAmount: TextEditingController(text: '0.00'),
        ),
      );
    });
  }

  void _removeItem(int index) {
    if (_items.length == 1) return;
    setState(() {
      final item = _items.removeAt(index);
      item.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _clientJobs;
    if (_projectId != 0 && !jobs.any((job) => job.id == _projectId)) {
      _projectId = 0;
    }
    return AlertDialog(
      title: const Text('Create invoice'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _FormGroupHeader('Invoice details'),
                const SizedBox(height: 8),
                if (widget.lockedClient == null) ...[
                  DropdownButtonFormField<int>(
                    key: const Key('invoiceClientField'),
                    initialValue: _clientId,
                    decoration: const InputDecoration(labelText: 'Client *'),
                    items: widget.clients
                        .map(
                          (client) => DropdownMenuItem(
                            value: client.id,
                            child: Text(
                              client.company.isEmpty
                                  ? client.name
                                  : client.company,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _clientId = value;
                        _projectId = 0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<int>(
                  key: const Key('invoiceProjectField'),
                  initialValue: _projectId,
                  decoration: const InputDecoration(labelText: 'Project'),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('No linked project'),
                    ),
                    ...jobs.map(
                      (job) => DropdownMenuItem(
                        value: job.id,
                        child: Text(job.title),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _projectId = value);
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Invoice number is generated by Daphnex CRM.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('invoiceStatusField'),
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'sent', child: Text('Sent')),
                    DropdownMenuItem(
                      value: 'part_paid',
                      child: Text('Part paid'),
                    ),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 12),
                DatePickerFormField(
                  key: const Key('invoiceDateField'),
                  controller: _issueDate,
                  labelText: 'Invoice Date',
                  validator: _date,
                ),
                const SizedBox(height: 12),
                DatePickerFormField(
                  key: const Key('invoiceDueDateField'),
                  controller: _dueDate,
                  labelText: 'Due Date',
                  validator: _date,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(child: _FormGroupHeader('Invoice items')),
                    TextButton.icon(
                      key: const Key('addInvoiceItemButton'),
                      onPressed: _addItem,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add item'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < _items.length; index++) ...[
                  _InvoiceLineItemFields(
                    item: _items[index],
                    index: index,
                    canRemove: _items.length > 1,
                    onRemove: () => _removeItem(index),
                    requiredValidator: _required,
                    moneyValidator: _money,
                  ),
                  const SizedBox(height: 12),
                ],
                const _FormGroupHeader('Notes'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Outstanding balance',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _summaryRow(
            'Total charged',
            moneyFromMinorUnits(invoice.totalAmount),
          ),
          _summaryRow('Total paid', moneyFromMinorUnits(invoice.amountPaid)),
          _summaryRow('Outstanding', moneyFromMinorUnits(invoice.balance)),
          _summaryRow('Payment status', _label(invoice.status)),
          const SizedBox(height: 14),
          const Text(
            'Payment history',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (invoice.payments.isEmpty)
            const Text(
              'No payments recorded.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            ...invoice.payments.asMap().entries.map((entry) {
              final payment = entry.value;
              // paid_at is a business date, not a recording instant. Preserve
              // its calendar date without timezone conversion or a guessed time.
              final paymentDate = RegExp(
                r'^\d{4}-\d{2}-\d{2}(?=$|[T\s])',
              ).stringMatch(payment.paidAt.trim());
              return ListTile(
                contentPadding: EdgeInsets.zero,
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
                title: Text(moneyFromMinorUnits(payment.amount)),
                subtitle: Text(
                  [
                    if (paymentDate != null) 'Payment Date: $paymentDate',
                    if (payment.method.isNotEmpty) _label(payment.method),
                    if (payment.reference.isNotEmpty) payment.reference,
                  ].join(' · '),
                ),
              );
            }),
        ],
      ),
    ),
  );

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value.isEmpty ? 'Not set' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _AddPaymentDialog extends StatefulWidget {
  const _AddPaymentDialog({required this.invoice});

  final Invoice invoice;

  @override
  State<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<_AddPaymentDialog> {
  static const _methods = ['cash', 'bank_transfer', 'card', 'paypal', 'other'];

  final _formKey = GlobalKey<FormState>();
  final _paidAt = TextEditingController();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  String _method = 'bank_transfer';

  @override
  void initState() {
    super.initState();
    _paidAt.text = formatCrmDate(DateTime.now());
    _amount.text = (widget.invoice.balance / 100).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _paidAt.dispose();
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CreateInvoicePaymentRequest(
        amount: _amount.text.trim(),
        paidAt: _paidAt.text.trim(),
        paymentMethod: _method,
        paymentReference: _reference.text.trim(),
      ),
    );
  }

  String? _date(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Required';
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)
        ? null
        : 'Use YYYY-MM-DD';
  }

  String? _paymentAmount(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Required';
    final parsed = num.tryParse(trimmed);
    if (parsed == null || parsed <= 0) return 'Enter a positive amount';
    final minorUnits = (parsed * 100).round();
    if (minorUnits > widget.invoice.balance) {
      return 'Payment cannot exceed outstanding balance.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add payment'),
    content: SizedBox(
      width: double.maxFinite,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.invoice.invoiceNumber,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Outstanding: ${moneyFromMinorUnits(widget.invoice.balance)}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              DatePickerFormField(
                key: const Key('paymentDateField'),
                controller: _paidAt,
                labelText: 'Paid At / Payment Date',
                validator: _date,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('paymentAmountField'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: _paymentAmount,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('paymentMethodField'),
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: _methods
                    .map(
                      (method) => DropdownMenuItem(
                        value: method,
                        child: Text(_label(method)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('paymentReferenceField'),
                controller: _reference,
                decoration: const InputDecoration(
                  labelText: 'Payment Reference',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Record payment')),
    ],
  );
}

String _label(String value) => value
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

class _InvoiceFormResult {
  const _InvoiceFormResult({
    required this.clientId,
    required this.projectId,
    required this.status,
    required this.issueDate,
    required this.dueDate,
    required this.notes,
    required this.items,
  });
  final int clientId;
  final int projectId;
  final String status;
  final String issueDate;
  final String dueDate;
  final String notes;
  final List<_InvoiceLineItemResult> items;
}

class _InvoiceLineItemResult {
  const _InvoiceLineItemResult({
    required this.description,
    required this.quantity,
    required this.unitAmount,
  });

  final String description;
  final String quantity;
  final String unitAmount;
}

class _InvoiceLineItemForm {
  _InvoiceLineItemForm({
    required this.description,
    required this.quantity,
    required this.unitAmount,
  });

  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController unitAmount;

  void dispose() {
    description.dispose();
    quantity.dispose();
    unitAmount.dispose();
  }
}

class _InvoiceLineItemFields extends StatelessWidget {
  const _InvoiceLineItemFields({
    required this.item,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.requiredValidator,
    required this.moneyValidator,
  });

  final _InvoiceLineItemForm item;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final String? Function(String?) requiredValidator;
  final String? Function(String?) moneyValidator;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.lightBlue.withValues(alpha: 0.45),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Item ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Remove item',
                ),
            ],
          ),
          TextFormField(
            key: Key('invoiceItemDescription-$index'),
            controller: item.description,
            decoration: const InputDecoration(labelText: 'Description *'),
            validator: requiredValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: Key('invoiceItemQuantity-$index'),
            controller: item.quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Quantity *'),
            validator: moneyValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: Key('invoiceItemAmount-$index'),
            controller: item.unitAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Unit Amount *'),
            validator: moneyValidator,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Line total is calculated by Daphnex CRM after save.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FormGroupHeader extends StatelessWidget {
  const _FormGroupHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: AppColors.blue,
      fontWeight: FontWeight.w900,
    ),
  );
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
