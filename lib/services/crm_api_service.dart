import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/errors/api_exception.dart';
import '../core/storage/token_store.dart';
import '../models/client.dart';
import '../models/crm_document.dart';
import '../models/crm_notification.dart';
import '../models/dashboard_data.dart';
import '../models/invoice.dart';
import '../models/job.dart';
import '../models/reminder.dart';

class CrmApiService {
  CrmApiService({http.Client? client, TokenStore? tokenStore})
    : _client = client ?? http.Client(),
      _tokenStore = tokenStore ?? const SecureTokenStore();

  static const _timeout = Duration(seconds: 15);
  final http.Client _client;
  final TokenStore _tokenStore;

  Future<bool> hasSession() async {
    final token = await _tokenStore.readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> login({required String email, required String password}) async {
    final endpoint = ApiConfig.endpoint('login');
    final response = await _send(
      endpoint,
      () => _client.post(
        endpoint,
        headers: _jsonHeaders,
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ),
      authenticated: false,
      loginRequest: true,
    );
    final data = _decodeObject(response);
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const ApiException('The CRM returned an invalid login response.');
    }
    await _tokenStore.writeToken(token);
  }

  Future<void> logout() => _tokenStore.deleteToken();

  Future<DashboardData> fetchDashboard() async {
    final response = await _authenticatedGet('dashboard');
    return DashboardData.fromJson(_decodeObject(response));
  }

  Future<List<Client>> fetchClients() async {
    final response = await _authenticatedGet('clients?per_page=100');
    return _decodeItems(response).map(Client.fromJson).toList(growable: false);
  }

  Future<Client> fetchClient(int id) async {
    final response = await _authenticatedGet('clients/$id');
    return Client.fromJson(_decodeObject(response));
  }

  Future<List<Reminder>> fetchReminders() async {
    final response = await _authenticatedGet('reminders?per_page=100');
    return _decodeItems(
      response,
    ).map(Reminder.fromJson).toList(growable: false);
  }

  Future<Reminder> createReminder(CreateReminderRequest request) async {
    final response = await _authenticatedPost('reminders', request.toJson());
    return Reminder.fromJson(_decodeObject(response));
  }

  Future<Reminder> completeReminder(int id) async {
    final response = await _authenticatedPost(
      'reminders/$id/complete',
      const {},
    );
    return Reminder.fromJson(_decodeObject(response));
  }

  Future<List<Invoice>> fetchInvoices() async {
    final response = await _authenticatedGet('invoices?per_page=100');
    return _decodeItems(response).map(Invoice.fromJson).toList(growable: false);
  }

  Future<Invoice> fetchInvoice(int id) async {
    final response = await _authenticatedGet('invoices/$id');
    return Invoice.fromJson(_decodeObject(response));
  }

  Future<Invoice> createInvoice(CreateInvoiceRequest request) async {
    final response = await _authenticatedPost('invoices', request.toJson());
    return Invoice.fromJson(_decodeObject(response));
  }

  Future<Invoice> markInvoicePaid(int id) async {
    final response = await _authenticatedPost(
      'invoices/$id/mark-paid',
      const {},
    );
    return Invoice.fromJson(_decodeObject(response));
  }

  Future<Invoice> markInvoiceUnpaid(int id) async {
    final response = await _authenticatedPost(
      'invoices/$id/mark-unpaid',
      const {},
    );
    return Invoice.fromJson(_decodeObject(response));
  }

  Future<List<Job>> fetchJobs({String status = 'all'}) async {
    final response = await _authenticatedGet(
      'jobs?per_page=100&status=${Uri.encodeQueryComponent(status)}',
    );
    return _decodeItems(response).map(Job.fromJson).toList(growable: false);
  }

  Future<Job> fetchJob(int id) async {
    final response = await _authenticatedGet('jobs/$id');
    return Job.fromJson(_decodeObject(response));
  }

  Future<Job> createJob(CreateJobRequest request) async {
    final response = await _authenticatedPost('jobs', request.toJson());
    return Job.fromJson(_decodeObject(response));
  }

  Future<Job> completeJob(int id) async {
    final response = await _authenticatedPost('jobs/$id/complete', const {});
    return Job.fromJson(_decodeObject(response));
  }

  Future<Job> reopenJob(int id) async {
    final response = await _authenticatedPost('jobs/$id/reopen', const {});
    return Job.fromJson(_decodeObject(response));
  }

  Future<Job> addJobNotes(int id, String notes, {bool append = true}) async {
    final response = await _authenticatedPost('jobs/$id/notes', {
      'notes': notes,
      'append': append,
    });
    return Job.fromJson(_decodeObject(response));
  }

  Future<List<CrmDocument>> fetchDocuments() async {
    final response = await _authenticatedGet('documents?per_page=100');
    return _decodeItems(
      response,
    ).map(CrmDocument.fromJson).toList(growable: false);
  }

  Future<List<CrmDocument>> fetchClientDocuments(int clientId) async {
    final response = await _authenticatedGet(
      'clients/$clientId/documents?per_page=100',
    );
    return _decodeItems(
      response,
    ).map(CrmDocument.fromJson).toList(growable: false);
  }

  Future<CrmDocument> uploadClientDocument({
    required int clientId,
    required String title,
    required String type,
    required String filePath,
    String description = '',
    int projectId = 0,
  }) async {
    final headers = await _authenticatedHeaders(includeContentType: false);
    final endpoint = ApiConfig.endpoint('clients/$clientId/documents');
    final request = http.MultipartRequest('POST', endpoint)
      ..headers.addAll(headers)
      ..fields.addAll({
        'title': title,
        'type': type,
        'description': description,
        'project_id': '$projectId',
      })
      ..files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamed = await _send(
      endpoint,
      () async => http.Response.fromStream(await _client.send(request)),
    );
    return CrmDocument.fromJson(_decodeObject(streamed));
  }

  Future<DocumentDownload> fetchDocumentDownload(int id) async {
    final response = await _authenticatedGet('documents/$id/download');
    return DocumentDownload.fromJson(_decodeObject(response));
  }

  Future<List<CrmNotification>> fetchNotifications() async {
    final response = await _authenticatedGet('notifications?per_page=100');
    return _decodeItems(
      response,
    ).map(CrmNotification.fromJson).toList(growable: false);
  }

  Future<void> markNotificationRead(String id) async {
    await _authenticatedPost('notifications/$id/read', const {});
  }

  Future<http.Response> _authenticatedGet(String path) async {
    final headers = await _authenticatedHeaders();
    final endpoint = ApiConfig.endpoint(path);
    return _send(endpoint, () => _client.get(endpoint, headers: headers));
  }

  Future<http.Response> _authenticatedPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final headers = await _authenticatedHeaders();
    final endpoint = ApiConfig.endpoint(path);
    return _send(
      endpoint,
      () => _client.post(endpoint, headers: headers, body: jsonEncode(body)),
    );
  }

  Future<Map<String, String>> _authenticatedHeaders({
    bool includeContentType = true,
  }) async {
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please log in to continue.', statusCode: 401);
    }
    return {
      'Accept': 'application/json',
      if (includeContentType) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _send(
    Uri endpoint,
    Future<http.Response> Function() operation, {
    bool authenticated = true,
    bool loginRequest = false,
  }) async {
    try {
      final response = await operation().timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      if (authenticated && response.statusCode == 401) {
        await _tokenStore.deleteToken();
      }
      throw ApiException(
        _errorMessage(response, loginRequest: loginRequest),
        statusCode: response.statusCode,
        endpoint: endpoint,
        responseBody: response.body,
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'The live CRM server took too long to respond.',
        endpoint: endpoint,
      );
    } on http.ClientException {
      throw ApiException(
        'The live CRM server could not be reached. Check your internet connection and try again.',
        endpoint: endpoint,
      );
    } on FormatException {
      throw ApiException(
        'The live CRM server returned an unreadable response.',
        endpoint: endpoint,
      );
    }
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object.');
    }
    return decoded;
  }

  List<Map<String, dynamic>> _decodeItems(http.Response response) {
    final items = _decodeObject(response)['items'];
    if (items is! List<dynamic>) {
      throw const FormatException('Expected a JSON item collection.');
    }
    return items.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  String _errorMessage(http.Response response, {required bool loginRequest}) {
    if (loginRequest && response.statusCode == 401) {
      return 'Invalid email or password.';
    }
    if (response.statusCode == 401) {
      return 'Authentication failed. Please log in again.';
    }
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final message = data['message'] as String?;
        if (message != null && message.isNotEmpty) return message;
      }
    } on FormatException {
      // Fall through to a stable client-side message.
    }
    return 'The CRM request failed (${response.statusCode}).';
  }

  static const _jsonHeaders = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
