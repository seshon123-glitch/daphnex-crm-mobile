class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.status,
    required this.clientId,
    this.description = '',
    this.priority = 'medium',
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
      clientId: (client['id'] as num?)?.toInt() ?? 0,
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
  });

  final int clientId;
  final String title;
  final String date;
  final String time;
  final String description;
  final String priority;

  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    'project_id': 0,
    'title': title,
    'description': description,
    'priority': priority,
    'date': date,
    'time': time,
  };
}
