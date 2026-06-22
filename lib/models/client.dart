import 'activity.dart';

class Client {
  const Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    this.notes = '',
    this.website = '',
    this.activities = const [],
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    final activity = json['activity'] as List<dynamic>? ?? const [];
    return Client(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      company: json['company'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      website: json['website'] as String? ?? '',
      activities: activity
          .whereType<Map<String, dynamic>>()
          .map(Activity.fromJson)
          .toList(growable: false),
    );
  }

  final int id;
  final String name;
  final String email;
  final String phone;
  final String company;
  final String notes;
  final String website;
  final List<Activity> activities;

  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    final value = words.take(2).map((word) => word[0].toUpperCase()).join();
    return value.isEmpty ? '—' : value;
  }
}
