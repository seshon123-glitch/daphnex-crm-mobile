import 'dart:convert';

import 'package:daphnex_crm_mobile/core/errors/api_exception.dart';
import 'package:daphnex_crm_mobile/core/storage/token_store.dart';
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
          contains('expired'),
        ),
      ),
    );
    expect(store.token, isNull);
  });
}
