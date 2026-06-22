import '../models/client.dart';
import '../models/dashboard_data.dart';
import '../models/reminder.dart';

abstract interface class CrmApi {
  Future<bool> hasSession();
  Future<void> login({required String email, required String password});
  Future<void> logout();
  Future<DashboardData> fetchDashboard();
  Future<List<Client>> fetchClients();
  Future<Client> fetchClient(int id);
  Future<List<Reminder>> fetchReminders();
  Future<Reminder> createReminder(CreateReminderRequest request);
  Future<Reminder> completeReminder(int id);
}
