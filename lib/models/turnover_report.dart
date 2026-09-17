class TurnoverReportRow {
  const TurnoverReportRow({
    required this.month,
    required this.totalInvoices,
    required this.totalInvoiced,
  });

  factory TurnoverReportRow.fromJson(Map<String, dynamic> json) =>
      TurnoverReportRow(
        month: json['month_key'] as String? ?? json['month'] as String? ?? '',
        totalInvoices: _intFromJson(
          json['invoice_count'] ??
              json['total_invoice_count'] ??
              json['total_invoices_count'] ??
              json['total_projects'],
        ),
        totalInvoiced:
            _moneyMinorUnitsFromJson(
              json['total_invoiced'] ??
                  json['total_invoices'] ??
                  json['turnover'],
            ) ??
            0,
      );

  final String month;
  final int totalInvoices;
  final int totalInvoiced;
}

int _intFromJson(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

int? _moneyMinorUnitsFromJson(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) {
    final trimmed = value.trim();
    final integerMinorUnits = int.tryParse(trimmed);
    if (integerMinorUnits != null) return integerMinorUnits;
    final decimalMajorUnits = double.tryParse(trimmed);
    if (decimalMajorUnits != null) return (decimalMajorUnits * 100).round();
  }
  return null;
}
