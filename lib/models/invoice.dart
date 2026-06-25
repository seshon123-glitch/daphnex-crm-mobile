import 'dart:typed_data';

class Invoice {
  const Invoice({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.totalAmount,
    required this.amountPaid,
    required this.balance,
    required this.status,
    required this.notes,
    this.projectId = 0,
    this.projectName = '',
    this.pdfUrl = '',
    this.downloadPdfUrl = '',
    this.payment = const InvoicePayment(),
    this.items = const [],
    this.activity = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: (json['id'] as num?)?.toInt() ?? 0,
      clientId: (json['client_id'] as num?)?.toInt() ?? 0,
      clientName: json['client_name'] as String? ?? '',
      projectId: (json['project_id'] as num?)?.toInt() ?? 0,
      projectName: json['project_name'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      issueDate: json['issue_date'] as String? ?? '',
      dueDate: json['due_date'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      amountPaid: (json['amount_paid'] as num?)?.toInt() ?? 0,
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      pdfUrl: json['pdf_url'] as String? ?? '',
      downloadPdfUrl: json['download_pdf_url'] as String? ?? '',
      payment: json['payment'] is Map<String, dynamic>
          ? InvoicePayment.fromJson(json['payment'] as Map<String, dynamic>)
          : const InvoicePayment(),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InvoiceItem.fromJson)
          .toList(growable: false),
      activity: (json['activity'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((item) => item['action'] as String? ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
    );
  }

  final int id;
  final int clientId;
  final String clientName;
  final int projectId;
  final String projectName;
  final String invoiceNumber;
  final String issueDate;
  final String dueDate;
  final int totalAmount;
  final int amountPaid;
  final int balance;
  final String status;
  final String notes;
  final String pdfUrl;
  final String downloadPdfUrl;
  final InvoicePayment payment;
  final List<InvoiceItem> items;
  final List<String> activity;

  bool get isPaid => status.toLowerCase() == 'paid' || balance <= 0;
}

class InvoicePayment {
  const InvoicePayment({
    this.configured = false,
    this.paymentUrl = '',
    this.publicInvoiceUrl = '',
    this.amountDue = 0,
    this.currency = 'GBP',
    this.requiresBearer = false,
  });

  factory InvoicePayment.fromJson(Map<String, dynamic> json) => InvoicePayment(
    configured: json['configured'] == true,
    paymentUrl: json['payment_url'] as String? ?? '',
    publicInvoiceUrl: json['public_invoice_url'] as String? ?? '',
    amountDue: (json['amount_due'] as num?)?.toInt() ?? 0,
    currency: json['currency'] as String? ?? 'GBP',
    requiresBearer: json['requires_bearer'] == true,
  );

  final bool configured;
  final String paymentUrl;
  final String publicInvoiceUrl;
  final int amountDue;
  final String currency;
  final bool requiresBearer;
}

class InvoicePdfFile {
  const InvoicePdfFile({
    required this.bytes,
    required this.fileName,
    this.mimeType = 'application/pdf',
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

class InvoiceItem {
  const InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitAmount,
    required this.lineTotal,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitAmount: (json['unit_amount'] as num?)?.toInt() ?? 0,
      lineTotal: (json['line_total'] as num?)?.toInt() ?? 0,
    );
  }

  final String description;
  final double quantity;
  final int unitAmount;
  final int lineTotal;
}

class CreateInvoiceRequest {
  const CreateInvoiceRequest({
    required this.clientId,
    required this.description,
    required this.unitAmount,
    this.projectId = 0,
    this.issueDate = '',
    this.dueDate = '',
    this.notes = '',
  });

  final int clientId;
  final int projectId;
  final String description;
  final String unitAmount;
  final String issueDate;
  final String dueDate;
  final String notes;

  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    'project_id': projectId,
    'status': 'sent',
    'issue_date': issueDate,
    'due_date': dueDate,
    'notes': notes,
    'items': [
      {'description': description, 'quantity': 1, 'unit_amount': unitAmount},
    ],
  };
}

String moneyFromMinorUnits(int amount) =>
    'GBP ${(amount / 100).toStringAsFixed(2)}';
