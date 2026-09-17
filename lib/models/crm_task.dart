class CrmTask {
  const CrmTask({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.title,
    required this.status,
    required this.priority,
    this.projectId = 0,
    this.projectName = '',
    this.assignedUserId = 0,
    this.assignedTo = '',
    this.dueDate = '',
    this.description = '',
    this.internalNotes = '',
  });

  factory CrmTask.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>? ?? const {};
    final project = json['project'] as Map<String, dynamic>? ?? const {};
    return CrmTask(
      id: (json['id'] as num?)?.toInt() ?? 0,
      clientId:
          (json['client_id'] as num?)?.toInt() ??
          (client['id'] as num?)?.toInt() ??
          0,
      clientName:
          json['client_name'] as String? ?? client['name'] as String? ?? '',
      projectId:
          (json['project_id'] as num?)?.toInt() ??
          (project['id'] as num?)?.toInt() ??
          0,
      projectName:
          json['project_name'] as String? ??
          project['title'] as String? ??
          project['project_title'] as String? ??
          '',
      assignedUserId: (json['assigned_user_id'] as num?)?.toInt() ?? 0,
      assignedTo: json['assigned_to'] as String? ?? '',
      title: json['title'] as String? ?? json['task_title'] as String? ?? '',
      dueDate: json['due_date'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      description:
          json['description'] as String? ??
          json['task_description'] as String? ??
          '',
      internalNotes: json['internal_notes'] as String? ?? '',
    );
  }

  final int id;
  final int clientId;
  final String clientName;
  final int projectId;
  final String projectName;
  final int assignedUserId;
  final String assignedTo;
  final String title;
  final String dueDate;
  final String priority;
  final String status;
  final String description;
  final String internalNotes;
}

class CreateTaskRequest {
  const CreateTaskRequest({
    required this.clientId,
    required this.title,
    this.projectId = 0,
    this.assignedUserId = 0,
    this.dueDate = '',
    this.priority = 'medium',
    this.status = 'pending',
    this.description = '',
    this.internalNotes = '',
  });

  final int clientId;
  final int projectId;
  final int assignedUserId;
  final String title;
  final String dueDate;
  final String priority;
  final String status;
  final String description;
  final String internalNotes;

  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    if (projectId > 0) 'project_id': projectId,
    if (assignedUserId > 0) 'assigned_user_id': assignedUserId,
    'title': title.trim(),
    'task_title': title.trim(),
    'due_date': dueDate.trim(),
    'priority': priority,
    'status': status,
    'description': description.trim(),
    'task_description': description.trim(),
    'internal_notes': internalNotes.trim(),
  };
}
