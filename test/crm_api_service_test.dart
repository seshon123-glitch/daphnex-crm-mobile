import 'dart:convert';

import 'package:daphnex_crm_mobile/core/errors/api_exception.dart';
import 'package:daphnex_crm_mobile/core/storage/token_store.dart';
import 'package:daphnex_crm_mobile/models/invoice.dart';
import 'package:daphnex_crm_mobile/models/job.dart';
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
          return http.Response(jsonEncode({'token': 'secure-test-token'}), 200);
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
    'Phase 3B service methods call live API routes with Bearer token',
    () async {
      final seenPaths = <String>[];
      final store = MemoryTokenStore()..token = 'phase3-token';
      final service = CrmApiService(
        tokenStore: store,
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer phase3-token');
          seenPaths.add(request.url.path);
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
              request.url.path.endsWith('/invoices/1/mark-unpaid')) {
            return http.Response(jsonEncode(_invoiceJson()), 200);
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
            return http.Response(jsonEncode(_jobJson()), 200);
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

      expect(await service.fetchInvoices(), hasLength(1));
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
          description: 'Line',
          unitAmount: '10.00',
        ),
      );
      await service.markInvoicePaid(1);
      await service.markInvoiceUnpaid(1);
      expect(await service.fetchJobs(), hasLength(1));
      await service.fetchJob(1);
      await service.createJob(
        const CreateJobRequest(clientId: 1, title: 'Job'),
      );
      await service.completeJob(1);
      await service.reopenJob(1);
      await service.addJobNotes(1, 'Notes');
      expect(await service.fetchDocuments(), hasLength(1));
      expect(await service.fetchClientDocuments(1), hasLength(1));
      expect(
        (await service.fetchDocumentDownload(1)).fileName,
        'agreement.pdf',
      );
      expect(await service.fetchNotifications(), hasLength(1));
      await service.markNotificationRead('reminder:1');
      expect(seenPaths, contains('/wp-json/daphnex-crm/v1/jobs/1/notes'));
    },
  );
}

Map<String, dynamic> _invoiceJson() => {
  'id': 1,
  'client_id': 1,
  'client_name': 'Northstar Studio',
  'project_id': 1,
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
};

Map<String, dynamic> _paymentJson() => {
  'configured': true,
  'payment_url': 'https://example.test/pay',
  'public_invoice_url': 'https://example.test/invoices/1/public',
  'amount_due': 1000,
  'currency': 'GBP',
  'requires_bearer': false,
};

Map<String, dynamic> _jobJson() => {
  'id': 1,
  'client_id': 1,
  'client_name': 'Northstar Studio',
  'title': 'Job',
  'description': 'Description',
  'status': 'in_progress',
  'start_date': '2026-06-24',
  'completion_date': null,
  'project_notes': '',
  'recent_activity': [],
};

Map<String, dynamic> _documentJson() => {
  'id': 1,
  'client_id': 1,
  'client_name': 'Northstar Studio',
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

Map<String, dynamic> _notificationJson() => {
  'id': 'reminder:1',
  'type': 'upcoming_reminder',
  'title': 'Follow up',
  'message': 'Upcoming CRM reminder.',
  'read': false,
  'created_at': '2026-06-24T10:00:00Z',
  'related': {'client_id': 1},
};
