import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/errors/api_exception.dart';
import '../core/storage/token_store.dart';
import '../models/client.dart';
import '../models/commercial_session.dart';
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
  CommercialSession? _currentSession;
  void Function(ApiException error)? onSessionInvalidated;

  CommercialSession? get currentSession => _currentSession;

  Future<bool> hasSession() async {
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) return false;
    try {
      await bootstrapSession();
      return true;
    } on ApiException catch (error) {
      if (error.shouldClearSession) {
        await _clearCommercialSession(error, notify: false);
        return false;
      }
      rethrow;
    }
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
    try {
      final session = data['session'];
      if (session is Map<String, dynamic>) {
        _currentSession = CommercialSession.fromJson(session);
      } else {
        await bootstrapSession();
      }
      _assertActiveSession();
    } on ApiException catch (error) {
      if (error.shouldClearSession) {
        await _clearCommercialSession(error, notify: false);
      } else {
        await _tokenStore.deleteToken();
        _currentSession = null;
      }
      rethrow;
    } catch (error) {
      await _tokenStore.deleteToken();
      _currentSession = null;
      rethrow;
    }
  }

  Future<CommercialSession> bootstrapSession() async {
    final response = await _authenticatedGet('session');
    _currentSession = CommercialSession.fromJson(_decodeObject(response));
    _assertActiveSession();
    return _currentSession!;
  }

  Future<void> logout() async {
    await _tokenStore.deleteToken();
    _currentSession = null;
  }

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

  Future<Client> createClient(CreateClientRequest request) async {
    final response = await _authenticatedPost('clients', request.toJson());
    return Client.fromJson(_decodeObject(response));
  }

  Future<Client> updateClient(int id, CreateClientRequest request) async {
    final response = await _authenticatedPost('clients/$id', request.toJson());
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

  Future<InvoicePdfFile> fetchInvoicePdf(int id) =>
      _fetchInvoicePdfFile('invoices/$id/pdf', 'invoice-$id.pdf');

  Future<InvoicePdfFile> downloadInvoicePdf(int id) =>
      _fetchInvoicePdfFile('invoices/$id/download-pdf', 'invoice-$id.pdf');

  Future<InvoicePayment> fetchInvoicePaymentLink(int id) async {
    final response = await _authenticatedGet('invoices/$id/payment-link');
    return InvoicePayment.fromJson(_decodeObject(response));
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
    final headers = await _authenticatedHeaders(includeContentType: false);
    final endpoint = ApiConfig.endpoint(path);
    return _send(endpoint, () => _client.get(endpoint, headers: headers));
  }

  Future<InvoicePdfFile> _fetchInvoicePdfFile(
    String path,
    String fallbackFileName,
  ) async {
    final headers = await _authenticatedHeaders(
      includeContentType: false,
      accept: 'application/pdf',
    );
    final endpoint = ApiConfig.endpoint(path);
    final response = await _send(
      endpoint,
      () => _client.get(endpoint, headers: headers),
    );
    return InvoicePdfFile(
      bytes: response.bodyBytes,
      fileName: _fileNameFromResponse(response) ?? fallbackFileName,
      mimeType:
          response.headers['content-type']?.split(';').first.trim() ??
          'application/pdf',
    );
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
    String accept = 'application/json',
  }) async {
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please log in to continue.', statusCode: 401);
    }
    return {
      'Accept': accept,
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
      final apiError = _apiException(
        response,
        loginRequest: loginRequest,
        endpoint: endpoint,
      );
      if (authenticated && apiError.shouldClearSession) {
        await _clearCommercialSession(apiError);
      }
      throw apiError;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'The live CRM server took too long to respond.',
        category: ApiErrorCategory.networkProblem,
        endpoint: endpoint,
      );
    } on http.ClientException {
      throw ApiException(
        'The live CRM server could not be reached. Check your internet connection and try again.',
        category: ApiErrorCategory.networkProblem,
        endpoint: endpoint,
      );
    } on FormatException {
      throw ApiException(
        'The live CRM server returned an unreadable response.',
        category: ApiErrorCategory.temporaryServiceProblem,
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

  ApiException _apiException(
    http.Response response, {
    required bool loginRequest,
    required Uri endpoint,
  }) {
    final parsed = _errorPayload(response);
    final code = parsed.$1;
    final backendMessage = parsed.$2;
    final category = _categoryFor(response.statusCode, code);
    final message = _safeErrorMessage(
      response.statusCode,
      category,
      backendMessage,
      loginRequest: loginRequest,
    );
    return ApiException(
      message,
      statusCode: response.statusCode,
      code: code,
      category: category,
      endpoint: endpoint,
      responseBody: response.body,
    );
  }

  (String?, String?) _errorPayload(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return (data['code'] as String?, data['message'] as String?);
      }
    } on FormatException {
      // Fall through to a stable client-side message.
    }
    return (null, null);
  }

  String _safeErrorMessage(
    int statusCode,
    ApiErrorCategory category,
    String? backendMessage, {
    required bool loginRequest,
  }) {
    if (loginRequest && statusCode == 401) {
      return 'Invalid email or password.';
    }
    switch (category) {
      case ApiErrorCategory.sessionExpired:
        return 'Authentication failed. Please log in again.';
      case ApiErrorCategory.accessRemoved:
        return 'Your access to this company workspace has been removed or deactivated.';
      case ApiErrorCategory.accountInactive:
        return 'This workspace is not active. Please contact the workspace owner.';
      case ApiErrorCategory.featureUnavailable:
        return backendMessage ??
            'This feature is not available on the current plan.';
      case ApiErrorCategory.limitReached:
        return backendMessage ?? 'You have reached the current plan limit.';
      case ApiErrorCategory.rateLimited:
        return 'Too many requests. Please wait a moment and try again.';
      case ApiErrorCategory.validationProblem:
        return backendMessage ?? 'Please check the details and try again.';
      case ApiErrorCategory.conflict:
        return backendMessage ??
            'This request needs another step before it can continue.';
      case ApiErrorCategory.notFound:
        return 'The requested CRM record could not be found.';
      case ApiErrorCategory.temporaryServiceProblem:
        return 'The CRM service is temporarily unavailable. Please try again.';
      case ApiErrorCategory.networkProblem:
        return 'The live CRM server could not be reached. Check your internet connection and try again.';
      case ApiErrorCategory.unknown:
        return backendMessage ?? 'The CRM request failed ($statusCode).';
    }
  }

  ApiErrorCategory _categoryFor(int statusCode, String? code) {
    final normalized = code ?? '';
    if (statusCode == 401) return ApiErrorCategory.sessionExpired;
    if (normalized.contains('membership') ||
        normalized.contains('tenant_inactive') ||
        normalized.contains('selection_denied')) {
      return ApiErrorCategory.accessRemoved;
    }
    if (normalized.contains('suspended') ||
        normalized.contains('expired') ||
        normalized.contains('inactive')) {
      return ApiErrorCategory.accountInactive;
    }
    if (normalized.contains('limit_reached')) {
      return ApiErrorCategory.limitReached;
    }
    if (normalized.contains('feature_not_in_plan') ||
        normalized.contains('role_not_permitted')) {
      return ApiErrorCategory.featureUnavailable;
    }
    return switch (statusCode) {
      400 => ApiErrorCategory.validationProblem,
      403 => ApiErrorCategory.accessRemoved,
      404 => ApiErrorCategory.notFound,
      409 => ApiErrorCategory.conflict,
      429 => ApiErrorCategory.rateLimited,
      >= 500 => ApiErrorCategory.temporaryServiceProblem,
      _ => ApiErrorCategory.unknown,
    };
  }

  void _assertActiveSession() {
    final session = _currentSession;
    if (session == null || !session.hasActiveWorkspace) {
      throw const ApiException(
        'Your access to this company workspace has been removed or deactivated.',
        statusCode: 403,
        code: 'daphnex_mobile_session_inactive',
        category: ApiErrorCategory.accessRemoved,
      );
    }
  }

  Future<void> _clearCommercialSession(
    ApiException error, {
    bool notify = true,
  }) async {
    await _tokenStore.deleteToken();
    _currentSession = null;
    if (notify) onSessionInvalidated?.call(error);
  }

  String? _fileNameFromResponse(http.Response response) {
    final disposition = response.headers['content-disposition'];
    if (disposition == null || disposition.isEmpty) return null;
    final match = RegExp(
      r'''filename\*?=(?:UTF-8''|")?([^";]+)"?''',
      caseSensitive: false,
    ).firstMatch(disposition);
    final value = match?.group(1);
    return value == null || value.isEmpty ? null : Uri.decodeFull(value);
  }

  static const _jsonHeaders = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
