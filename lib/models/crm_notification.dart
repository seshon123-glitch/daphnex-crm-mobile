class CrmNotification {
  const CrmNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    this.related = const {},
  });

  factory CrmNotification.fromJson(Map<String, dynamic> json) {
    return CrmNotification(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
      related: (json['related'] as Map<String, dynamic>?) ?? const {},
    );
  }

  final String id;
  final String type;
  final String title;
  final String message;
  final bool read;
  final String createdAt;
  final Map<String, dynamic> related;
}
