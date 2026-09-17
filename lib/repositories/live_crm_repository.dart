import 'package:flutter/foundation.dart';

import '../core/errors/api_exception.dart';
import '../models/client.dart';
import '../models/commercial_session.dart';
import '../models/crm_document.dart';
import '../models/crm_notification.dart';
import '../models/crm_task.dart';
import '../models/dashboard_data.dart';
import '../models/invoice.dart';
import '../models/job.dart';
import '../models/project_expense.dart';
import '../models/quote.dart';
import '../models/reminder.dart';
import '../models/turnover_report.dart';
import '../services/crm_api.dart';
import '../services/crm_api_service.dart';
import '../services/mock_crm_service.dart';

class LiveCrmRepository implements CrmApi {
  LiveCrmRepository({CrmApiService? service})
    : _service = service ?? CrmApiService();

  final CrmApiService _service;

  @override
  CommercialSession? get currentSession => _service.currentSession;

  @override
  void setSessionInvalidatedHandler(
    void Function(ApiException error)? handler,
  ) {
    _service.onSessionInvalidated = handler;
  }

  @override
  Future<bool> hasSession() => _service.hasSession();

  @override
  Future<CommercialSession> bootstrapSession() => _service.bootstrapSession();

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
  Future<Client> createClient(CreateClientRequest request) =>
      _service.createClient(request);

  @override
  Future<Client> updateClient(int id, CreateClientRequest request) =>
      _service.updateClient(id, request);

  @override
  Future<void> deleteClient(int id) => _service.deleteClient(id);

  @override
  Future<List<Reminder>> fetchReminders({int? clientId}) =>
      _service.fetchReminders(clientId: clientId);

  @override
  Future<Reminder> createReminder(CreateReminderRequest request) =>
      _service.createReminder(request);

  @override
  Future<Reminder> updateReminder(int id, CreateReminderRequest request) =>
      _service.updateReminder(id, request);

  @override
  Future<Reminder> completeReminder(int id) => _service.completeReminder(id);

  @override
  Future<void> deleteReminder(int id) => _service.deleteReminder(id);

  @override
  Future<List<CrmTask>> fetchTasks({String status = 'all', int? clientId}) =>
      _service.fetchTasks(status: status, clientId: clientId);

  @override
  Future<CrmTask> fetchTask(int id) => _service.fetchTask(id);

  @override
  Future<CrmTask> createTask(CreateTaskRequest request) =>
      _service.createTask(request);

  @override
  Future<CrmTask> updateTask(int id, CreateTaskRequest request) =>
      _service.updateTask(id, request);

  @override
  Future<void> deleteTask(int id) => _service.deleteTask(id);

  @override
  Future<List<Invoice>> fetchInvoices({int? clientId}) =>
      _service.fetchInvoices(clientId: clientId);

  @override
  Future<Invoice> fetchInvoice(int id) => _service.fetchInvoice(id);

  @override
  Future<Invoice> createInvoice(CreateInvoiceRequest request) =>
      _service.createInvoice(request);

  @override
  Future<InvoicePdfFile> fetchInvoicePdf(int id) =>
      _service.fetchInvoicePdf(id);

  @override
  Future<InvoicePdfFile> downloadInvoicePdf(int id) =>
      _service.downloadInvoicePdf(id);

  @override
  Future<InvoicePayment> fetchInvoicePaymentLink(int id) =>
      _service.fetchInvoicePaymentLink(id);

  @override
  Future<Invoice> markInvoicePaid(int id) => _service.markInvoicePaid(id);

  @override
  Future<Invoice> markInvoiceUnpaid(int id) => _service.markInvoiceUnpaid(id);

  @override
  Future<Invoice> addInvoicePayment(
    int id,
    CreateInvoicePaymentRequest request,
  ) => _service.addInvoicePayment(id, request);

  @override
  Future<void> deleteInvoice(int id) => _service.deleteInvoice(id);

  @override
  Future<List<Job>> fetchJobs({String status = 'all', int? clientId}) =>
      _service.fetchJobs(status: status, clientId: clientId);

  @override
  Future<Job> fetchJob(int id) => _service.fetchJob(id);

  @override
  Future<Job> createJob(CreateJobRequest request) =>
      _service.createJob(request);

  @override
  Future<Job> updateJob(int id, CreateJobRequest request) =>
      _service.updateJob(id, request);

  @override
  Future<Job> completeJob(int id) => _service.completeJob(id);

  @override
  Future<Job> reopenJob(int id) => _service.reopenJob(id);

  @override
  Future<Job> addJobNotes(int id, String notes, {bool append = true}) =>
      _service.addJobNotes(id, notes, append: append);

  @override
  Future<void> deleteJob(int id) => _service.deleteJob(id);

  @override
  Future<Job> clearJobExpenses(int id) => _service.clearJobExpenses(id);

  @override
  Future<List<ProjectExpense>> fetchProjectExpenses({
    int? clientId,
    int? projectId,
  }) => _service.fetchProjectExpenses(clientId: clientId, projectId: projectId);

  @override
  Future<List<ProjectExpense>> fetchJobExpenses(int jobId) =>
      _service.fetchJobExpenses(jobId);

  @override
  Future<ProjectExpense> fetchProjectExpense(int id) =>
      _service.fetchProjectExpense(id);

  @override
  Future<ProjectExpense> createJobExpense(
    int jobId,
    CreateProjectExpenseRequest request,
  ) => _service.createJobExpense(jobId, request);

  @override
  Future<ProjectExpense> updateProjectExpense(
    int id,
    CreateProjectExpenseRequest request,
  ) => _service.updateProjectExpense(id, request);

  @override
  Future<void> deleteProjectExpense(int id) =>
      _service.deleteProjectExpense(id);

  @override
  Future<List<Quote>> fetchQuotes({int? clientId}) =>
      _service.fetchQuotes(clientId: clientId);

  @override
  Future<Quote> fetchQuote(int id) => _service.fetchQuote(id);

  @override
  Future<Quote> createQuote(CreateQuoteRequest request) =>
      _service.createQuote(request);

  @override
  Future<Quote> updateQuote(int id, CreateQuoteRequest request) =>
      _service.updateQuote(id, request);

  @override
  Future<QuotePdfFile> fetchQuotePdf(int id) => _service.fetchQuotePdf(id);

  @override
  Future<QuotePdfFile> downloadQuotePdf(int id) =>
      _service.downloadQuotePdf(id);

  @override
  Future<void> deleteQuote(int id) => _service.deleteQuote(id);

  @override
  Future<List<TurnoverReportRow>> fetchTurnoverReport() =>
      _service.fetchTurnoverReport();

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
  Future<void> deleteDocument(int id) => _service.deleteDocument(id);

  @override
  Future<List<CrmNotification>> fetchNotifications() =>
      _service.fetchNotifications();

  @override
  Future<void> markNotificationRead(String id) =>
      _service.markNotificationRead(id);
}
