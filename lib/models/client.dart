import 'activity.dart';

class Client {
  const Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    this.firstName = '',
    this.lastName = '',
    this.notes = '',
    this.website = '',
    this.activities = const [],
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    final activity = json['activity'] as List<dynamic>? ?? const [];
    final firstName = json['first_name'] as String? ?? '';
    final lastName = json['last_name'] as String? ?? '';
    final name = json['name'] as String?;
    return Client(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: name == null || name.isEmpty ? '$firstName $lastName'.trim() : name,
      firstName: firstName,
      lastName: lastName,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      company:
          json['company'] as String? ??
          json['company_name'] as String? ??
          json['business_name'] as String? ??
          '',
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
  final String firstName;
  final String lastName;
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

class CreateClientRequest {
  const CreateClientRequest({
    required this.firstName,
    required this.lastName,
    this.companyName = '',
    this.email = '',
    this.phone = '',
    this.website = '',
    this.notes = '',
  });

  factory CreateClientRequest.fromClient(Client client) {
    final derived = _splitName(client.name);
    return CreateClientRequest(
      firstName: client.firstName.isNotEmpty ? client.firstName : derived.$1,
      lastName: client.lastName.isNotEmpty ? client.lastName : derived.$2,
      companyName: client.company,
      email: client.email,
      phone: client.phone,
      website: client.website,
      notes: client.notes,
    );
  }

  final String firstName;
  final String lastName;
  final String companyName;
  final String email;
  final String phone;
  final String website;
  final String notes;

  Map<String, dynamic> toJson() => {
    'first_name': firstName.trim(),
    'last_name': lastName.trim(),
    'company_name': companyName.trim(),
    'email': email.trim(),
    'phone': phone.trim(),
    'website': website.trim(),
    'notes': notes.trim(),
  };

  static (String, String) _splitName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.skip(1).join(' '));
  }
}
