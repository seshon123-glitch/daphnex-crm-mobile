class Job {
  const Job({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.title,
    required this.description,
    required this.status,
    required this.startDate,
    required this.completionDate,
    required this.notes,
    this.recentActivity = const [],
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: (json['id'] as num?)?.toInt() ?? 0,
      clientId: (json['client_id'] as num?)?.toInt() ?? 0,
      clientName: json['client_name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      startDate: json['start_date'] as String? ?? '',
      completionDate: json['completion_date'] as String?,
      notes: json['project_notes'] as String? ?? '',
      recentActivity: (json['recent_activity'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((item) => item['action'] as String? ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
    );
  }

  final int id;
  final int clientId;
  final String clientName;
  final String title;
  final String description;
  final String status;
  final String startDate;
  final String? completionDate;
  final String notes;
  final List<String> recentActivity;
}

class CreateJobRequest {
  const CreateJobRequest({
    required this.clientId,
    required this.title,
    this.description = '',
    this.notes = '',
    this.status = 'in_progress',
    this.priority = 'medium',
    this.type = 'other',
    this.startDate = '',
    this.deadline = '',
  });

  final int clientId;
  final String title;
  final String description;
  final String notes;
  final String status;
  final String priority;
  final String type;
  final String startDate;
  final String deadline;

  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    'title': title,
    'description': description,
    'notes': notes,
    'status': status,
    'priority': priority,
    'type': type,
    'start_date': startDate,
    'deadline': deadline,
  };
}
