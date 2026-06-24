import 'package:flutter/foundation.dart';

import '../core/errors/api_exception.dart';
import '../models/client.dart';
import '../models/crm_document.dart';
import '../models/crm_notification.dart';
import '../models/dashboard_data.dart';
import '../models/invoice.dart';
import '../models/job.dart';
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

  @override
  Future<List<Invoice>> fetchInvoices() => _service.fetchInvoices();

  @override
  Future<Invoice> fetchInvoice(int id) => _service.fetchInvoice(id);

  @override
  Future<Invoice> createInvoice(CreateInvoiceRequest request) =>
      _service.createInvoice(request);

  @override
  Future<Invoice> markInvoicePaid(int id) => _service.markInvoicePaid(id);

  @override
  Future<Invoice> markInvoiceUnpaid(int id) => _service.markInvoiceUnpaid(id);

  @override
  Future<List<Job>> fetchJobs({String status = 'all'}) =>
      _service.fetchJobs(status: status);

  @override
  Future<Job> fetchJob(int id) => _service.fetchJob(id);

  @override
  Future<Job> createJob(CreateJobRequest request) =>
      _service.createJob(request);

  @override
  Future<Job> completeJob(int id) => _service.completeJob(id);

  @override
  Future<Job> reopenJob(int id) => _service.reopenJob(id);

  @override
  Future<Job> addJobNotes(int id, String notes, {bool append = true}) =>
      _service.addJobNotes(id, notes, append: append);

  @override
  Future<List<CrmDocument>> fetchDocuments() => _service.fetchDocuments();

  @override
  Future<List<CrmDocument>> fetchClientDocuments(int clientId) =>
      _service.fetchClientDocuments(clientId);

  @override
  Future<CrmDocument> uploadClientDocument({
    required int clientId,
    required String title,
    required String type,
    required String filePath,
    String description = '',
    int projectId = 0,
  }) => _service.uploadClientDocument(
    clientId: clientId,
    title: title,
    type: type,
    filePath: filePath,
    description: description,
    projectId: projectId,
  );

  @override
  Future<DocumentDownload> fetchDocumentDownload(int id) =>
      _service.fetchDocumentDownload(id);

  @override
  Future<List<CrmNotification>> fetchNotifications() =>
      _service.fetchNotifications();

  @override
  Future<void> markNotificationRead(String id) =>
      _service.markNotificationRead(id);
}
