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

abstract interface class CrmApi {
  CommercialSession? get currentSession;
  void setSessionInvalidatedHandler(void Function(ApiException error)? handler);
  Future<bool> hasSession();
  Future<CommercialSession> bootstrapSession();
  Future<void> login({required String email, required String password});
  Future<void> logout();
  Future<DashboardData> fetchDashboard();
  Future<List<Client>> fetchClients();
  Future<Client> fetchClient(int id);
  Future<Client> createClient(CreateClientRequest request);
  Future<Client> updateClient(int id, CreateClientRequest request);
  Future<void> deleteClient(int id);
  Future<List<Reminder>> fetchReminders({int? clientId});
  Future<Reminder> createReminder(CreateReminderRequest request);
  Future<Reminder> updateReminder(int id, CreateReminderRequest request);
  Future<Reminder> completeReminder(int id);
  Future<void> deleteReminder(int id);
  Future<List<CrmTask>> fetchTasks({String status = 'all', int? clientId});
  Future<CrmTask> fetchTask(int id);
  Future<CrmTask> createTask(CreateTaskRequest request);
  Future<CrmTask> updateTask(int id, CreateTaskRequest request);
  Future<void> deleteTask(int id);
  Future<List<Invoice>> fetchInvoices({int? clientId});
  Future<Invoice> fetchInvoice(int id);
  Future<Invoice> createInvoice(CreateInvoiceRequest request);
  Future<InvoicePdfFile> fetchInvoicePdf(int id);
  Future<InvoicePdfFile> downloadInvoicePdf(int id);
  Future<InvoicePayment> fetchInvoicePaymentLink(int id);
  Future<Invoice> markInvoicePaid(int id);
  Future<Invoice> markInvoiceUnpaid(int id);
  Future<Invoice> addInvoicePayment(
    int id,
    CreateInvoicePaymentRequest request,
  );
  Future<void> deleteInvoice(int id);
  Future<List<Job>> fetchJobs({String status = 'all', int? clientId});
  Future<Job> fetchJob(int id);
  Future<Job> createJob(CreateJobRequest request);
  Future<Job> updateJob(int id, CreateJobRequest request);
  Future<Job> completeJob(int id);
  Future<Job> reopenJob(int id);
  Future<Job> addJobNotes(int id, String notes, {bool append = true});
  Future<void> deleteJob(int id);
  Future<Job> clearJobExpenses(int id);
  Future<List<ProjectExpense>> fetchProjectExpenses({
    int? clientId,
    int? projectId,
  });
  Future<List<ProjectExpense>> fetchJobExpenses(int jobId);
  Future<ProjectExpense> fetchProjectExpense(int id);
  Future<ProjectExpense> createJobExpense(
    int jobId,
    CreateProjectExpenseRequest request,
  );
  Future<ProjectExpense> updateProjectExpense(
    int id,
    CreateProjectExpenseRequest request,
  );
  Future<void> deleteProjectExpense(int id);
  Future<List<Quote>> fetchQuotes({int? clientId});
  Future<Quote> fetchQuote(int id);
  Future<Quote> createQuote(CreateQuoteRequest request);
  Future<Quote> updateQuote(int id, CreateQuoteRequest request);
  Future<QuotePdfFile> fetchQuotePdf(int id);
  Future<QuotePdfFile> downloadQuotePdf(int id);
  Future<void> deleteQuote(int id);
  Future<List<TurnoverReportRow>> fetchTurnoverReport();
  Future<List<CrmDocument>> fetchDocuments();
  Future<List<CrmDocument>> fetchClientDocuments(int clientId);
  Future<CrmDocument> uploadClientDocument({
    required int clientId,
    required String title,
    required String type,
    required String filePath,
    String description = '',
    int projectId = 0,
  });
  Future<DocumentDownload> fetchDocumentDownload(int id);
  Future<void> deleteDocument(int id);
  Future<List<CrmNotification>> fetchNotifications();
  Future<void> markNotificationRead(String id);
}
