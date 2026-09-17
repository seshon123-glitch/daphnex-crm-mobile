class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.status,
    required this.clientId,
    this.clientName = '',
    this.description = '',
    this.priority = 'medium',
    this.projectId = 0,
    this.projectName = '',
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>? ?? const {};
    return Reminder(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      priority: json['priority'] as String? ?? 'medium',
      clientId:
          (json['client_id'] as num?)?.toInt() ??
          (client['id'] as num?)?.toInt() ??
          0,
      clientName:
          json['client_name'] as String? ?? client['name'] as String? ?? '',
      projectId: (json['project'] is Map<String, dynamic>)
          ? ((json['project'] as Map<String, dynamic>)['id'] as num?)
                    ?.toInt() ??
                0
          : (json['project_id'] as num?)?.toInt() ?? 0,
      projectName: (json['project'] is Map<String, dynamic>)
          ? ((json['project'] as Map<String, dynamic>)['title'] as String? ??
                (json['project'] as Map<String, dynamic>)['project_title']
                    as String? ??
                '')
          : json['project_name'] as String? ?? '',
    );
  }

  final int id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String status;
  final String priority;
  final int clientId;
  final String clientName;
  final int projectId;
  final String projectName;

  bool get isCompleted => status == 'completed';
  String get due => [date, time].where((value) => value.isNotEmpty).join(' · ');
}

class CreateReminderRequest {
  const CreateReminderRequest({
    required this.clientId,
    required this.title,
    required this.date,
    this.time = '09:00',
    this.description = '',
    this.priority = 'medium',
    this.status = 'pending',
    this.projectId = 0,
  });

  final int clientId;
  final String title;
  final String date;
  final String time;
  final String description;
  final String priority;
  final String status;
  final int projectId;

  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    'project_id': projectId,
    'title': title,
    'description': description,
    'priority': priority,
    'status': status,
    'date': date,
    'time': time,
  };
}
