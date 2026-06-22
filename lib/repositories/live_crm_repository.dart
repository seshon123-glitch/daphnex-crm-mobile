import 'package:flutter/foundation.dart';

import '../core/errors/api_exception.dart';
import '../models/client.dart';
import '../models/dashboard_data.dart';
import '../models/reminder.dart';
import '../services/crm_api.dart';
import '../services/crm_api_service.dart';
import '../services/mock_crm_service.dart';

class LiveCrmRepository implements CrmApi {
  LiveCrmRepository({CrmApiService? service})
    : _service = service ?? CrmApiService();

  final CrmApiService _service;

  @override
  Future<bool> hasSession() => _service.hasSession();

  @override
  Future<void> login({required String email, required String password}) =>
      _service.login(email: email, password: password);

  @override
  Future<void> logout() => _service.logout();

  @override
  Future<DashboardData> fetchDashboard() async {
    try {
      return await _service.fetchDashboard();
    } on ApiException catch (error) {
      if (error.isAuthenticationError) rethrow;
      debugPrint(
        'Daphnex CRM dashboard API failed; using mock fallback: $error',
      );
      return MockCrmService.dashboardFallback;
    }
  }

  @override
  Future<List<Client>> fetchClients() => _service.fetchClients();

  @override
  Future<Client> fetchClient(int id) => _service.fetchClient(id);

  @override
  Future<List<Reminder>> fetchReminders() => _service.fetchReminders();

  @override
  Future<Reminder> createReminder(CreateReminderRequest request) =>
      _service.createReminder(request);

  @override
  Future<Reminder> completeReminder(int id) => _service.completeReminder(id);
}
