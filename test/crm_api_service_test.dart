import 'dart:convert';

import 'package:daphnex_crm_mobile/core/errors/api_exception.dart';
import 'package:daphnex_crm_mobile/core/storage/token_store.dart';
import 'package:daphnex_crm_mobile/models/client.dart';
import 'package:daphnex_crm_mobile/models/commercial_session.dart';
import 'package:daphnex_crm_mobile/models/crm_task.dart';
import 'package:daphnex_crm_mobile/models/invoice.dart';
import 'package:daphnex_crm_mobile/models/job.dart';
import 'package:daphnex_crm_mobile/models/project_expense.dart';
import 'package:daphnex_crm_mobile/models/reminder.dart';
import 'package:daphnex_crm_mobile/services/crm_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemoryTokenStore implements TokenStore {
  String? token;

  @override
  Future<void> deleteToken() async => token = null;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async => token = value;
}

void main() {
  test(
    'login stores token and authenticated request sends Bearer header',
    () async {
      final store = MemoryTokenStore();
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/login')) {
          expect(jsonDecode(request.body)['email'], 'admin@example.test');
          return http.Response(
            jsonEncode({
              'token': 'secure-test-token',
              'session': _sessionJson(role: 'owner'),
            }),
            200,
          );
        }
        expect(request.headers['Authorization'], 'Bearer secure-test-token');
        return http.Response(
          jsonEncode({
            'total_clients': 7,
            'active_jobs': 2,
            'pending_invoices': 1,
            'upcoming_reminders': 3,
          }),
          200,
        );
      });
      final service = CrmApiService(client: client, tokenStore: store);
      await service.login(email: 'admin@example.test', password: 'secret');
      final dashboard = await service.fetchDashboard();
      expect(store.token, 'secure-test-token');
      expect(service.currentSession?.membership.role, CommercialRole.owner);
      expect(dashboard.totalClients, 7);
    },
  );

  test('API error message is exposed and 401 clears stored token', () async {
    final store = MemoryTokenStore()..token = 'expired';
    final service = CrmApiService(
      tokenStore: store,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'The authentication token is invalid or expired.',
          }),
          401,
        ),
      ),
    );
    await expectLater(
      service.fetchClients(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('Authentication failed'),
        ),
      ),
    );
    expect(store.token, isNull);
  });

  test(
    'stored token is revalidated through commercial session endpoint',
    () async {
      final store = MemoryTokenStore()..token = 'stored-token';
      final service = CrmApiService(
        tokenStore: store,
        client: MockClient((request) async {
          expect(request.url.path, '/wp-json/daphnex-crm/v1/session');
          expect(request.headers['Authorization'], 'Bearer stored-token');
          return http.Response(jsonEncode(_sessionJson(role: 'admin')), 200);
        }),
      );

      expect(await service.hasSession(), isTrue);
      expect(service.currentSession?.membership.role, CommercialRole.admin);
    },
  );

  test('access removed clears stored token and notifies listener', () async {
    final store = MemoryTokenStore()..token = 'removed-token';
    ApiException? invalidation;
    final service = CrmApiService(
      tokenStore: store,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'daphnex_tenant_membership_required',
            'message': 'No active tenant membership was found.',
          }),
          403,
        ),
      ),
    )..onSessionInvalidated = (error) => invalidation = error;

    await expectLater(service.fetchDashboard(), throwsA(isA<ApiException>()));
    expect(store.token, isNull);
    expect(service.currentSession, isNull);
    expect(invalidation?.category, ApiErrorCategory.accessRemoved);
  });

  test(
    'Phase 3B service methods call live API routes with Bearer token',
    () async {
      final seenPaths = <String>[];
      final seenQueries = <String>[];
      final store = MemoryTokenStore()..token = 'phase3-token';
      final service = CrmApiService(
        tokenStore: store,
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer phase3-token');
          seenPaths.add(request.url.path);
          seenQueries.add(request.url.query);
          if (request.url.path.endsWith('/invoices')) {
            if (request.method == 'POST') {
              return http.Response(jsonEncode(_invoiceJson()), 201);
            }
            return http.Response(
              jsonEncode({
                'items': [_invoiceJson()],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/invoices/1')) {
            return http.Response(jsonEncode(_invoiceJson()), 200);
          }
          if (request.url.path.endsWith('/invoices/1/pdf')) {
            expect(request.headers['Accept'], 'application/pdf');
            return http.Response.bytes(
              utf8.encode('%PDF-1.4 test'),
              200,
              headers: {
                'content-type': 'application/pdf',
                'content-disposition': 'inline; filename="INV-1.pdf"',
              },
            );
          }
          if (request.url.path.endsWith('/invoices/1/download-pdf')) {
            expect(request.headers['Accept'], 'application/pdf');
            return http.Response.bytes(
              utf8.encode('%PDF-1.4 test'),
              200,
              headers: {
                'content-type': 'application/pdf',
                'content-disposition': 'attachment; filename="INV-1.pdf"',
              },
            );
          }
          if (request.url.path.endsWith('/invoices/1/payment-link')) {
            return http.Response(jsonEncode(_paymentJson()), 200);
          }
          if (request.url.path.endsWith('/invoices/1/mark-paid') ||
              request.url.path.endsWith('/invoices/1/mark-unpaid') ||
              request.url.path.endsWith('/invoices/1/payments')) {
            return http.Response(jsonEncode(_invoiceJson()), 200);
          }
          if (request.url.path.endsWith('/invoices/1') &&
              request.method == 'DELETE') {
            return http.Response(jsonEncode({'deleted': true}), 200);
          }
          if (request.url.path.endsWith('/clients')) {
            if (request.method == 'POST') {
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              expect(body['first_name'], 'Priya');
              return http.Response(jsonEncode(_clientJson(id: 3)), 201);
            }
            return http.Response(
              jsonEncode({
                'items': [_clientJson()],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/clients/1')) {
            if (request.method == 'DELETE') {
              return http.Response(jsonEncode({'deleted': true}), 200);
            }
            if (request.method == 'POST') {
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              expect(body['company_name'], 'Northstar Updated');
              return http.Response(jsonEncode(_clientJson()), 200);
            }
            return http.Response(jsonEncode(_clientJson()), 200);
          }
          if (request.url.path.endsWith('/jobs')) {
            if (request.method == 'POST') {
              return http.Response(jsonEncode(_jobJson()), 201);
            }
            return http.Response(
              jsonEncode({
                'items': [_jobJson()],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/jobs/1') ||
              request.url.path.endsWith('/jobs/1/complete') ||
              request.url.path.endsWith('/jobs/1/reopen') ||
              request.url.path.endsWith('/jobs/1/notes')) {
            if (request.method == 'DELETE') {
              return http.Response(jsonEncode({'deleted': true}), 200);
            }
            return http.Response(jsonEncode(_jobJson()), 200);
          }
          if (request.url.path.endsWith('/jobs/1/expenses')) {
            if (request.method == 'POST') {
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              expect(body['description'], 'Materials purchased');
              return http.Response(jsonEncode(_projectExpenseJson()), 201);
            }
            if (request.method == 'DELETE') {
              return http.Response(jsonEncode(_jobJson()), 200);
            }
            return http.Response(
              jsonEncode({
                'items': [_projectExpenseJson()],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/expenses')) {
            return http.Response(
              jsonEncode({
                'items': [_projectExpenseJson()],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/expenses/1')) {
            if (request.method == 'DELETE') {
              return http.Response(jsonEncode({'deleted': true}), 200);
            }
            return http.Response(jsonEncode(_projectExpenseJson()), 200);
          }
          if (request.url.path.endsWith('/reports/turnover')) {
            return http.Response(
              jsonEncode({
                'monthly_breakdown': [_turnoverJson()],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/tasks')) {
            if (request.method == 'POST') {
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              expect(body.containsKey('assigned_user_id'), isFalse);
              return http.Response(jsonEncode(_taskJson()), 201);
            }
            return http.Response(
              jsonEncode({
                'items': [_taskJson()],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/tasks/1')) {
            if (request.method == 'DELETE') {
              return http.Response(jsonEncode({'deleted': true}), 200);
            }
            return http.Response(jsonEncode(_taskJson()), 200);
          }
          if (request.url.path.endsWith('/reminders/1')) {
            if (request.method == 'DELETE') {
              return http.Response(jsonEncode({'deleted': true}), 200);
            }
            return http.Response(jsonEncode(_reminderJson()), 200);
          }
          if (request.url.path.endsWith('/documents')) {
            return http.Response(
              jsonEncode({
                'items': [_documentJson()],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/clients/1/documents')) {
            return http.Response(
              jsonEncode({
                'items': [_documentJson()],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/documents/1/download')) {
            return http.Response(
              jsonEncode({
                'file_name': 'agreement.pdf',
                'mime_type': 'application/pdf',
                'file_size': 10,
                'download_url': 'https://example.test/agreement.pdf',
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/documents/1') &&
              request.method == 'DELETE') {
            return http.Response(jsonEncode({'deleted': true}), 200);
          }
          if (request.url.path.endsWith('/notifications')) {
            return http.Response(
              jsonEncode({
                'items': [_notificationJson()],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/notifications/reminder:1/read')) {
            return http.Response(jsonEncode({'read': true}), 200);
          }
          return http.Response('{}', 404);
        }),
      );

      expect(await service.fetchClients(), hasLength(1));
      final fetchedClient = await service.fetchClient(1);
      expect(fetchedClient.name, 'Olivia Bennett');
      expect(fetchedClient.addressLine1, '10 Pilot Street');
      expect(fetchedClient.city, 'London');
      expect(fetchedClient.countyState, 'Greater London');
      expect(fetchedClient.postcode, 'P01 0AA');
      expect(fetchedClient.country, 'United Kingdom');
      await service.createClient(
        const CreateClientRequest(
          firstName: 'Priya',
          lastName: 'Shah',
          companyName: 'Blue Finch',
        ),
      );
      await service.updateClient(
        1,
        const CreateClientRequest(
          firstName: 'Olivia',
          lastName: 'Bennett',
          companyName: 'Northstar Updated',
        ),
      );
      await service.deleteClient(1);
      expect(await service.fetchInvoices(clientId: 1), hasLength(1));
      expect((await service.fetchInvoice(1)).invoiceNumber, 'INV-1');
      expect((await service.fetchInvoicePdf(1)).fileName, 'INV-1.pdf');
      expect((await service.downloadInvoicePdf(1)).bytes, isNotEmpty);
      expect(
        (await service.fetchInvoicePaymentLink(1)).paymentUrl,
        'https://example.test/pay',
      );
      await service.createInvoice(
        const CreateInvoiceRequest(
          clientId: 1,
          items: [
            CreateInvoiceItemRequest(
              description: 'Line',
              quantity: '1',
              unitAmount: '10.00',
            ),
          ],
        ),
      );
      await service.markInvoicePaid(1);
      await service.markInvoiceUnpaid(1);
      await service.addInvoicePayment(
        1,
        const CreateInvoicePaymentRequest(
          amount: '50.00',
          paidAt: '2026-06-25',
          paymentMethod: 'bank_transfer',
          paymentReference: 'TEST-1',
        ),
      );
      await service.deleteInvoice(1);
      expect(await service.fetchJobs(clientId: 1), hasLength(1));
      await service.fetchJob(1);
      await service.createJob(
        const CreateJobRequest(clientId: 1, title: 'Job'),
      );
      await service.updateJob(
        1,
        const CreateJobRequest(clientId: 1, title: 'Updated Job'),
      );
      expect(await service.fetchProjectExpenses(projectId: 1), hasLength(1));
      expect(await service.fetchJobExpenses(1), hasLength(1));
      expect((await service.fetchProjectExpense(1)).description, 'Materials');
      await service.createJobExpense(
        1,
        const CreateProjectExpenseRequest(
          expenseDate: '2026-09-10',
          description: 'Materials purchased',
          amount: '120.00',
        ),
      );
      await service.updateProjectExpense(
        1,
        const CreateProjectExpenseRequest(
          expenseDate: '2026-09-11',
          description: 'Materials updated',
          amount: '130.00',
        ),
      );
      await service.deleteProjectExpense(1);
      await service.clearJobExpenses(1);
      expect((await service.fetchTurnoverReport()).single.totalInvoiced, 94000);
      expect(await service.fetchTasks(clientId: 1), hasLength(1));
      await service.fetchTask(1);
      await service.createTask(
        const CreateTaskRequest(clientId: 1, title: 'Task'),
      );
      await service.updateTask(
        1,
        const CreateTaskRequest(clientId: 1, title: 'Updated Task'),
      );
      await service.deleteTask(1);
      expect(seenPaths, contains('/wp-json/daphnex-crm/v1/tasks'));
      expect(seenQueries, contains(contains('client_id=1')));
      await service.completeJob(1);
      await service.reopenJob(1);
      await service.addJobNotes(1, 'Notes');
      await service.deleteJob(1);
      expect(await service.fetchDocuments(), hasLength(1));
      expect(await service.fetchClientDocuments(1), hasLength(1));
      expect(
        (await service.fetchDocumentDownload(1)).fileName,
        'agreement.pdf',
      );
      await service.deleteDocument(1);
      expect(await service.fetchNotifications(), hasLength(1));
      await service.markNotificationRead('reminder:1');
      await service.updateReminder(
        1,
        const CreateReminderRequest(
          clientId: 1,
          title: 'Reminder',
          date: '2026-06-26',
        ),
      );
      await service.deleteReminder(1);
      expect(seenPaths, contains('/wp-json/daphnex-crm/v1/jobs/1/notes'));
      expect(seenPaths, contains('/wp-json/daphnex-crm/v1/clients/1'));
      expect(
        seenPaths,
        contains('/wp-json/daphnex-crm/v1/invoices/1/payments'),
      );
      expect(seenPaths, contains('/wp-json/daphnex-crm/v1/jobs/1/expenses'));
      expect(seenPaths, contains('/wp-json/daphnex-crm/v1/expenses'));
      expect(seenPaths, contains('/wp-json/daphnex-crm/v1/expenses/1'));
      expect(seenPaths, contains('/wp-json/daphnex-crm/v1/reports/turnover'));
      expect(seenPaths, contains('/wp-json/daphnex-crm/v1/documents/1'));
    },
  );

  test(
    'client-scoped workspace collections discard mismatched response records',
    () async {
      final store = MemoryTokenStore()..token = 'scope-token';
      final seenQueries = <String>[];
      final service = CrmApiService(
        tokenStore: store,
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer scope-token');
          seenQueries.add(request.url.query);
          if (request.url.path.endsWith('/invoices')) {
            return http.Response(
              jsonEncode({
                'items': [
                  _invoiceJson(id: 1, clientId: 1),
                  _invoiceJson(id: 2, clientId: 2),
                ],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/jobs')) {
            return http.Response(
              jsonEncode({
                'items': [
                  _jobJson(id: 1, clientId: 1),
                  _jobJson(id: 2, clientId: 2),
                ],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/tasks')) {
            return http.Response(
              jsonEncode({
                'items': [
                  _taskJson(id: 1, clientId: 1),
                  _taskJson(id: 2, clientId: 2),
                ],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/reminders')) {
            return http.Response(
              jsonEncode({
                'items': [
                  _reminderJson(id: 1, clientId: 1),
                  _reminderJson(id: 2, clientId: 2),
                ],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/expenses')) {
            return http.Response(
              jsonEncode({
                'items': [
                  _projectExpenseJson(id: 1, clientId: 1),
                  _projectExpenseJson(id: 2, clientId: 2),
                ],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/clients/1/documents')) {
            return http.Response(
              jsonEncode({
                'items': [
                  _documentJson(id: 1, clientId: 1),
                  _documentJson(id: 2, clientId: 2),
                ],
              }),
              200,
            );
          }
          return http.Response('{}', 404);
        }),
      );

      expect(
        (await service.fetchInvoices(clientId: 1)).map((item) => item.clientId),
        [1],
      );
      expect(
        (await service.fetchJobs(clientId: 1)).map((item) => item.clientId),
        [1],
      );
      expect(
        (await service.fetchTasks(clientId: 1)).map((item) => item.clientId),
        [1],
      );
      expect(
        (await service.fetchReminders(
          clientId: 1,
        )).map((item) => item.clientId),
        [1],
      );
      expect(
        (await service.fetchProjectExpenses(
          clientId: 1,
        )).map((item) => item.clientId),
        [1],
      );
      expect(
        (await service.fetchClientDocuments(1)).map((item) => item.clientId),
        [1],
      );
      expect(
        seenQueries.where((query) => query.contains('client_id=1')),
        hasLength(5),
      );
    },
  );

  test('task writes include backend task aliases and preserve client id', () {
    final body = const CreateTaskRequest(
      clientId: 7,
      title: 'Call supplier',
      description: 'Confirm delivery slot.',
      dueDate: '2026-09-14',
    ).toJson();

    expect(body['client_id'], 7);
    expect(body['title'], 'Call supplier');
    expect(body['task_title'], 'Call supplier');
    expect(body['description'], 'Confirm delivery slot.');
    expect(body['task_description'], 'Confirm delivery slot.');
  });

  test(
    'quotes use client scoped endpoints and are filtered defensively',
    () async {
      final seen = <String>[];
      final store = MemoryTokenStore()..token = 'token';
      final service = CrmApiService(
        tokenStore: store,
        client: MockClient((request) async {
          seen.add(request.url.toString());
          if (request.url.path.endsWith('/quotes')) {
            return http.Response(
              jsonEncode({
                'items': [
                  _quoteJson(id: 1, clientId: 1),
                  _quoteJson(id: 2, clientId: 2),
                ],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/quotes/1')) {
            return http.Response(
              jsonEncode(_quoteJson(id: 1, clientId: 1)),
              200,
            );
          }
          if (request.url.path.endsWith('/quotes/1/pdf') ||
              request.url.path.endsWith('/quotes/1/download-pdf')) {
            return http.Response(
              '%PDF',
              200,
              headers: {'content-type': 'application/pdf'},
            );
          }
          return http.Response('{}', 200);
        }),
      );

      final quotes = await service.fetchQuotes(clientId: 1);
      expect(quotes.map((quote) => quote.clientId), [1]);
      expect(seen.single, contains('client_id=1'));

      expect((await service.fetchQuote(1)).quoteReference, 'QUOTE-000001');
      expect((await service.fetchQuotePdf(1)).fileName, 'quote-1.pdf');
      expect((await service.downloadQuotePdf(1)).bytes, isNotEmpty);
    },
  );
}

Map<String, dynamic> _clientJson({int id = 1}) => {
  'id': id,
  'name': id == 1 ? 'Olivia Bennett' : 'Priya Shah',
  'first_name': id == 1 ? 'Olivia' : 'Priya',
  'last_name': id == 1 ? 'Bennett' : 'Shah',
  'email': 'client@example.test',
  'phone': '07700 900123',
  'company': id == 1 ? 'Northstar Studio' : 'Blue Finch',
  'notes': '',
  'website': '',
  'address': {
    'line_1': '10 Pilot Street',
    'line_2': 'Suite 2',
    'city': 'London',
    'county_state': 'Greater London',
    'postcode': 'P01 0AA',
    'country': 'United Kingdom',
  },
  'activity': [],
};

Map<String, dynamic> _invoiceJson({int id = 1, int clientId = 1}) => {
  'id': id,
  'client_id': clientId,
  'client_name': clientId == 1 ? 'Northstar Studio' : 'Blue Finch',
  'project_id': clientId,
  'project_name': 'Website maintenance',
  'invoice_number': 'INV-1',
  'issue_date': '2026-06-24',
  'due_date': '2026-07-01',
  'total_amount': 1000,
  'amount_paid': 0,
  'balance': 1000,
  'status': 'sent',
  'notes': '',
  'pdf_url': 'https://example.test/invoices/1/pdf',
  'download_pdf_url': 'https://example.test/invoices/1/download-pdf',
  'payment': _paymentJson(),
  'payment_history': [
    {
      'id': 1,
      'amount': 5000,
      'paid_at': '2026-06-25',
      'payment_method': 'bank_transfer',
      'payment_reference': 'TEST-1',
      'status': 'recorded',
    },
  ],
};

Map<String, dynamic> _quoteJson({int id = 1, int clientId = 1}) => {
  'id': id,
  'client_id': clientId,
  'client_name': clientId == 1 ? 'Northstar Studio' : 'Blue Finch',
  'quote_reference': 'QUOTE-${id.toString().padLeft(6, '0')}',
  'quote_date': '2026-09-15',
  'subtotal_amount': 1000,
  'total_amount': 1000,
  'status': 'sent',
  'notes': '',
  'pdf_url': 'https://example.test/quotes/$id/pdf',
  'download_pdf_url': 'https://example.test/quotes/$id/download-pdf',
  'share_url': 'https://example.test/quotes/$id/public',
  'items': [
    {
      'description': 'Discovery',
      'quantity': 1,
      'unit_amount': 1000,
      'line_total': 1000,
    },
  ],
};

Map<String, dynamic> _paymentJson() => {
  'configured': true,
  'payment_url': 'https://example.test/pay',
  'public_invoice_url': 'https://example.test/invoices/1/public',
  'amount_due': 1000,
  'currency': 'GBP',
  'requires_bearer': false,
};

Map<String, dynamic> _jobJson({int id = 1, int clientId = 1}) => {
  'id': id,
  'client_id': clientId,
  'client_name': clientId == 1 ? 'Northstar Studio' : 'Blue Finch',
  'title': 'Job',
  'description': 'Description',
  'status': 'in_progress',
  'start_date': '2026-06-24',
  'completion_date': null,
  'project_notes': '',
  'recent_activity': [],
};

Map<String, dynamic> _projectExpenseJson({int id = 1, int clientId = 1}) => {
  'id': id,
  'client_id': clientId,
  'client_name': clientId == 1 ? 'Northstar Studio' : 'Blue Finch',
  'project_id': clientId,
  'project_name': 'Website maintenance',
  'expense_date': '2026-09-10',
  'description': 'Materials',
  'amount': 12000,
  'currency': 'GBP',
};

Map<String, dynamic> _turnoverJson() => {
  'month': '2026-09',
  'invoice_count': 2,
  'total_invoiced': 94000,
};

Map<String, dynamic> _documentJson({int id = 1, int clientId = 1}) => {
  'id': id,
  'client_id': clientId,
  'client_name': clientId == 1 ? 'Northstar Studio' : 'Blue Finch',
  'project_id': 0,
  'project_name': '',
  'type': 'agreement',
  'title': 'Signed Agreement',
  'description': '',
  'file_name': 'agreement.pdf',
  'file_size': 10,
  'mime_type': 'application/pdf',
  'status': 'active',
  'download_url': 'https://example.test/download',
  'created_at': '2026-06-24T10:00:00Z',
};

Map<String, dynamic> _taskJson({int id = 1, int clientId = 1}) => {
  'id': id,
  'client_id': clientId,
  'client_name': clientId == 1 ? 'Northstar Studio' : 'Blue Finch',
  'project_id': clientId,
  'project_name': 'Website maintenance',
  'title': 'Prepare homepage copy',
  'assigned_user_id': 0,
  'assigned_to': '',
  'due_date': '2026-07-02',
  'priority': 'medium',
  'status': 'pending',
  'description': 'Draft client-ready copy.',
  'internal_notes': '',
};

Map<String, dynamic> _reminderJson({int id = 1, int clientId = 1}) => {
  'id': id,
  'client_id': clientId,
  'client_name': clientId == 1 ? 'Northstar Studio' : 'Blue Finch',
  'project_id': clientId,
  'project_name': 'Website maintenance',
  'title': 'Reminder',
  'date': '2026-06-26',
  'time': '09:00',
  'priority': 'medium',
  'status': 'pending',
  'description': '',
};

Map<String, dynamic> _notificationJson() => {
  'id': 'reminder:1',
  'type': 'upcoming_reminder',
  'title': 'Follow up',
  'message': 'Upcoming CRM reminder.',
  'read': false,
  'created_at': '2026-06-24T10:00:00Z',
  'related': {'client_id': 1},
};

Map<String, dynamic> _sessionJson({String role = 'owner'}) => {
  'user': {
    'id': 7,
    'display_name': 'Daphnex User',
    'email': 'owner@example.test',
  },
  'tenant': {
    'id': 12,
    'company_name': 'Northstar Studio',
    'slug': 'northstar-studio',
    'status': 'active',
    'currency': 'GBP',
    'timezone': 'Europe/London',
  },
  'membership': {
    'role': role,
    'role_label': role,
    'status': 'active',
    'active': true,
  },
  'company_profile': {
    'company_name': 'Northstar Studio',
    'trading_name': 'Northstar',
    'email': 'hello@example.test',
    'phone': '07700 900111',
    'currency': 'GBP',
    'can_edit': true,
  },
  'branding': {
    'display_name': 'Northstar Studio',
    'logo_url': '',
    'initials': 'NS',
    'accent_color': '#147DE8',
    'can_edit': true,
  },
  'entitlements': {
    'plan': {
      'key': 'pilot',
      'label': 'Pilot',
      'description': 'Pilot workspace',
      'internal_only': true,
    },
    'status': 'active',
    'features': {
      'clients': {
        'allowed': true,
        'reason': 'allowed',
        'message': '',
        'label': 'Clients',
      },
    },
    'limits': {'clients': 100},
    'usage': {
      'clients': {'usage': 3, 'limit': 100, 'label': 'Clients'},
    },
    'upgrade_required': false,
    'placeholder_notice': 'Development placeholder',
  },
};
