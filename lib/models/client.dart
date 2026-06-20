import 'activity.dart';

class Client {
  const Client({
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.notes,
    required this.initials,
    required this.activities,
  });

  final String name;
  final String email;
  final String phone;
  final String company;
  final String notes;
  final String initials;
  final List<Activity> activities;
}
