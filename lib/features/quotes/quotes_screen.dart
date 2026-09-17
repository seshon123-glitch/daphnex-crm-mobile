import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/date_time_picker_fields.dart';
import '../../models/client.dart';
import '../../models/invoice.dart';
import '../../models/quote.dart';
import '../../services/crm_api.dart';
import '../../services/pdf_share_service.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key, required this.api, required this.client});

  final CrmApi api;
  final Client client;

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  List<Quote>? _quotes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final quotes = await widget.api.fetchQuotes(clientId: widget.client.id);
      if (mounted) setState(() => _quotes = quotes);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _createQuote() async {
    final result = await showDialog<_QuoteFormResult>(
      context: context,
      builder: (_) => _QuoteDialog(client: widget.client),
    );
    if (result == null) return;
    try {
      await widget.api.createQuote(
        CreateQuoteRequest(
          clientId: widget.client.id,
          quoteDate: result.quoteDate,
          notes: result.notes,
          items: result.items
              .map(
                (item) => CreateQuoteItemRequest(
                  description: item.description,
                  unitAmount: item.unitAmount,
                ),
              )
              .toList(growable: false),
        ),
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quote created.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotes = _quotes;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.client.name} quotes')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('createQuoteButton'),
        heroTag: 'quotes-add-quote-fab',
        onPressed: _createQuote,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Quote'),
      ),
      body: _error != null && quotes == null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : quotes == null
          ? const LoadingView(label: 'Loading quotes…')
          : quotes.isEmpty
          ? const EmptyStateView(
              message: 'No quotes found.',
              icon: Icons.request_quote_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                itemCount: quotes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final quote = quotes[index];
                  return Card(
                    child: ListTile(
                      key: Key('quote-${quote.id}'),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.lightBlue,
                        child: Text(
                          '${index + 1}.',
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        quote.quoteReference,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        'QUOTATION\n${quote.quoteDate.isEmpty ? 'Date not set' : quote.quoteDate}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        moneyFromMinorUnits(
                          quote.totalAmount,
                          currency: quote.currency,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      onTap: () => Navigator.of(context)
                          .push(
                            MaterialPageRoute<void>(
                              builder: (_) => QuoteDetailScreen(
                                api: widget.api,
                                quote: quote,
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

class QuoteDetailScreen extends StatefulWidget {
  const QuoteDetailScreen({super.key, required this.api, required this.quote});

  final CrmApi api;
  final Quote quote;

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  Quote? _quote;
  String? _error;
  String? _busyAction;

  @override
  void initState() {
    super.initState();
    _quote = widget.quote;
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final quote = await widget.api.fetchQuote(widget.quote.id);
      if (mounted) setState(() => _quote = quote);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _editQuote() async {
    final current = _quote;
    if (current == null) return;
    final result = await showDialog<_QuoteFormResult>(
      context: context,
      builder: (_) => _QuoteDialog(client: null, initialQuote: current),
    );
    if (result == null) return;
    await _runAction('edit_quote', () async {
      final updated = await widget.api.updateQuote(
        current.id,
        CreateQuoteRequest(
          clientId: current.clientId,
          quoteDate: result.quoteDate,
          notes: result.notes,
          items: result.items
              .map(
                (item) => CreateQuoteItemRequest(
                  description: item.description,
                  unitAmount: item.unitAmount,
                ),
              )
              .toList(growable: false),
        ),
      );
      if (mounted) setState(() => _quote = updated);
    });
  }

  Future<void> _viewPdf() async {
    await _runAction('view_pdf', () async {
      final pdf = await widget.api.fetchQuotePdf(widget.quote.id);
      final file = await _writePdf(pdf, temporary: true);
      await OpenFilex.open(file.path);
    });
  }

  Future<void> _downloadPdf() async {
    await _runAction('download_pdf', () async {
      final pdf = await widget.api.downloadQuotePdf(widget.quote.id);
      final file = await _writePdf(pdf, temporary: false);
      await OpenFilex.open(file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quote PDF saved to ${file.path}')),
      );
    });
  }

  Future<void> _shareOnWhatsApp() async {
    final current = _quote;
    if (current == null) return;
    await _runAction('share_whatsapp', () async {
      final pdf = await widget.api.downloadQuotePdf(current.id);
      if (pdf.bytes.isEmpty) {
        throw Exception('Quote PDF is empty and cannot be shared.');
      }
      final file = await _writePdf(pdf, temporary: true);
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('Quote PDF file is empty and cannot be shared.');
      }
      final company =
          widget.api.currentSession?.branding.displayName ??
          widget.api.currentSession?.tenant.companyName ??
          'Daphnex CRM';
      final message =
          'Hello ${current.clientName},\n\n'
          'Please find quotation ${current.quoteReference} from $company attached as a PDF.\n\n'
          'Thank you.';
      await const PdfShareService().sharePdf(
        filePath: file.path,
        fileName: pdf.fileName,
        text: message,
        subject: 'Quotation ${current.quoteReference}',
        targetPackage: 'com.whatsapp',
      );
    });
  }

  Future<void> _deleteQuote() async {
    final current = _quote;
    if (current == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete quote?'),
        content: Text('Delete quotation ${current.quoteReference}?'),
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
    await _runAction('delete_quote', () async {
      await widget.api.deleteQuote(current.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quote deleted.')));
    });
  }

  Future<void> _runAction(String action, Future<void> Function() task) async {
    if (_busyAction != null) return;
    setState(() => _busyAction = action);
    try {
      await task();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<File> _writePdf(QuotePdfFile pdf, {required bool temporary}) async {
    final directory = temporary
        ? await getTemporaryDirectory()
        : await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}${pdf.fileName}',
    );
    return file.writeAsBytes(pdf.bytes, flush: true);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quote;
    return Scaffold(
      appBar: AppBar(title: const Text('Quote detail')),
      body: _error != null && quote == null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : quote == null
          ? const LoadingView(label: 'Loading quote…')
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QUOTATION',
                          style: TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _detailRow('Quote Reference', quote.quoteReference),
                        _detailRow('Client', quote.clientName),
                        _detailRow('Quote Date', quote.quoteDate),
                        _detailRow(
                          'Subtotal',
                          moneyFromMinorUnits(
                            quote.subtotalAmount,
                            currency: quote.currency,
                          ),
                        ),
                        _detailRow(
                          'Total',
                          moneyFromMinorUnits(
                            quote.totalAmount,
                            currency: quote.currency,
                          ),
                        ),
                        if (quote.notes.isNotEmpty)
                          _detailRow('Notes', quote.notes),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quote items',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (quote.items.isEmpty)
                          const Text(
                            'No line items.',
                            style: TextStyle(color: AppColors.muted),
                          )
                        else
                          ...quote.items.map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.description),
                              subtitle: Text('Quantity ${item.quantity}'),
                              trailing: Text(
                                moneyFromMinorUnits(
                                  item.lineTotal,
                                  currency: quote.currency,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('editQuoteButton'),
                  onPressed: _busyAction == null ? _editQuote : null,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('viewQuotePdfButton'),
                  onPressed: _busyAction == null ? _viewPdf : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('View PDF Quote'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('downloadQuotePdfButton'),
                  onPressed: _busyAction == null ? _downloadPdf : null,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download PDF Quote'),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const Key('shareQuoteWhatsAppButton'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                  ),
                  onPressed: _busyAction == null ? _shareOnWhatsApp : null,
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('Share via WhatsApp'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('deleteQuoteButton'),
                  onPressed: _busyAction == null ? _deleteQuote : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
              ],
            ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _QuoteDialog extends StatefulWidget {
  const _QuoteDialog({required this.client, this.initialQuote});

  final Client? client;
  final Quote? initialQuote;

  @override
  State<_QuoteDialog> createState() => _QuoteDialogState();
}

class _QuoteDialogState extends State<_QuoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quoteDate = TextEditingController();
  final _notes = TextEditingController();
  final _items = <_QuoteLineItemForm>[];

  @override
  void initState() {
    super.initState();
    final quote = widget.initialQuote;
    _quoteDate.text = quote?.quoteDate ?? formatCrmDate(DateTime.now());
    _notes.text = quote?.notes ?? '';
    if (quote == null || quote.items.isEmpty) {
      _items.add(
        _QuoteLineItemForm(
          description: TextEditingController(),
          unitAmount: TextEditingController(text: '100.00'),
        ),
      );
    } else {
      _items.addAll(
        quote.items.map(
          (item) => _QuoteLineItemForm(
            description: TextEditingController(text: item.description),
            unitAmount: TextEditingController(
              text: (item.unitAmount / 100).toStringAsFixed(2),
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _quoteDate.dispose();
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
      _QuoteFormResult(
        quoteDate: _quoteDate.text.trim(),
        notes: _notes.text.trim(),
        items: _items
            .map(
              (item) => _QuoteLineItemResult(
                description: item.description.text.trim(),
                unitAmount: item.unitAmount.text.trim(),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  void _addItem() {
    setState(() {
      _items.add(
        _QuoteLineItemForm(
          description: TextEditingController(),
          unitAmount: TextEditingController(text: '0.00'),
        ),
      );
    });
  }

  void _removeItem(int index) {
    if (_items.length == 1) return;
    setState(() => _items.removeAt(index).dispose());
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
    if (trimmed.isEmpty) return 'Required';
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)
        ? null
        : 'Use YYYY-MM-DD';
  }

  int get _totalMinorUnits => _items.fold<int>(0, (sum, item) {
    final parsed = num.tryParse(item.unitAmount.text.trim()) ?? 0;
    return sum + (parsed * 100).round();
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initialQuote == null ? 'Create quote' : 'Edit quote'),
    content: SizedBox(
      width: double.maxFinite,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.client != null) ...[
                Text(
                  widget.client!.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
              ],
              DatePickerFormField(
                key: const Key('quoteDateField'),
                controller: _quoteDate,
                labelText: 'Quote Date *',
                validator: _date,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Quote line items',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('addQuoteItemButton'),
                    onPressed: _addItem,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add item'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < _items.length; index++) ...[
                TextFormField(
                  key: Key('quoteItemDescriptionField-$index'),
                  controller: _items[index].description,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: Key('quoteItemAmountField-$index'),
                  controller: _items[index].unitAmount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Amount *'),
                  validator: _money,
                  onChanged: (_) => setState(() {}),
                ),
                if (_items.length > 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: Key('removeQuoteItemButton-$index'),
                      onPressed: () => _removeItem(index),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      label: const Text('Remove'),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              _totalRow('Subtotal', _totalMinorUnits),
              _totalRow('Total', _totalMinorUnits),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('quoteNotesField'),
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
      FilledButton(
        key: const Key('saveQuoteForm'),
        onPressed: _submit,
        child: Text(widget.initialQuote == null ? 'Create' : 'Save'),
      ),
    ],
  );

  Widget _totalRow(String label, int value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted)),
        Text(
          moneyFromMinorUnits(value),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _QuoteFormResult {
  const _QuoteFormResult({
    required this.quoteDate,
    required this.notes,
    required this.items,
  });

  final String quoteDate;
  final String notes;
  final List<_QuoteLineItemResult> items;
}

class _QuoteLineItemResult {
  const _QuoteLineItemResult({
    required this.description,
    required this.unitAmount,
  });

  final String description;
  final String unitAmount;
}

class _QuoteLineItemForm {
  _QuoteLineItemForm({required this.description, required this.unitAmount});

  final TextEditingController description;
  final TextEditingController unitAmount;

  void dispose() {
    description.dispose();
    unitAmount.dispose();
  }
}
