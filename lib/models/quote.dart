import 'dart:typed_data';

class Quote {
  const Quote({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.quoteReference,
    required this.quoteDate,
    required this.totalAmount,
    required this.status,
    required this.notes,
    this.subtotalAmount = 0,
    this.pdfUrl = '',
    this.downloadPdfUrl = '',
    this.shareUrl = '',
    this.currency = 'GBP',
    this.items = const [],
  });

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
    id: (json['id'] as num?)?.toInt() ?? 0,
    clientId: (json['client_id'] as num?)?.toInt() ?? 0,
    clientName: (json['client_name'] ?? '').toString(),
    quoteReference:
        (json['quote_reference'] ?? json['quote_number'] ?? '').toString(),
    quoteDate: (json['quote_date'] ?? json['issue_date'] ?? '').toString(),
    subtotalAmount: (json['subtotal_amount'] as num?)?.toInt() ?? 0,
    totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
    status: (json['status'] ?? 'draft').toString(),
    notes: (json['notes'] ?? '').toString(),
    pdfUrl: (json['pdf_url'] ?? '').toString(),
    downloadPdfUrl: (json['download_pdf_url'] ?? '').toString(),
    shareUrl: (json['share_url'] ?? json['public_quote_url'] ?? '').toString(),
    currency: (json['currency'] ?? 'GBP').toString(),
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(QuoteItem.fromJson)
        .toList(growable: false),
  );

  final int id;
  final int clientId;
  final String clientName;
  final String quoteReference;
  final String quoteDate;
  final int subtotalAmount;
  final int totalAmount;
  final String status;
  final String notes;
  final String pdfUrl;
  final String downloadPdfUrl;
  final String shareUrl;
  final String currency;
  final List<QuoteItem> items;
}

class QuoteItem {
  const QuoteItem({
    required this.description,
    required this.quantity,
    required this.unitAmount,
    required this.lineTotal,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) => QuoteItem(
    description: (json['description'] ?? '').toString(),
    quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
    unitAmount: (json['unit_amount'] as num?)?.toInt() ?? 0,
    lineTotal: (json['line_total'] as num?)?.toInt() ?? 0,
  );

  final String description;
  final double quantity;
  final int unitAmount;
  final int lineTotal;
}

class QuotePdfFile {
  const QuotePdfFile({
    required this.bytes,
    required this.fileName,
    this.mimeType = 'application/pdf',
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

class CreateQuoteRequest {
  const CreateQuoteRequest({
    required this.clientId,
    required this.items,
    this.quoteDate = '',
    this.status = 'sent',
    this.notes = '',
  });

  final int clientId;
  final String quoteDate;
  final String status;
  final String notes;
  final List<CreateQuoteItemRequest> items;

  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    'quote_date': quoteDate.trim(),
    'issue_date': quoteDate.trim(),
    'status': status.trim(),
    'notes': notes.trim(),
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };
}

class CreateQuoteItemRequest {
  const CreateQuoteItemRequest({
    required this.description,
    this.quantity = '1',
    required this.unitAmount,
  });

  final String description;
  final String quantity;
  final String unitAmount;

  Map<String, dynamic> toJson() => {
    'description': description.trim(),
    'quantity': quantity.trim().isEmpty ? '1' : quantity.trim(),
    'unit_amount': unitAmount.trim(),
  };
}
