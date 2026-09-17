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
    this.status = 'active',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.countyState = '',
    this.postcode = '',
    this.country = '',
    this.activities = const [],
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    final activity = json['activity'] as List<dynamic>? ?? const [];
    final firstName = json['first_name'] as String? ?? '';
    final lastName = json['last_name'] as String? ?? '';
    final name = json['name'] as String?;
    final address = json['address'] is Map<String, dynamic>
        ? json['address'] as Map<String, dynamic>
        : const <String, dynamic>{};
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
      status: json['status'] as String? ?? 'active',
      addressLine1:
          json['address_line_1'] as String? ??
          address['line_1'] as String? ??
          '',
      addressLine2:
          json['address_line_2'] as String? ??
          address['line_2'] as String? ??
          '',
      city: json['city'] as String? ?? address['city'] as String? ?? '',
      countyState:
          json['county_state'] as String? ??
          address['county_state'] as String? ??
          '',
      postcode:
          json['postcode'] as String? ?? address['postcode'] as String? ?? '',
      country:
          json['country'] as String? ?? address['country'] as String? ?? '',
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
  final String status;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String countyState;
  final String postcode;
  final String country;
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
    this.status = 'active',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.countyState = '',
    this.postcode = '',
    this.country = '',
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
      status: client.status,
      addressLine1: client.addressLine1,
      addressLine2: client.addressLine2,
      city: client.city,
      countyState: client.countyState,
      postcode: client.postcode,
      country: client.country,
      notes: client.notes,
    );
  }

  final String firstName;
  final String lastName;
  final String companyName;
  final String email;
  final String phone;
  final String website;
  final String status;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String countyState;
  final String postcode;
  final String country;
  final String notes;

  Map<String, dynamic> toJson() => {
    'first_name': firstName.trim(),
    'last_name': lastName.trim(),
    'company_name': companyName.trim(),
    'email': email.trim(),
    'phone': phone.trim(),
    'website': website.trim(),
    'status': status.trim().isEmpty ? 'active' : status.trim(),
    'address_line_1': addressLine1.trim(),
    'address_line_2': addressLine2.trim(),
    'city': city.trim(),
    'county_state': countyState.trim(),
    'postcode': postcode.trim(),
    'country': country.trim(),
    'notes': notes.trim(),
  };

  static (String, String) _splitName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.skip(1).join(' '));
  }
}
