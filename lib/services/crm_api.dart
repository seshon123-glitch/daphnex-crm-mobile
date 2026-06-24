import '../models/client.dart';
import '../models/crm_document.dart';
import '../models/crm_notification.dart';
import '../models/dashboard_data.dart';
import '../models/invoice.dart';
import '../models/job.dart';
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
  Future<List<Invoice>> fetchInvoices();
  Future<Invoice> fetchInvoice(int id);
  Future<Invoice> createInvoice(CreateInvoiceRequest request);
  Future<Invoice> markInvoicePaid(int id);
  Future<Invoice> markInvoiceUnpaid(int id);
  Future<List<Job>> fetchJobs({String status = 'all'});
  Future<Job> fetchJob(int id);
  Future<Job> createJob(CreateJobRequest request);
  Future<Job> completeJob(int id);
  Future<Job> reopenJob(int id);
  Future<Job> addJobNotes(int id, String notes, {bool append = true});
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
  Future<List<CrmNotification>> fetchNotifications();
  Future<void> markNotificationRead(String id);
}
