import 'package:daphnex_crm_mobile/core/errors/api_exception.dart';
import 'package:daphnex_crm_mobile/models/activity.dart';
import 'package:daphnex_crm_mobile/models/client.dart';
import 'package:daphnex_crm_mobile/models/dashboard_data.dart';
import 'package:daphnex_crm_mobile/models/reminder.dart';
import 'package:daphnex_crm_mobile/services/crm_api.dart';

class FakeCrmApi implements CrmApi {
  bool session = false;
  bool failLogin = false;
  String? lastLoginEmail;
  int? completedReminderId;

  final clients = <Client>[
    const Client(
      id: 1,
      name: 'Olivia Bennett',
      email: 'olivia@example.test',
      phone: '07700 900123',
      company: 'Northstar Studio',
      notes: 'Live profile notes',
      activities: [
        Activity(
          title: 'Client Updated',
          detail: '',
          date: '2026-06-22T12:00:00Z',
        ),
      ],
    ),
    const Client(
      id: 2,
      name: 'Marcus Chen',
      email: 'marcus@example.test',
      phone: '07700 900456',
      company: 'Brightline Digital',
    ),
  ];

  final reminders = <Reminder>[
    const Reminder(
      id: 1,
      title: 'Follow up with Olivia',
      date: '2026-06-24',
      time: '14:00',
      status: 'pending',
      clientId: 1,
    ),
  ];

  @override
  Future<bool> hasSession() async => session;

  @override
  Future<void> login({required String email, required String password}) async {
    lastLoginEmail = email;
    if (failLogin) {
      throw const ApiException('Invalid email or password.', statusCode: 401);
    }
    session = true;
  }

  @override
  Future<void> logout() async => session = false;

  @override
  Future<DashboardData> fetchDashboard() async => const DashboardData(
    totalClients: 2,
    activeJobs: 3,
    pendingInvoices: 4,
    upcomingReminders: 1,
  );

  @override
  Future<List<Client>> fetchClients() async => List.of(clients);

  @override
  Future<Client> fetchClient(int id) async =>
      clients.firstWhere((client) => client.id == id);

  @override
  Future<List<Reminder>> fetchReminders() async => List.of(reminders);

  @override
  Future<Reminder> createReminder(CreateReminderRequest request) async {
    final reminder = Reminder(
      id: reminders.length + 1,
      title: request.title,
      date: request.date,
      time: request.time,
      status: 'pending',
      clientId: request.clientId,
    );
    reminders.add(reminder);
    return reminder;
  }

  @override
  Future<Reminder> completeReminder(int id) async {
    completedReminderId = id;
    final index = reminders.indexWhere((reminder) => reminder.id == id);
    final current = reminders[index];
    final completed = Reminder(
      id: current.id,
      title: current.title,
      date: current.date,
      time: current.time,
      status: 'completed',
      clientId: current.clientId,
    );
    reminders[index] = completed;
    return completed;
  }
}
