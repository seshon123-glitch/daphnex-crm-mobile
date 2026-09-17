class ProjectExpense {
  const ProjectExpense({
    required this.id,
    required this.clientId,
    required this.projectId,
    required this.expenseDate,
    required this.description,
    required this.amount,
    this.clientName = '',
    this.projectName = '',
    this.currency = 'GBP',
  });

  factory ProjectExpense.fromJson(Map<String, dynamic> json) => ProjectExpense(
    id: _intFromJson(json['id']),
    clientId: _intFromJson(json['client_id']),
    clientName: json['client_name'] as String? ?? '',
    projectId: _intFromJson(json['project_id']),
    projectName: json['project_name'] as String? ?? '',
    expenseDate:
        json['expense_date'] as String? ?? json['date'] as String? ?? '',
    description: json['description'] as String? ?? '',
    amount: _moneyMinorUnitsFromJson(json['amount']),
    currency: json['currency'] as String? ?? 'GBP',
  );

  final int id;
  final int clientId;
  final String clientName;
  final int projectId;
  final String projectName;
  final String expenseDate;
  final String description;
  final int amount;
  final String currency;
}

class CreateProjectExpenseRequest {
  const CreateProjectExpenseRequest({
    required this.expenseDate,
    required this.description,
    required this.amount,
  });

  final String expenseDate;
  final String description;
  final String amount;

  Map<String, dynamic> toJson() => {
    'expense_date': expenseDate.trim(),
    'description': description.trim(),
    'amount': amount.trim(),
  };
}

int _intFromJson(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

int _moneyMinorUnitsFromJson(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) {
    final trimmed = value.trim();
    final integerMinorUnits = int.tryParse(trimmed);
    if (integerMinorUnits != null) return integerMinorUnits;
    final decimalMajorUnits = double.tryParse(trimmed);
    if (decimalMajorUnits != null) return (decimalMajorUnits * 100).round();
  }
  return 0;
}
