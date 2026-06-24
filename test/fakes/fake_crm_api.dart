import 'package:daphnex_crm_mobile/core/errors/api_exception.dart';
import 'package:daphnex_crm_mobile/models/activity.dart';
import 'package:daphnex_crm_mobile/models/client.dart';
import 'package:daphnex_crm_mobile/models/crm_document.dart';
import 'package:daphnex_crm_mobile/models/crm_notification.dart';
import 'package:daphnex_crm_mobile/models/dashboard_data.dart';
import 'package:daphnex_crm_mobile/models/invoice.dart';
import 'package:daphnex_crm_mobile/models/job.dart';
import 'package:daphnex_crm_mobile/models/reminder.dart';
import 'package:daphnex_crm_mobile/services/crm_api.dart';

class FakeCrmApi implements CrmApi {
  bool session = false;
  bool failLogin = false;
  String? lastLoginEmail;
  int? completedReminderId;
  int? completedJobId;
  int? reopenedJobId;
  int? paidInvoiceId;
  int? unpaidInvoiceId;

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

  final invoices = <Invoice>[
    const Invoice(
      id: 1,
      clientId: 1,
      clientName: 'Northstar Studio',
      invoiceNumber: 'INV-2026-0001',
      issueDate: '2026-06-24',
      dueDate: '2026-07-01',
      totalAmount: 15000,
      amountPaid: 0,
      balance: 15000,
      status: 'sent',
      notes: 'Test invoice',
    ),
  ];

  final jobs = <Job>[
    const Job(
      id: 1,
      clientId: 1,
      clientName: 'Northstar Studio',
      title: 'Website maintenance',
      description: 'Monthly support',
      status: 'in_progress',
      startDate: '2026-06-24',
      completionDate: null,
      notes: 'Initial notes',
      recentActivity: ['project_created'],
    ),
  ];

  final documents = <CrmDocument>[
    const CrmDocument(
      id: 1,
      clientId: 1,
      clientName: 'Northstar Studio',
      projectId: 0,
      projectName: '',
      type: 'agreement',
      title: 'Signed Agreement',
      description: 'Client agreement',
      fileName: 'agreement.pdf',
      fileSize: 2048,
      mimeType: 'application/pdf',
      status: 'active',
      downloadEndpoint: 'https://example.test/download',
      createdAt: '2026-06-24T10:00:00Z',
    ),
  ];

  final notifications = <CrmNotification>[
    const CrmNotification(
      id: 'reminder:1',
      type: 'upcoming_reminder',
      title: 'Follow up with Olivia',
      message: 'Upcoming CRM reminder.',
      read: false,
      createdAt: '2026-06-24T10:00:00Z',
      related: {'client_id': 1, 'reminder_id': 1},
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
    completedJobs: 1,
    pendingInvoices: 4,
    unpaidInvoices: 2,
    outstandingInvoiceAmount: 15000,
    upcomingReminders: 1,
    unreadNotifications: 1,
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

  @override
  Future<List<Invoice>> fetchInvoices() async => List.of(invoices);

  @override
  Future<Invoice> fetchInvoice(int id) async =>
      invoices.firstWhere((invoice) => invoice.id == id);

  @override
  Future<Invoice> createInvoice(CreateInvoiceRequest request) async {
    final invoice = Invoice(
      id: invoices.length + 1,
      clientId: request.clientId,
      clientName: 'Northstar Studio',
      invoiceNumber: 'INV-TEST-${invoices.length + 1}',
      issueDate: request.issueDate,
      dueDate: request.dueDate,
      totalAmount: 10000,
      amountPaid: 0,
      balance: 10000,
      status: 'sent',
      notes: request.notes,
    );
    invoices.add(invoice);
    return invoice;
  }

  @override
  Future<Invoice> markInvoicePaid(int id) async {
    paidInvoiceId = id;
    return fetchInvoice(id);
  }

  @override
  Future<Invoice> markInvoiceUnpaid(int id) async {
    unpaidInvoiceId = id;
    return fetchInvoice(id);
  }

  @override
  Future<List<Job>> fetchJobs({String status = 'all'}) async =>
      status == 'completed'
      ? jobs.where((job) => job.status == 'completed').toList()
      : List.of(jobs);

  @override
  Future<Job> fetchJob(int id) async => jobs.firstWhere((job) => job.id == id);

  @override
  Future<Job> createJob(CreateJobRequest request) async {
    final job = Job(
      id: jobs.length + 1,
      clientId: request.clientId,
      clientName: 'Northstar Studio',
      title: request.title,
      description: request.description,
      status: request.status,
      startDate: request.startDate,
      completionDate: null,
      notes: request.notes,
    );
    jobs.add(job);
    return job;
  }

  @override
  Future<Job> completeJob(int id) async {
    completedJobId = id;
    return fetchJob(id);
  }

  @override
  Future<Job> reopenJob(int id) async {
    reopenedJobId = id;
    return fetchJob(id);
  }

  @override
  Future<Job> addJobNotes(int id, String notes, {bool append = true}) async =>
      fetchJob(id);

  @override
  Future<List<CrmDocument>> fetchDocuments() async => List.of(documents);

  @override
  Future<List<CrmDocument>> fetchClientDocuments(int clientId) async =>
      documents.where((document) => document.clientId == clientId).toList();

  @override
  Future<CrmDocument> uploadClientDocument({
    required int clientId,
    required String title,
    required String type,
    required String filePath,
    String description = '',
    int projectId = 0,
  }) async {
    final document = CrmDocument(
      id: documents.length + 1,
      clientId: clientId,
      clientName: 'Northstar Studio',
      projectId: projectId,
      projectName: '',
      type: type,
      title: title,
      description: description,
      fileName: filePath.split('\\').last,
      fileSize: 1,
      mimeType: 'application/pdf',
      status: 'active',
      downloadEndpoint: 'https://example.test/download',
      createdAt: '2026-06-24T10:00:00Z',
    );
    documents.add(document);
    return document;
  }

  @override
  Future<DocumentDownload> fetchDocumentDownload(int id) async =>
      const DocumentDownload(
        fileName: 'agreement.pdf',
        mimeType: 'application/pdf',
        fileSize: 2048,
        downloadUrl: 'https://example.test/agreement.pdf',
      );

  @override
  Future<List<CrmNotification>> fetchNotifications() async =>
      List.of(notifications);

  @override
  Future<void> markNotificationRead(String id) async {}
}
