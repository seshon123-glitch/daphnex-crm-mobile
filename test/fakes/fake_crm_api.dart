import 'dart:typed_data';

import 'package:daphnex_crm_mobile/core/errors/api_exception.dart';
import 'package:daphnex_crm_mobile/models/activity.dart';
import 'package:daphnex_crm_mobile/models/client.dart';
import 'package:daphnex_crm_mobile/models/commercial_session.dart';
import 'package:daphnex_crm_mobile/models/crm_document.dart';
import 'package:daphnex_crm_mobile/models/crm_notification.dart';
import 'package:daphnex_crm_mobile/models/crm_task.dart';
import 'package:daphnex_crm_mobile/models/dashboard_data.dart';
import 'package:daphnex_crm_mobile/models/invoice.dart';
import 'package:daphnex_crm_mobile/models/job.dart';
import 'package:daphnex_crm_mobile/models/project_expense.dart';
import 'package:daphnex_crm_mobile/models/quote.dart';
import 'package:daphnex_crm_mobile/models/reminder.dart';
import 'package:daphnex_crm_mobile/models/turnover_report.dart';
import 'package:daphnex_crm_mobile/services/crm_api.dart';

class FakeCrmApi implements CrmApi {
  bool session = false;
  bool failLogin = false;
  ApiException? bootstrapError;
  CommercialRole sessionRole = CommercialRole.owner;
  String sessionUserDisplayName = 'Daphnex User';
  String sessionCompanyName = 'Northstar Studio';
  String sessionBrandingInitials = 'NS';
  DashboardData dashboardData = const DashboardData(
    totalClients: 2,
    activeJobs: 3,
    completedJobs: 1,
    pendingInvoices: 4,
    unpaidInvoices: 2,
    outstandingInvoiceAmount: 15000,
    upcomingReminders: 1,
    unreadNotifications: 1,
  );
  String? lastLoginEmail;
  int? completedReminderId;
  int? updatedReminderId;
  int? deletedReminderId;
  CreateReminderRequest? lastReminderUpdateRequest;
  int? completedJobId;
  int? reopenedJobId;
  int? paidInvoiceId;
  int? unpaidInvoiceId;
  int? paymentInvoiceId;
  int? deletedProjectExpenseId;
  CreateProjectExpenseRequest? lastProjectExpenseRequest;
  CreateInvoicePaymentRequest? lastPaymentRequest;
  int? deletedQuoteId;
  CreateQuoteRequest? lastQuoteRequest;
  int fetchRemindersCalls = 0;

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

  final projectExpenses = <ProjectExpense>[
    const ProjectExpense(
      id: 1,
      clientId: 1,
      clientName: 'Olivia Bennett',
      projectId: 1,
      projectName: 'Website refresh',
      expenseDate: '2026-09-10',
      description: 'Materials purchased',
      amount: 12000,
      currency: 'GBP',
    ),
  ];

  final turnoverRows = <TurnoverReportRow>[
    const TurnoverReportRow(
      month: '2026-09',
      totalInvoices: 2,
      totalInvoiced: 94000,
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
      clientName: 'Olivia Bennett',
      projectId: 1,
      projectName: 'Website maintenance',
      description: 'Call about the next project milestone.',
    ),
  ];

  final tasks = <CrmTask>[
    const CrmTask(
      id: 1,
      clientId: 1,
      clientName: 'Northstar Studio',
      projectId: 1,
      projectName: 'Website maintenance',
      title: 'Prepare homepage copy',
      dueDate: '2026-06-25',
      priority: 'medium',
      status: 'pending',
      description: 'Draft client homepage content.',
      internalNotes: 'Use the agreed tone of voice.',
    ),
  ];

  final invoices = <Invoice>[
    const Invoice(
      id: 1,
      clientId: 1,
      clientName: 'Northstar Studio',
      projectId: 1,
      projectName: 'Website maintenance',
      invoiceNumber: 'INV-2026-0001',
      issueDate: '2026-06-24',
      dueDate: '2026-07-01',
      totalAmount: 15000,
      amountPaid: 0,
      balance: 15000,
      status: 'sent',
      notes: 'Test invoice',
      payments: [
        InvoicePaymentRecord(
          id: 1,
          amount: 5000,
          paidAt: '2026-06-25',
          method: 'bank_transfer',
          reference: 'TEST-1',
        ),
      ],
      pdfUrl: 'https://example.test/invoices/1/pdf',
      downloadPdfUrl: 'https://example.test/invoices/1/download-pdf',
      payment: InvoicePayment(
        configured: true,
        paymentUrl: 'https://example.test/pay',
        amountDue: 15000,
      ),
    ),
  ];

  final quotes = <Quote>[
    const Quote(
      id: 1,
      clientId: 1,
      clientName: 'Northstar Studio',
      quoteReference: 'QUOTE-000001',
      quoteDate: '2026-09-15',
      subtotalAmount: 25000,
      totalAmount: 25000,
      status: 'sent',
      notes: 'Pilot quote',
      pdfUrl: 'https://example.test/quotes/1/pdf',
      downloadPdfUrl: 'https://example.test/quotes/1/download-pdf',
      shareUrl: 'https://example.test/quotes/1/public',
      items: [
        QuoteItem(
          description: 'Discovery',
          quantity: 1,
          unitAmount: 25000,
          lineTotal: 25000,
        ),
      ],
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
  CommercialSession? currentSession;

  void Function(ApiException error)? _onSessionInvalidated;

  @override
  void setSessionInvalidatedHandler(
    void Function(ApiException error)? handler,
  ) {
    _onSessionInvalidated = handler;
  }

  @override
  Future<bool> hasSession() async {
    if (!session) return false;
    await bootstrapSession();
    return true;
  }

  @override
  Future<CommercialSession> bootstrapSession() async {
    final error = bootstrapError;
    if (error != null) {
      _clearFor(error);
      throw error;
    }
    currentSession = commercialSessionFixture(
      role: sessionRole,
      userDisplayName: sessionUserDisplayName,
      companyName: sessionCompanyName,
      brandingInitials: sessionBrandingInitials,
    );
    return currentSession!;
  }

  Future<void> _ensureProtectedAccess() async {
    final error = bootstrapError;
    if (error != null) {
      _clearFor(error);
      throw error;
    }
  }

  void _clearFor(ApiException error) {
    session = false;
    currentSession = null;
    if (error.shouldClearSession) _onSessionInvalidated?.call(error);
  }

  void simulateSessionInvalidated(ApiException error) {
    bootstrapError = error;
    _clearFor(error);
  }

  @override
  Future<void> login({required String email, required String password}) async {
    lastLoginEmail = email;
    if (failLogin) {
      throw const ApiException('Invalid email or password.', statusCode: 401);
    }
    session = true;
    await bootstrapSession();
  }

  @override
  Future<void> logout() async {
    session = false;
    currentSession = null;
  }

  @override
  Future<DashboardData> fetchDashboard() async => dashboardData;

  @override
  Future<List<Client>> fetchClients() async {
    await _ensureProtectedAccess();
    return List.of(clients);
  }

  @override
  Future<Client> fetchClient(int id) async =>
      clients.firstWhere((client) => client.id == id);

  @override
  Future<Client> createClient(CreateClientRequest request) async {
    await _ensureProtectedAccess();
    final client = Client(
      id: clients.length + 1,
      name: '${request.firstName} ${request.lastName}'.trim(),
      firstName: request.firstName,
      lastName: request.lastName,
      email: request.email,
      phone: request.phone,
      company: request.companyName,
      notes: request.notes,
      website: request.website,
      status: request.status,
      addressLine1: request.addressLine1,
      addressLine2: request.addressLine2,
      city: request.city,
      countyState: request.countyState,
      postcode: request.postcode,
      country: request.country,
    );
    clients.add(client);
    return client;
  }

  @override
  Future<Client> updateClient(int id, CreateClientRequest request) async {
    await _ensureProtectedAccess();
    final index = clients.indexWhere((client) => client.id == id);
    final client = Client(
      id: id,
      name: '${request.firstName} ${request.lastName}'.trim(),
      firstName: request.firstName,
      lastName: request.lastName,
      email: request.email,
      phone: request.phone,
      company: request.companyName,
      notes: request.notes,
      website: request.website,
      status: request.status,
      addressLine1: request.addressLine1,
      addressLine2: request.addressLine2,
      city: request.city,
      countyState: request.countyState,
      postcode: request.postcode,
      country: request.country,
      activities: clients[index].activities,
    );
    clients[index] = client;
    return client;
  }

  @override
  Future<void> deleteClient(int id) async {
    await _ensureProtectedAccess();
    clients.removeWhere((client) => client.id == id);
  }

  @override
  Future<List<Reminder>> fetchReminders({int? clientId}) async {
    fetchRemindersCalls++;
    return clientId == null
        ? List.of(reminders)
        : reminders.where((reminder) => reminder.clientId == clientId).toList();
  }

  @override
  Future<Reminder> createReminder(CreateReminderRequest request) async {
    final reminder = Reminder(
      id: reminders.length + 1,
      title: request.title,
      date: request.date,
      time: request.time,
      status: request.status,
      clientId: request.clientId,
      clientName: clients
          .firstWhere(
            (client) => client.id == request.clientId,
            orElse: () => clients.first,
          )
          .name,
      projectId: request.projectId,
      projectName: request.projectId == 0 ? '' : 'Website maintenance',
      priority: request.priority,
      description: request.description,
    );
    reminders.add(reminder);
    return reminder;
  }

  @override
  Future<Reminder> updateReminder(int id, CreateReminderRequest request) async {
    updatedReminderId = id;
    lastReminderUpdateRequest = request;
    final index = reminders.indexWhere((reminder) => reminder.id == id);
    final updated = Reminder(
      id: id,
      title: request.title,
      date: request.date,
      time: request.time,
      status: request.status,
      clientId: request.clientId,
      clientName: clients
          .firstWhere(
            (client) => client.id == request.clientId,
            orElse: () => clients.first,
          )
          .name,
      projectId: request.projectId,
      projectName: request.projectId == 0 ? '' : 'Website maintenance',
      priority: request.priority,
      description: request.description,
    );
    reminders[index] = updated;
    return updated;
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
      clientName: current.clientName,
      projectId: current.projectId,
      projectName: current.projectName,
      priority: current.priority,
      description: current.description,
    );
    reminders[index] = completed;
    return completed;
  }

  @override
  Future<void> deleteReminder(int id) async {
    deletedReminderId = id;
    reminders.removeWhere((reminder) => reminder.id == id);
  }

  @override
  Future<List<CrmTask>> fetchTasks({
    String status = 'all',
    int? clientId,
  }) async {
    final filtered = tasks.where((task) {
      final statusMatches = status == 'all' || task.status == status;
      final clientMatches = clientId == null || task.clientId == clientId;
      return statusMatches && clientMatches;
    });
    return filtered.toList();
  }

  @override
  Future<CrmTask> fetchTask(int id) async =>
      tasks.firstWhere((task) => task.id == id);

  @override
  Future<CrmTask> createTask(CreateTaskRequest request) async {
    final task = CrmTask(
      id: tasks.length + 1,
      clientId: request.clientId,
      clientName: 'Northstar Studio',
      projectId: request.projectId,
      projectName: request.projectId == 0 ? '' : 'Website maintenance',
      assignedUserId: request.assignedUserId,
      title: request.title,
      dueDate: request.dueDate,
      priority: request.priority,
      status: request.status,
      description: request.description,
      internalNotes: request.internalNotes,
    );
    tasks.add(task);
    return task;
  }

  @override
  Future<CrmTask> updateTask(int id, CreateTaskRequest request) async {
    final index = tasks.indexWhere((task) => task.id == id);
    final updated = CrmTask(
      id: id,
      clientId: request.clientId,
      clientName: 'Northstar Studio',
      projectId: request.projectId,
      projectName: request.projectId == 0 ? '' : 'Website maintenance',
      assignedUserId: request.assignedUserId,
      title: request.title,
      dueDate: request.dueDate,
      priority: request.priority,
      status: request.status,
      description: request.description,
      internalNotes: request.internalNotes,
    );
    tasks[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTask(int id) async {
    tasks.removeWhere((task) => task.id == id);
  }

  @override
  Future<List<Invoice>> fetchInvoices({int? clientId}) async => clientId == null
      ? List.of(invoices)
      : invoices.where((invoice) => invoice.clientId == clientId).toList();

  @override
  Future<Invoice> fetchInvoice(int id) async =>
      invoices.firstWhere((invoice) => invoice.id == id);

  @override
  Future<Invoice> createInvoice(CreateInvoiceRequest request) async {
    final client = clients.firstWhere(
      (client) => client.id == request.clientId,
    );
    final total = request.items.fold<int>(0, (sum, item) {
      final amount = (double.tryParse(item.unitAmount) ?? 0) * 100;
      final quantity = double.tryParse(item.quantity) ?? 1;
      return sum + (amount * quantity).round();
    });
    final invoice = Invoice(
      id: invoices.length + 1,
      clientId: request.clientId,
      clientName: client.company.isEmpty ? client.name : client.company,
      invoiceNumber: 'INV-TEST-${invoices.length + 1}',
      issueDate: request.issueDate,
      dueDate: request.dueDate,
      totalAmount: total,
      amountPaid: 0,
      balance: total,
      status: request.status,
      notes: request.notes,
      items: request.items
          .map(
            (item) => InvoiceItem(
              description: item.description,
              quantity: double.tryParse(item.quantity) ?? 1,
              unitAmount: ((double.tryParse(item.unitAmount) ?? 0) * 100)
                  .round(),
              lineTotal:
                  ((double.tryParse(item.unitAmount) ?? 0) *
                          (double.tryParse(item.quantity) ?? 1) *
                          100)
                      .round(),
            ),
          )
          .toList(),
    );
    invoices.add(invoice);
    if (total > 0) {
      final month = request.issueDate.length >= 7
          ? request.issueDate.substring(0, 7)
          : '2026-09';
      final index = turnoverRows.indexWhere((row) => row.month == month);
      if (index == -1) {
        turnoverRows.add(
          TurnoverReportRow(
            month: month,
            totalInvoices: 1,
            totalInvoiced: total,
          ),
        );
      } else {
        final current = turnoverRows[index];
        turnoverRows[index] = TurnoverReportRow(
          month: current.month,
          totalInvoices: current.totalInvoices + 1,
          totalInvoiced: current.totalInvoiced + total,
        );
      }
      dashboardData = DashboardData(
        totalClients: dashboardData.totalClients,
        activeJobs: dashboardData.activeJobs,
        completedJobs: dashboardData.completedJobs,
        pendingInvoices: dashboardData.pendingInvoices + 1,
        unpaidInvoices: dashboardData.unpaidInvoices + 1,
        outstandingInvoiceAmount:
            dashboardData.outstandingInvoiceAmount + total,
        upcomingReminders: dashboardData.upcomingReminders,
        unreadNotifications: dashboardData.unreadNotifications,
      );
    }
    return invoice;
  }

  @override
  Future<InvoicePdfFile> fetchInvoicePdf(int id) async => InvoicePdfFile(
    bytes: Uint8List.fromList('%PDF-1.4 fake'.codeUnits),
    fileName: 'invoice-$id.pdf',
  );

  @override
  Future<InvoicePdfFile> downloadInvoicePdf(int id) => fetchInvoicePdf(id);

  @override
  Future<InvoicePayment> fetchInvoicePaymentLink(int id) async =>
      invoices.firstWhere((invoice) => invoice.id == id).payment;

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
  Future<Invoice> addInvoicePayment(
    int id,
    CreateInvoicePaymentRequest request,
  ) async {
    paymentInvoiceId = id;
    lastPaymentRequest = request;
    final index = invoices.indexWhere((invoice) => invoice.id == id);
    final current = invoices[index];
    final paymentAmount = ((double.tryParse(request.amount.trim()) ?? 0) * 100)
        .round();
    final paidCandidate = current.amountPaid + paymentAmount;
    final updatedPaid = paidCandidate < 0
        ? 0
        : paidCandidate > current.totalAmount
        ? current.totalAmount
        : paidCandidate;
    final updatedBalance = current.totalAmount - updatedPaid;
    final updatedPayments = [
      ...current.payments,
      InvoicePaymentRecord(
        id: current.payments.length + 1,
        amount: paymentAmount,
        paidAt: request.paidAt,
        method: request.paymentMethod,
        reference: request.paymentReference,
        status: 'recorded',
      ),
    ];
    final updated = Invoice(
      id: current.id,
      clientId: current.clientId,
      clientName: current.clientName,
      invoiceNumber: current.invoiceNumber,
      issueDate: current.issueDate,
      dueDate: current.dueDate,
      totalAmount: current.totalAmount,
      amountPaid: updatedPaid,
      balance: updatedBalance,
      status: updatedBalance == 0 ? 'paid' : 'part_paid',
      notes: current.notes,
      projectId: current.projectId,
      projectName: current.projectName,
      pdfUrl: current.pdfUrl,
      downloadPdfUrl: current.downloadPdfUrl,
      currency: current.currency,
      payment: current.payment,
      items: current.items,
      payments: updatedPayments,
      activity: current.activity,
    );
    invoices[index] = updated;
    dashboardData = DashboardData(
      totalClients: dashboardData.totalClients,
      activeJobs: dashboardData.activeJobs,
      completedJobs: dashboardData.completedJobs,
      pendingInvoices: dashboardData.pendingInvoices,
      unpaidInvoices: invoices.where((invoice) => invoice.balance > 0).length,
      outstandingInvoiceAmount: invoices.fold<int>(
        0,
        (sum, invoice) => sum + invoice.balance,
      ),
      upcomingReminders: dashboardData.upcomingReminders,
      unreadNotifications: dashboardData.unreadNotifications,
    );
    return updated;
  }

  @override
  Future<void> deleteInvoice(int id) async {
    final invoice = await fetchInvoice(id);
    invoices.removeWhere((candidate) => candidate.id == id);
    final month = invoice.issueDate.length >= 7
        ? invoice.issueDate.substring(0, 7)
        : '2026-09';
    final index = turnoverRows.indexWhere((row) => row.month == month);
    if (index != -1) {
      final current = turnoverRows[index];
      turnoverRows[index] = TurnoverReportRow(
        month: current.month,
        totalInvoices: current.totalInvoices - 1,
        totalInvoiced: current.totalInvoiced - invoice.totalAmount,
      );
    }
  }

  @override
  Future<List<Job>> fetchJobs({String status = 'all', int? clientId}) async {
    final filtered = jobs.where((job) {
      final statusMatches =
          status == 'all' ||
          (status == 'active' &&
              job.status != 'completed' &&
              job.status != 'cancelled') ||
          job.status == status;
      final clientMatches = clientId == null || job.clientId == clientId;
      return statusMatches && clientMatches;
    });
    return filtered.toList();
  }

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
      priority: request.priority,
      type: request.type,
      deadline: request.deadline,
      estimatedValue: request.estimatedValue,
      expenseAmount: request.expenseAmount,
      expenseNotes: request.expenseNotes,
    );
    jobs.add(job);
    final month = request.startDate.length >= 7
        ? request.startDate.substring(0, 7)
        : '2026-09';
    final index = turnoverRows.indexWhere((row) => row.month == month);
    if (index == -1) {
      turnoverRows.add(
        TurnoverReportRow(month: month, totalInvoices: 0, totalInvoiced: 0),
      );
    }
    return job;
  }

  @override
  Future<Job> updateJob(int id, CreateJobRequest request) async {
    final index = jobs.indexWhere((job) => job.id == id);
    final current = jobs[index];
    final updated = Job(
      id: id,
      clientId: request.clientId,
      clientName: current.clientName,
      title: request.title,
      description: request.description,
      status: request.status,
      startDate: request.startDate,
      completionDate: request.status == 'completed'
          ? current.completionDate
          : null,
      notes: request.notes,
      priority: request.priority,
      type: request.type,
      deadline: request.deadline,
      estimatedValue: request.estimatedValue,
      expenseAmount: request.expenseAmount,
      expenseNotes: request.expenseNotes,
      recentActivity: current.recentActivity,
    );
    jobs[index] = updated;
    return updated;
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
  Future<void> deleteJob(int id) async {
    jobs.removeWhere((job) => job.id == id);
  }

  @override
  Future<Job> clearJobExpenses(int id) async {
    final index = jobs.indexWhere((job) => job.id == id);
    final current = jobs[index];
    final updated = Job(
      id: current.id,
      clientId: current.clientId,
      clientName: current.clientName,
      title: current.title,
      description: current.description,
      status: current.status,
      startDate: current.startDate,
      completionDate: current.completionDate,
      notes: current.notes,
      priority: current.priority,
      type: current.type,
      deadline: current.deadline,
      estimatedValue: current.estimatedValue,
      expenseAmount: '',
      expenseNotes: '',
      recentActivity: current.recentActivity,
    );
    jobs[index] = updated;
    return updated;
  }

  @override
  Future<List<ProjectExpense>> fetchProjectExpenses({
    int? clientId,
    int? projectId,
  }) async => projectExpenses
      .where(
        (expense) =>
            (clientId == null || expense.clientId == clientId) &&
            (projectId == null || expense.projectId == projectId),
      )
      .toList();

  @override
  Future<List<ProjectExpense>> fetchJobExpenses(int jobId) async =>
      fetchProjectExpenses(projectId: jobId);

  @override
  Future<ProjectExpense> fetchProjectExpense(int id) async =>
      projectExpenses.firstWhere((expense) => expense.id == id);

  @override
  Future<ProjectExpense> createJobExpense(
    int jobId,
    CreateProjectExpenseRequest request,
  ) async {
    lastProjectExpenseRequest = request;
    final job = await fetchJob(jobId);
    final expense = ProjectExpense(
      id: projectExpenses.length + 1,
      clientId: job.clientId,
      clientName: job.clientName,
      projectId: job.id,
      projectName: job.title,
      expenseDate: request.expenseDate,
      description: request.description,
      amount: (double.tryParse(request.amount) ?? 0) * 100 ~/ 1,
    );
    projectExpenses.add(expense);
    return expense;
  }

  @override
  Future<ProjectExpense> updateProjectExpense(
    int id,
    CreateProjectExpenseRequest request,
  ) async {
    lastProjectExpenseRequest = request;
    final index = projectExpenses.indexWhere((expense) => expense.id == id);
    final current = projectExpenses[index];
    final updated = ProjectExpense(
      id: current.id,
      clientId: current.clientId,
      clientName: current.clientName,
      projectId: current.projectId,
      projectName: current.projectName,
      expenseDate: request.expenseDate,
      description: request.description,
      amount: (double.tryParse(request.amount) ?? 0) * 100 ~/ 1,
      currency: current.currency,
    );
    projectExpenses[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteProjectExpense(int id) async {
    deletedProjectExpenseId = id;
    projectExpenses.removeWhere((expense) => expense.id == id);
  }

  @override
  Future<List<Quote>> fetchQuotes({int? clientId}) async => clientId == null
      ? List.of(quotes)
      : quotes.where((quote) => quote.clientId == clientId).toList();

  @override
  Future<Quote> fetchQuote(int id) async =>
      quotes.firstWhere((quote) => quote.id == id);

  @override
  Future<Quote> createQuote(CreateQuoteRequest request) async {
    lastQuoteRequest = request;
    final total = request.items.fold<int>(0, (sum, item) {
      final amount = (num.tryParse(item.unitAmount) ?? 0) * 100;
      final quantity = num.tryParse(item.quantity) ?? 1;
      return sum + (amount * quantity).round();
    });
    final quote = Quote(
      id: quotes.length + 1,
      clientId: request.clientId,
      clientName: clients
          .firstWhere((client) => client.id == request.clientId)
          .name,
      quoteReference: 'QUOTE-${(quotes.length + 1).toString().padLeft(6, '0')}',
      quoteDate: request.quoteDate,
      subtotalAmount: total,
      totalAmount: total,
      status: request.status,
      notes: request.notes,
      shareUrl: 'https://example.test/quotes/${quotes.length + 1}/public',
      items: request.items
          .map((item) {
            final unitAmount = ((num.tryParse(item.unitAmount) ?? 0) * 100)
                .round();
            final quantity = num.tryParse(item.quantity)?.toDouble() ?? 1;
            return QuoteItem(
              description: item.description,
              quantity: quantity,
              unitAmount: unitAmount,
              lineTotal: (unitAmount * quantity).round(),
            );
          })
          .toList(growable: false),
    );
    quotes.add(quote);
    return quote;
  }

  @override
  Future<Quote> updateQuote(int id, CreateQuoteRequest request) async {
    lastQuoteRequest = request;
    final index = quotes.indexWhere((quote) => quote.id == id);
    final current = quotes[index];
    final updated = Quote(
      id: current.id,
      clientId: current.clientId,
      clientName: current.clientName,
      quoteReference: current.quoteReference,
      quoteDate: request.quoteDate,
      totalAmount: ((num.tryParse(request.items.first.unitAmount) ?? 0) * 100)
          .round(),
      status: request.status,
      notes: request.notes,
      shareUrl: current.shareUrl,
      items: [
        QuoteItem(
          description: request.items.first.description,
          quantity: 1,
          unitAmount:
              ((num.tryParse(request.items.first.unitAmount) ?? 0) * 100)
                  .round(),
          lineTotal: ((num.tryParse(request.items.first.unitAmount) ?? 0) * 100)
              .round(),
        ),
      ],
    );
    quotes[index] = updated;
    return updated;
  }

  @override
  Future<QuotePdfFile> fetchQuotePdf(int id) async => QuotePdfFile(
    bytes: Uint8List.fromList([37, 80, 68, 70]),
    fileName: 'QUOTE-000001.pdf',
  );

  @override
  Future<QuotePdfFile> downloadQuotePdf(int id) => fetchQuotePdf(id);

  @override
  Future<void> deleteQuote(int id) async {
    deletedQuoteId = id;
    quotes.removeWhere((quote) => quote.id == id);
  }

  @override
  Future<List<TurnoverReportRow>> fetchTurnoverReport() async =>
      List.of(turnoverRows);

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
  Future<void> deleteDocument(int id) async {
    documents.removeWhere((document) => document.id == id);
  }

  @override
  Future<List<CrmNotification>> fetchNotifications() async =>
      List.of(notifications);

  @override
  Future<void> markNotificationRead(String id) async {}
}

CommercialSession commercialSessionFixture({
  CommercialRole role = CommercialRole.owner,
  String tenantStatus = 'active',
  bool membershipActive = true,
  String userDisplayName = 'Daphnex User',
  String companyName = 'Northstar Studio',
  String brandingInitials = 'NS',
}) => CommercialSession(
  user: CurrentUser(
    id: 7,
    displayName: userDisplayName,
    email: 'owner@example.test',
  ),
  tenant: TenantWorkspace(
    id: 12,
    companyName: companyName,
    slug: 'northstar-studio',
    status: tenantStatus,
    currency: 'GBP',
    timezone: 'Europe/London',
  ),
  membership: TenantMembership(
    role: role,
    roleLabel: role.name,
    status: membershipActive ? 'active' : 'inactive',
    active: membershipActive,
  ),
  entitlements: EntitlementSummary(
    plan: const PlanSummary(
      key: 'pilot',
      label: 'Pilot',
      description: 'Pilot workspace',
      internalOnly: true,
    ),
    status: 'active',
    features: const {
      'team_management': FeatureEntitlement(
        key: 'team_management',
        allowed: true,
        reason: '',
        message: 'Team management is available for this workspace.',
        label: 'Team management',
      ),
      'advanced_branding': FeatureEntitlement(
        key: 'advanced_branding',
        allowed: false,
        reason: 'feature_not_in_plan',
        message: 'Advanced branding requires a future plan upgrade.',
        label: 'Advanced branding',
      ),
    },
    usage: const {
      'team_members': UsageLimit(
        key: 'team_members',
        usage: 2,
        limit: 5,
        label: 'Team members',
      ),
      'documents': UsageLimit(
        key: 'documents',
        usage: 1,
        limit: 50,
        label: 'Documents',
      ),
    },
    upgradeRequired: false,
  ),
  companyProfile: CompanyProfile(
    companyName: companyName,
    tradingName: 'Northstar',
    email: 'hello@example.test',
    phone: '07700 900111',
  ),
  branding: BrandingSummary(
    displayName: companyName,
    initials: brandingInitials,
    accentColor: '#147DE8',
  ),
);
