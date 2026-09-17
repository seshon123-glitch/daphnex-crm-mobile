import 'package:daphnex_crm_mobile/app.dart';
import 'package:daphnex_crm_mobile/core/errors/api_exception.dart';
import 'package:daphnex_crm_mobile/core/widgets/date_time_picker_fields.dart';
import 'package:daphnex_crm_mobile/features/account/account_screens.dart';
import 'package:daphnex_crm_mobile/features/clients/client_profile_screen.dart';
import 'package:daphnex_crm_mobile/features/documents/documents_screen.dart';
import 'package:daphnex_crm_mobile/features/invoices/invoices_screen.dart';
import 'package:daphnex_crm_mobile/features/jobs/jobs_screen.dart';
import 'package:daphnex_crm_mobile/features/outstanding/outstanding_screen.dart';
import 'package:daphnex_crm_mobile/features/quotes/quotes_screen.dart';
import 'package:daphnex_crm_mobile/features/reminders/reminders_screen.dart';
import 'package:daphnex_crm_mobile/features/tasks/tasks_screen.dart';
import 'package:daphnex_crm_mobile/models/client.dart';
import 'package:daphnex_crm_mobile/models/commercial_session.dart';
import 'package:daphnex_crm_mobile/models/dashboard_data.dart';
import 'package:daphnex_crm_mobile/models/invoice.dart';
import 'package:daphnex_crm_mobile/models/job.dart';
import 'package:daphnex_crm_mobile/models/project_expense.dart';
import 'package:daphnex_crm_mobile/models/quote.dart';
import 'package:daphnex_crm_mobile/services/document_picker_service.dart';
import 'package:daphnex_crm_mobile/services/pdf_share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_crm_api.dart';

void main() {
  tearDown(() {
    DatePickerFormField.debugPickerOverride = null;
    TimePickerFormField.debugPickerOverride = null;
    PdfShareService.debugShareOverride = null;
  });

  Finder scrollableByKey(Key key) {
    return find
        .descendant(of: find.byKey(key), matching: find.byType(Scrollable))
        .first;
  }

  test(
    'PDF share service sends a PDF attachment payload without URL text',
    () async {
      final channel = const MethodChannel('com.daphnex.crm/document_picker');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      await const PdfShareService().sharePdf(
        filePath: r'C:\Temp\quote-1.pdf',
        fileName: 'quote-1.pdf',
        text:
            'Hello Northstar Studio, please find quotation QUOTE-000001 attached as a PDF.',
        subject: 'Quotation QUOTE-000001',
        targetPackage: 'com.whatsapp',
      );

      expect(calls, hasLength(1));
      expect(calls.single.method, 'sharePdf');
      final args = calls.single.arguments as Map<Object?, Object?>;
      expect(args['fileName'], 'quote-1.pdf');
      expect(args['mimeType'], 'application/pdf');
      expect(args['targetPackage'], 'com.whatsapp');
      expect(args['text'], contains('attached as a PDF'));
      expect(args['text'], isNot(contains('https://')));
    },
  );

  Future<FakeCrmApi> login(
    WidgetTester tester, {
    CommercialRole role = CommercialRole.owner,
    FakeCrmApi? api,
  }) async {
    final fakeApi = api ?? FakeCrmApi();
    fakeApi.sessionRole = role;
    await tester.pumpWidget(DaphnexCrmApp(api: fakeApi));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'admin@example.test',
    );
    await tester.enterText(find.byKey(const Key('passwordField')), 'secret');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();
    return fakeApi;
  }

  Future<void> tapBottomDestination(WidgetTester tester, String label) async {
    final index = switch (label) {
      'Clients' => 0,
      'Reminders' => 1,
      'Outstanding' => 2,
      'Turnover' => 3,
      'Settings' => 4,
      _ => throw ArgumentError.value(label, 'label', 'Unknown destination'),
    };
    await tester.tap(find.byType(NavigationDestination).at(index));
    await tester.pumpAndSettle();
  }

  Future<void> openSettingsHub(WidgetTester tester) async {
    await tapBottomDestination(tester, 'Settings');
    final scrollable = scrollableByKey(const Key('moreScroll'));
    expect(scrollable, findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.drag(scrollable, const Offset(0, 700), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapMoreCard(WidgetTester tester, Key key) async {
    final scrollable = scrollableByKey(const Key('moreScroll'));
    await tester.scrollUntilVisible(
      find.byKey(key),
      220,
      scrollable: scrollable,
      maxScrolls: 30,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(key)),
      alignment: 0.35,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Future<void> expectMoreCardVisible(WidgetTester tester, Key key) async {
    final scrollable = scrollableByKey(const Key('moreScroll'));
    await tester.scrollUntilVisible(
      find.byKey(key),
      220,
      scrollable: scrollable,
      maxScrolls: 30,
    );
    expect(find.byKey(key), findsOneWidget);
  }

  Future<void> popPushedScreen(WidgetTester tester) async {
    Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
    await tester.pumpAndSettle();
  }

  Future<void> expectReadOnlyPickerField(
    WidgetTester tester,
    Key fieldKey,
  ) async {
    await tester.pump();
    final textField = find.descendant(
      of: find.byKey(fieldKey),
      matching: find.byType(TextField),
    );
    expect(textField, findsOneWidget);
    final widget = tester.widget<TextField>(textField);
    expect(widget.readOnly, isTrue);
    expect(widget.keyboardType, TextInputType.none);
  }

  testWidgets('live login opens client-centric root navigation', (
    tester,
  ) async {
    final api = await login(tester);
    expect(api.lastLoginEmail, 'admin@example.test');
    expect(find.byKey(const Key('clientSearch')), findsOneWidget);
    expect(find.text('Olivia Bennett'), findsOneWidget);
    expect(find.byKey(const Key('clients-premiumBanner')), findsOneWidget);
    expect(find.text('Clients'), findsWidgets);
    expect(
      find.textContaining('projects, tasks, quotes, invoices and documents'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('commercialBottomNavigation')), findsOneWidget);
    expect(find.text('Clients'), findsWidgets);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Outstanding'), findsOneWidget);
    expect(find.text('Turnover'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('client-centric shell exposes primary work areas', (
    tester,
  ) async {
    await login(tester);
    expect(find.text('Clients'), findsWidgets);
    await tapBottomDestination(tester, 'Reminders');
    expect(find.text('Reminders'), findsWidgets);
    await tapBottomDestination(tester, 'Outstanding');
    expect(find.text('Outstanding balance'), findsWidgets);
    await tapBottomDestination(tester, 'Turnover');
    expect(find.text('Monthly Turnover'), findsWidgets);
    await tapBottomDestination(tester, 'Settings');
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('dashboard handles long company and large currency values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = FakeCrmApi()
      ..sessionCompanyName =
          'Northstar Commercial Maintenance and Property Services Limited'
      ..sessionBrandingInitials = 'NM'
      ..dashboardData = const DashboardData(
        totalClients: 987,
        activeJobs: 48,
        completedJobs: 122,
        pendingInvoices: 31,
        unpaidInvoices: 12,
        outstandingInvoiceAmount: 987654321,
        upcomingReminders: 9,
        unreadNotifications: 6,
      );
    api.invoices[0] = const Invoice(
      id: 1,
      clientId: 1,
      clientName: 'Northstar Studio',
      projectId: 1,
      projectName: 'Website maintenance',
      invoiceNumber: 'INV-2026-0001',
      issueDate: '2026-06-24',
      dueDate: '2026-07-01',
      totalAmount: 987654321,
      amountPaid: 0,
      balance: 987654321,
      status: 'sent',
      notes: 'Large value invoice',
    );

    await login(tester, api: api);

    await tapBottomDestination(tester, 'Outstanding');
    expect(find.textContaining('£9876543.21'), findsWidgets);
    await tapBottomDestination(tester, 'Turnover');
    expect(find.text('Monthly Turnover'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed login displays API error', (tester) async {
    final api = FakeCrmApi()..failLogin = true;
    await tester.pumpWidget(DaphnexCrmApp(api: api));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'admin@example.test',
    );
    await tester.enterText(find.byKey(const Key('passwordField')), 'wrong');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loginError')), findsOneWidget);
    expect(find.textContaining('Invalid email or password.'), findsOneWidget);
    expect(find.textContaining('API base URL:'), findsNothing);
    expect(find.textContaining('Endpoint called:'), findsNothing);
  });

  testWidgets('access removal exits protected workspace safely', (
    tester,
  ) async {
    final api = await login(tester);
    api.simulateSessionInvalidated(
      const ApiException(
        'Your access to this company workspace has been removed or deactivated.',
        statusCode: 403,
        code: 'daphnex_tenant_membership_required',
        category: ApiErrorCategory.accessRemoved,
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loginError')), findsOneWidget);
    expect(
      find.textContaining('access to this company workspace has been removed'),
      findsOneWidget,
    );
    expect(api.session, isFalse);
    expect(api.currentSession, isNull);
  });

  testWidgets('clients search opens workspace before detailed profile', (
    tester,
  ) async {
    await login(tester);
    await tester.enterText(find.byKey(const Key('clientSearch')), 'Brightline');
    await tester.pump();
    expect(find.text('Marcus Chen'), findsOneWidget);
    expect(find.text('Olivia Bennett'), findsNothing);
    await tester.tap(find.text('Marcus Chen'));
    await tester.pumpAndSettle();
    expect(find.text('Client profile'), findsOneWidget);
    expect(find.byKey(const Key('viewClientProfileButton')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('clientProjectsTile')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const Key('clientProjectsTile')), findsOneWidget);
    expect(find.byKey(const Key('clientTasksTile')), findsOneWidget);
    expect(find.byKey(const Key('clientDocumentsTile')), findsOneWidget);
    await tester.tap(find.byKey(const Key('viewClientProfileButton')));
    await tester.pumpAndSettle();
    expect(find.text('Client profile details'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Address Line 1'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Address Line 1'), findsOneWidget);
    expect(find.text('Address Line 2'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('County / State'), findsOneWidget);
    expect(find.text('Postcode'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Not provided'), findsWidgets);
  });

  testWidgets('client create and edit use live API methods', (tester) async {
    final api = await login(tester);
    await tester.tap(find.byKey(const Key('addClientButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('clientFirstNameField')),
      'Priya',
    );
    await tester.enterText(
      find.byKey(const Key('clientLastNameField')),
      'Shah',
    );
    await tester.enterText(
      find.byKey(const Key('clientCompanyField')),
      'Blue Finch',
    );
    await tester.enterText(
      find.byKey(const Key('clientEmailField')),
      'priya@example.test',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('clientAddressLine1Field')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.enterText(
      find.byKey(const Key('clientAddressLine1Field')),
      '10 Pilot Street',
    );
    await tester.enterText(find.byKey(const Key('clientCityField')), 'London');
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('clientMoreAddressDetails'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('clientMoreAddressDetails')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('clientCountyStateField')),
      'Greater London',
    );
    await tester.enterText(
      find.byKey(const Key('clientPostcodeField')),
      'P01 0AA',
    );
    await tester.enterText(
      find.byKey(const Key('clientCountryField')),
      'United Kingdom',
    );
    await tester.tap(find.byKey(const Key('saveClientForm')));
    await tester.pumpAndSettle();
    expect(api.clients, hasLength(3));
    await tester.scrollUntilVisible(
      find.text('Priya Shah'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Priya Shah'), findsOneWidget);

    await tester.tap(find.text('Priya Shah'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editClientButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('editClientCompanyField')),
      'Blue Finch Studio',
    );
    await tester.tap(find.byKey(const Key('saveEditClient')));
    await tester.pumpAndSettle();
    expect(find.text('Blue Finch Studio'), findsWidgets);

    await tester.tap(find.byKey(const Key('viewClientProfileButton')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Address Line 1'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('10 Pilot Street'), findsOneWidget);
    expect(find.text('London'), findsOneWidget);
    expect(find.text('Greater London'), findsOneWidget);
    expect(find.text('P01 0AA'), findsOneWidget);
    expect(find.text('United Kingdom'), findsOneWidget);
  });

  testWidgets('minimal client create requires only first and last name', (
    tester,
  ) async {
    final api = await login(tester);
    await tester.tap(find.byKey(const Key('addClientButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('clientFirstNameField')),
      'John',
    );
    await tester.enterText(
      find.byKey(const Key('clientLastNameField')),
      'Smith',
    );
    await tester.tap(find.byKey(const Key('saveClientForm')));
    await tester.pumpAndSettle();
    expect(api.clients, hasLength(3));
    await tester.scrollUntilVisible(
      find.text('John Smith'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('John Smith'), findsOneWidget);
  });

  testWidgets('clients sort alphabetically and search by contact fields', (
    tester,
  ) async {
    final api = FakeCrmApi();
    api.clients.add(
      const Client(
        id: 3,
        name: 'Adam Smith',
        firstName: 'Adam',
        lastName: 'Smith',
        company: 'Kunzle Limited',
        phone: '07123 456789',
        email: 'adam@kunzle.example',
      ),
    );
    await login(tester, api: api);

    expect(
      find.text('Search by name, company, phone or email'),
      findsOneWidget,
    );
    final firstOrdinal = tester.getTopLeft(find.text('1.').first);
    final adamTop = tester.getTopLeft(find.text('Adam Smith'));
    expect((adamTop.dy - firstOrdinal.dy).abs(), lessThan(40));

    await tester.enterText(find.byKey(const Key('clientSearch')), 'kunzle');
    await tester.pumpAndSettle();
    expect(find.text('Adam Smith'), findsOneWidget);
    expect(find.text('Olivia Bennett'), findsNothing);

    await tester.enterText(find.byKey(const Key('clientSearch')), '456789');
    await tester.pumpAndSettle();
    expect(find.text('Adam Smith'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('clientSearch')), 'adam@');
    await tester.pumpAndSettle();
    expect(find.text('Adam Smith'), findsOneWidget);
  });

  testWidgets('new client keeps simplified address and optional notes', (
    tester,
  ) async {
    await login(tester);
    await tester.tap(find.byKey(const Key('addClientButton')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('clientAddressLine1Field')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Address'), findsWidgets);
    expect(find.text('City / Town'), findsOneWidget);
    expect(find.text('Postcode'), findsOneWidget);
    expect(find.byKey(const Key('clientMoreAddressDetails')), findsOneWidget);
    expect(find.text('Address Line 2'), findsNothing);
    expect(find.text('Optional notes about this client'), findsOneWidget);
  });

  testWidgets('client workspace includes isolated quotes workflow', (
    tester,
  ) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ClientProfileScreen(api: api, client: api.clients.first),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('clientQuotesTile')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const Key('clientQuotesTile')), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: QuotesScreen(api: api, client: api.clients.first),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('QUOTE-000001'), findsOneWidget);
    await tester.tap(find.byKey(const Key('createQuoteButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('quoteItemDescriptionField-0')),
      'Consultation',
    );
    await tester.enterText(
      find.byKey(const Key('quoteItemAmountField-0')),
      '75',
    );
    await tester.tap(find.byKey(const Key('addQuoteItemButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('quoteItemDescriptionField-1')),
      'Materials',
    );
    await tester.enterText(
      find.byKey(const Key('quoteItemAmountField-1')),
      '25',
    );
    await tester.tap(find.byKey(const Key('saveQuoteForm')));
    await tester.pumpAndSettle();

    expect(api.quotes.where((quote) => quote.clientId == 1), hasLength(2));
    expect(api.invoices, hasLength(1));
    expect(api.dashboardData.outstandingInvoiceAmount, 15000);
  });

  testWidgets('quote detail supports edit delete pdf and WhatsApp actions', (
    tester,
  ) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(
      MaterialApp(
        home: QuotesScreen(api: api, client: api.clients.first),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quote-1')));
    await tester.pumpAndSettle();

    expect(find.text('QUOTATION'), findsOneWidget);
    expect(find.byKey(const Key('editQuoteButton')), findsOneWidget);
    expect(find.byKey(const Key('viewQuotePdfButton')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('downloadQuotePdfButton')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const Key('downloadQuotePdfButton')), findsOneWidget);
    expect(find.byKey(const Key('shareQuoteWhatsAppButton')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('deleteQuoteButton')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('deleteQuoteButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(api.deletedQuoteId, 1);
  });

  testWidgets('mobile project form does not show project type', (tester) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(MaterialApp(home: JobsScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createJobButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('jobTypeField')), findsNothing);
    expect(find.text('Project Type'), findsNothing);
  });

  testWidgets('turnover is monthly only and finance snapshot is outstanding', (
    tester,
  ) async {
    final api = await login(tester);
    await tapBottomDestination(tester, 'Turnover');
    expect(find.text('Monthly Turnover'), findsWidgets);
    expect(find.text('Total Invoiced'), findsOneWidget);
    expect(find.text('Outstanding invoice amount'), findsNothing);
    expect(find.textContaining('Profit'), findsNothing);
    expect(find.textContaining('Expenses'), findsNothing);

    await tapBottomDestination(tester, 'Outstanding');
    expect(find.text('Live finance snapshot'), findsOneWidget);
    expect(find.text('Outstanding balance'), findsWidgets);
    expect(api.dashboardData.outstandingInvoiceAmount, 15000);
  });

  testWidgets('reminder tap opens detail and explicit completion updates UI', (
    tester,
  ) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(MaterialApp(home: RemindersScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reminder-1')));
    await tester.pumpAndSettle();
    expect(find.text('Reminder detail'), findsOneWidget);
    expect(api.completedReminderId, isNull);
    await tester.scrollUntilVisible(
      find.byKey(const Key('toggleReminderButton')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('toggleReminderButton')));
    await tester.pumpAndSettle();
    expect(api.completedReminderId, 1);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('reminder detail edit and delete use API safely', (tester) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(MaterialApp(home: RemindersScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reminder-1')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('editReminderButton')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('editReminderButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('newReminderField')),
      'Edited reminder',
    );
    await tester.tap(find.byKey(const Key('confirmAddReminder')));
    await tester.pumpAndSettle();
    expect(api.reminders.single.title, 'Edited reminder');
    await tester.scrollUntilVisible(
      find.byKey(const Key('deleteReminderButton')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('deleteReminderButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(api.reminders, isEmpty);
  });

  testWidgets('completed reminder can reopen and delete with the same ID', (
    tester,
  ) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(MaterialApp(home: RemindersScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reminder-1')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('toggleReminderButton')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('toggleReminderButton')));
    await tester.pumpAndSettle();

    expect(api.completedReminderId, 1);
    expect(api.reminders.single.id, 1);
    expect(api.reminders.single.status, 'completed');

    await tester.tap(find.byKey(const Key('toggleReminderButton')));
    await tester.pumpAndSettle();

    expect(api.updatedReminderId, 1);
    expect(api.lastReminderUpdateRequest?.status, 'pending');
    expect(api.reminders.single.id, 1);
    expect(api.reminders.single.status, 'pending');

    await tester.tap(find.byKey(const Key('toggleReminderButton')));
    await tester.pumpAndSettle();

    expect(api.completedReminderId, 1);
    expect(api.reminders.single.id, 1);
    expect(api.reminders.single.status, 'completed');

    await tester.scrollUntilVisible(
      find.byKey(const Key('deleteReminderButton')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('deleteReminderButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(api.deletedReminderId, 1);
    expect(api.reminders, isEmpty);
    expect(api.fetchRemindersCalls, greaterThanOrEqualTo(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('add reminder posts and refreshes list', (tester) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(MaterialApp(home: RemindersScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addReminderButton')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(
      find.byKey(const Key('newReminderField')),
      'Mobile API reminder',
    );
    await tester.tap(find.byKey(const Key('confirmAddReminder')));
    await tester.pump(const Duration(seconds: 1));
    expect(api.reminders.length, 2);
    expect(api.fetchRemindersCalls, 2);
    expect(find.text('New reminder'), findsNothing);
    expect(find.text('2. Mobile API reminder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('shared picker formatters preserve CRM payload formats', () {
    expect(formatCrmDate(DateTime(2026, 9, 12)), '2026-09-12');
    expect(formatCrmTime(const TimeOfDay(hour: 14, minute: 30)), '14:30');
  });

  testWidgets('reminder date and time are read-only picker fields', (
    tester,
  ) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(MaterialApp(home: RemindersScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addReminderButton')));
    await tester.pump(const Duration(milliseconds: 500));
    await expectReadOnlyPickerField(tester, const Key('reminderDateField'));
    await expectReadOnlyPickerField(tester, const Key('reminderTimeField'));
  });

  testWidgets('job and invoice creation use client selectors', (tester) async {
    final api = FakeCrmApi();

    await tester.pumpWidget(MaterialApp(home: JobsScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createJobButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('jobClientField')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('jobTitleField')),
      'Mobile rollout',
    );
    await tester.tap(find.text('Create').last);
    await tester.pumpAndSettle();
    expect(api.jobs, hasLength(2));
    expect(find.text('2. Mobile rollout'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(home: InvoicesScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createInvoiceButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invoiceClientField')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('invoiceItemDescription-0')),
      'Mobile support',
    );
    await tester.enterText(find.byKey(const Key('invoiceItemAmount-0')), '250');
    await tester.tap(find.text('Create').last);
    await tester.pumpAndSettle();
    expect(api.invoices, hasLength(2));
    expect(find.text('INV-TEST-2'), findsOneWidget);
  });

  testWidgets('client invoices stay scoped to the selected client', (
    tester,
  ) async {
    final api = FakeCrmApi();
    final brightline = api.clients.last;

    await tester.pumpWidget(
      MaterialApp(
        home: InvoicesScreen(api: api, client: brightline),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No invoices found.'), findsOneWidget);
    expect(find.text('INV-2026-0001'), findsNothing);

    await tester.tap(find.byKey(const Key('createInvoiceButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invoiceClientField')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('invoiceItemDescription-0')),
      'Brightline support',
    );
    await tester.enterText(find.byKey(const Key('invoiceItemAmount-0')), '50');
    await tester.tap(find.text('Create').last);
    await tester.pumpAndSettle();

    expect(find.text('INV-TEST-2'), findsOneWidget);
    expect(find.text('INV-2026-0001'), findsNothing);

    await tester.tap(find.byKey(const Key('createInvoiceButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('invoiceItemDescription-0')),
      'Brightline hosting',
    );
    await tester.enterText(find.byKey(const Key('invoiceItemAmount-0')), '75');
    await tester.tap(find.text('Create').last);
    await tester.pumpAndSettle();

    expect(find.text('INV-TEST-2'), findsOneWidget);
    expect(find.text('INV-TEST-3'), findsOneWidget);
    expect(
      api.invoices.where((invoice) => invoice.clientId == 2),
      hasLength(2),
    );
  });

  testWidgets('outstanding part payments reduce balances and keep history', (
    tester,
  ) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(MaterialApp(home: OutstandingScreen(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('£150.00'), findsWidgets);
    await tester.tap(find.byKey(const Key('outstanding-invoice-1')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Payment history'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Payment history'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('addPaymentButton')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('addPaymentButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('paymentAmountField')), '50');
    await tester.enterText(
      find.byKey(const Key('paymentReferenceField')),
      'PART-1',
    );
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    expect(find.text('£100.00'), findsWidgets);
    expect(api.invoices.single.amountPaid, 5000);
    expect(api.invoices.single.balance, 10000);
    expect(api.invoices.single.payments.last.reference, 'PART-1');

    await tester.scrollUntilVisible(
      find.byKey(const Key('addPaymentButton')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('addPaymentButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('paymentAmountField')), '100');
    await tester.enterText(
      find.byKey(const Key('paymentReferenceField')),
      'FINAL-1',
    );
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    expect(api.invoices.single.balance, 0);
    expect(api.invoices.single.status, 'paid');
    expect(api.invoices.single.payments, hasLength(3));
  });

  testWidgets('outstanding includes live unpaid invoice balances', (
    tester,
  ) async {
    final api = FakeCrmApi();
    api.invoices.add(
      const Invoice(
        id: 55,
        clientId: 1,
        clientName: 'Northstar Studio',
        invoiceNumber: 'INV-LIVE-550',
        issueDate: '2026-09-16',
        dueDate: '2026-09-30',
        totalAmount: 55000,
        amountPaid: 0,
        balance: 55000,
        status: 'unpaid',
        notes: 'Live unpaid invoice fixture',
      ),
    );

    await tester.pumpWidget(MaterialApp(home: OutstandingScreen(api: api)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('outstanding-invoice-55')), findsOneWidget);
    expect(find.text('£550.00'), findsWidgets);
  });

  testWidgets('task due date is a read-only picker field', (tester) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(MaterialApp(home: TasksScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('createTaskButton')));
    await tester.pumpAndSettle();
    await expectReadOnlyPickerField(tester, const Key('taskDueDateField'));
  });

  testWidgets('task create form keeps advanced fields under More Options', (
    tester,
  ) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(MaterialApp(home: TasksScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('createTaskButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('taskTitleField')), findsOneWidget);
    expect(find.byKey(const Key('taskClientField')), findsOneWidget);
    expect(find.text('Project'), findsOneWidget);
    expect(find.byKey(const Key('taskDueDateField')), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Assigned To'), findsNothing);
    expect(find.text('Status'), findsNothing);
    expect(find.text('Internal Notes'), findsNothing);

    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('taskMoreOptions'))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('More Options'));
    await tester.pumpAndSettle();
    expect(find.text('Assigned To'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Internal Notes'), findsOneWidget);
  });

  testWidgets('task create, detail, edit and delete use live API methods', (
    tester,
  ) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(MaterialApp(home: TasksScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('createTaskButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('taskTitleField')),
      'Call client',
    );
    await tester.tap(find.byKey(const Key('saveTaskForm')));
    await tester.pumpAndSettle();
    expect(api.tasks, hasLength(2));
    expect(find.text('Call client'), findsOneWidget);

    await tester.tap(find.byKey(const Key('task-2')));
    await tester.pumpAndSettle();
    expect(find.text('Task detail'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('editTaskButton')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('editTaskButton'))),
      alignment: 0.45,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editTaskButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('taskTitleField')),
      'Updated task',
    );
    await tester.tap(find.byKey(const Key('saveTaskForm')));
    await tester.pumpAndSettle();
    expect(api.tasks.last.title, 'Updated task');
    await tester.scrollUntilVisible(
      find.byKey(const Key('deleteTaskButton')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('deleteTaskButton'))),
      alignment: 0.45,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteTaskButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(api.tasks, hasLength(1));
  });

  testWidgets('job start and deadline are read-only picker fields', (
    tester,
  ) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(MaterialApp(home: JobsScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('createJobButton')));
    await tester.pumpAndSettle();
    await expectReadOnlyPickerField(tester, const Key('jobStartDateField'));
    await expectReadOnlyPickerField(tester, const Key('jobDeadlineField'));
  });

  testWidgets('invoice date and due date are read-only picker fields', (
    tester,
  ) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(MaterialApp(home: InvoicesScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('createInvoiceButton')));
    await tester.pumpAndSettle();
    await expectReadOnlyPickerField(tester, const Key('invoiceDateField'));
    await expectReadOnlyPickerField(tester, const Key('invoiceDueDateField'));
  });

  testWidgets('document upload uses safe injected picker and multipart API', (
    tester,
  ) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(
      MaterialApp(
        home: DocumentsScreen(
          api: api,
          documentPicker: const _FakeDocumentPicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('uploadDocumentButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pickDocumentButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDocumentUpload')));
    await tester.pumpAndSettle();
    expect(api.documents, hasLength(2));
    expect(find.text('agreement'), findsOneWidget);
  });

  testWidgets('project expenses use simple expense CRUD instead of job form', (
    tester,
  ) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(MaterialApp(home: JobsScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1. Website maintenance'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('projectExpensesButton')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('projectExpensesButton')));
    await tester.pumpAndSettle();

    expect(find.text('Project Expenses'), findsWidgets);
    expect(find.text('Materials purchased'), findsOneWidget);
    expect(find.textContaining('do not affect Turnover'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addProjectExpenseButton')));
    await tester.pumpAndSettle();
    expect(find.text('Date *'), findsOneWidget);
    expect(find.text('Expense Description *'), findsOneWidget);
    expect(find.text('Amount *'), findsOneWidget);
    expect(find.textContaining('Project Title'), findsNothing);
    expect(find.textContaining('Project Type'), findsNothing);
    expect(find.textContaining('Priority'), findsNothing);
    expect(find.textContaining('Project Status'), findsNothing);
    expect(find.textContaining('Estimated Project Value'), findsNothing);
    expect(find.textContaining('Project Deadline'), findsNothing);
    expect(find.textContaining('Project Description'), findsNothing);
    DatePickerFormField.debugPickerOverride =
        (context, initialDate, firstDate, lastDate) async =>
            DateTime(2026, 9, 10);
    await tester.tap(find.byKey(const Key('expenseDateField')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('expenseDescriptionField')),
      'Fuel receipt',
    );
    await tester.enterText(find.byKey(const Key('expenseAmountField')), '45');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    expect(api.lastProjectExpenseRequest?.description, 'Fuel receipt');

    await tester.tap(find.text('Fuel receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Expense Detail'), findsOneWidget);
    expect(find.text('Client'), findsOneWidget);
    expect(find.text('Project'), findsOneWidget);
    expect(find.byKey(const Key('editProjectExpenseButton')), findsOneWidget);
    expect(find.byKey(const Key('deleteProjectExpenseButton')), findsOneWidget);
    expect(find.textContaining('Complete'), findsNothing);
    expect(find.textContaining('Reopen'), findsNothing);

    await tester.tap(find.byKey(const Key('editProjectExpenseButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('expenseDescriptionField')),
      'Updated fuel receipt',
    );
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    expect(api.lastProjectExpenseRequest?.description, 'Updated fuel receipt');
    expect(find.text('Updated fuel receipt'), findsOneWidget);

    await tester.tap(find.byKey(const Key('deleteProjectExpenseButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(api.deletedProjectExpenseId, isNotNull);
  });

  testWidgets('client Project Expenses tile saves expenses without job form', (
    tester,
  ) async {
    final api = FakeCrmApi();
    api.projectExpenses.clear();
    api.jobs.add(
      const Job(
        id: 2,
        clientId: 1,
        clientName: 'Northstar Studio',
        title: 'Kitchen Renovation',
        description: 'Kitchen works',
        status: 'active',
        startDate: '',
        completionDate: null,
        notes: '',
      ),
    );
    api.jobs.add(
      const Job(
        id: 3,
        clientId: 2,
        clientName: 'Brightline Digital',
        title: 'Client B Project',
        description: 'Different client project',
        status: 'active',
        startDate: '',
        completionDate: null,
        notes: '',
      ),
    );
    api.projectExpenses.addAll(const [
      ProjectExpense(
        id: 20,
        clientId: 1,
        clientName: 'Northstar Studio',
        projectId: 1,
        projectName: 'Website maintenance',
        expenseDate: '2026-09-16',
        description: 'Materials',
        amount: 8000,
      ),
      ProjectExpense(
        id: 21,
        clientId: 1,
        clientName: 'Northstar Studio',
        projectId: 2,
        projectName: 'Kitchen Renovation',
        expenseDate: '2026-09-18',
        description: 'Timber',
        amount: 15000,
      ),
      ProjectExpense(
        id: 22,
        clientId: 2,
        clientName: 'Brightline Digital',
        projectId: 3,
        projectName: 'Client B Project',
        expenseDate: '2026-09-19',
        description: 'Client B expense',
        amount: 30000,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: ClientProfileScreen(api: api, client: api.clients.first),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('clientExpensesTile')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(
      find.byType(Scrollable).last,
      const Offset(0, -180),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('clientExpensesTile')),
        matching: find.text('Project Expenses'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('createJobButton')), findsNothing);
    expect(find.text('Materials'), findsOneWidget);
    expect(find.text('Timber'), findsOneWidget);
    expect(find.text('Website maintenance'), findsOneWidget);
    expect(find.text('Kitchen Renovation'), findsOneWidget);
    expect(find.text('Client B expense'), findsNothing);
    expect(
      find.byKey(const Key('clientAddProjectExpenseButton')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('addExpenseForProject-1')), findsNothing);

    await tester.tap(find.byKey(const Key('clientAddProjectExpenseButton')));
    await tester.pumpAndSettle();
    expect(find.text('Project *'), findsOneWidget);
    expect(find.byKey(const Key('selectExpenseProject-1')), findsOneWidget);
    expect(find.byKey(const Key('selectExpenseProject-2')), findsOneWidget);
    expect(find.byKey(const Key('selectExpenseProject-3')), findsNothing);
    await tester.tap(find.byKey(const Key('selectExpenseProject-2')));
    await tester.pumpAndSettle();
    DatePickerFormField.debugPickerOverride =
        (context, initialDate, firstDate, lastDate) async =>
            DateTime(2026, 9, 12);
    await tester.tap(find.byKey(const Key('expenseDateField')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('expenseDescriptionField')),
      'Client tile expense',
    );
    await tester.enterText(find.byKey(const Key('expenseAmountField')), '31');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(api.lastProjectExpenseRequest?.description, 'Client tile expense');
    expect(
      api.projectExpenses.where(
        (expense) =>
            expense.clientId == 1 &&
            expense.projectId == 2 &&
            expense.description == 'Client tile expense',
      ),
      hasLength(1),
    );
    expect(
      api.projectExpenses.where(
        (expense) =>
            expense.clientId != 1 &&
            expense.description == 'Client tile expense',
      ),
      isEmpty,
    );
    expect(find.text('Client tile expense'), findsOneWidget);

    api.projectExpenses.clear();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(
        home: ClientProjectExpensesScreen(api: api, client: api.clients.first),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No project expenses recorded for this client yet.'),
      findsOneWidget,
    );

    api.jobs.removeWhere((job) => job.clientId == 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(
        home: ClientProjectExpensesScreen(api: api, client: api.clients.first),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No projects available. Create a project before adding project expenses.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('turnover invoices update count and totals from invoice date', (
    tester,
  ) async {
    final api = await login(tester);

    await tapBottomDestination(tester, 'Turnover');
    expect(find.text('2'), findsWidgets);
    expect(find.text('£940.00'), findsOneWidget);

    final firstInvoice = await api.createInvoice(
      const CreateInvoiceRequest(
        clientId: 1,
        projectId: 1,
        issueDate: '2026-09-15',
        items: [
          CreateInvoiceItemRequest(
            description: 'Existing project invoice',
            quantity: '1',
            unitAmount: '400.00',
          ),
        ],
      ),
    );
    await api.createInvoice(
      const CreateInvoiceRequest(
        clientId: 1,
        projectId: 1,
        issueDate: '2026-09-16',
        items: [
          CreateInvoiceItemRequest(
            description: 'Second existing project invoice',
            quantity: '1',
            unitAmount: '200.00',
          ),
        ],
      ),
    );

    await tapBottomDestination(tester, 'Clients');
    await tapBottomDestination(tester, 'Turnover');

    expect(find.text('4'), findsWidgets);
    expect(find.text('£1540.00'), findsOneWidget);

    await api.addInvoicePayment(
      firstInvoice.id,
      const CreateInvoicePaymentRequest(
        amount: '150.00',
        paidAt: '2026-09-20',
        paymentMethod: 'bank_transfer',
        paymentReference: 'TURNOVER-PAY-1',
      ),
    );
    await tapBottomDestination(tester, 'Clients');
    await tapBottomDestination(tester, 'Turnover');

    expect(find.text('4'), findsWidgets);
    expect(find.text('£1540.00'), findsOneWidget);

    await api.deleteInvoice(firstInvoice.id);
    await tapBottomDestination(tester, 'Clients');
    await tapBottomDestination(tester, 'Turnover');

    expect(find.text('3'), findsWidgets);
    expect(find.text('£1140.00'), findsOneWidget);

    await api.createJob(
      const CreateJobRequest(
        clientId: 1,
        title: 'New September project',
        startDate: '2026-09-21',
      ),
    );
    await tapBottomDestination(tester, 'Clients');
    await tapBottomDestination(tester, 'Turnover');

    expect(find.text('3'), findsWidgets);
    expect(find.text('£1140.00'), findsOneWidget);
  });

  testWidgets('turnover refreshes after invoice creation and excludes quotes', (
    tester,
  ) async {
    final api = await login(tester);

    await tapBottomDestination(tester, 'Turnover');
    expect(find.text('£940.00'), findsOneWidget);

    await api.createInvoice(
      const CreateInvoiceRequest(
        clientId: 1,
        issueDate: '2026-09-15',
        items: [
          CreateInvoiceItemRequest(
            description: 'Turnover refresh invoice',
            quantity: '1',
            unitAmount: '500.00',
          ),
        ],
      ),
    );
    await api.createQuote(
      const CreateQuoteRequest(
        clientId: 1,
        quoteDate: '2026-09-15',
        items: [
          CreateQuoteItemRequest(
            description: 'Turnover excluded quote',
            quantity: '1',
            unitAmount: '999.00',
          ),
        ],
      ),
    );

    await tapBottomDestination(tester, 'Clients');
    await tapBottomDestination(tester, 'Turnover');

    expect(find.text('£1440.00'), findsOneWidget);
    expect(find.text('£2439.00'), findsNothing);
  });

  testWidgets(
    'turnover rows expose total invoiced without profit calculations',
    (tester) async {
      await login(tester);
      await tapBottomDestination(tester, 'Turnover');
      await tester.pumpAndSettle();

      expect(find.text('Monthly Turnover'), findsWidgets);
      expect(find.text('No.'), findsWidgets);
      expect(find.text('Month'), findsWidgets);
      expect(find.text('Total Projects'), findsNothing);
      expect(find.text('Total Invoices'), findsWidgets);
      expect(find.text('Total Invoiced'), findsWidgets);
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.text('£940.00'), findsOneWidget);
      expect(find.text('Expenses'), findsNothing);
      expect(find.textContaining('Profit'), findsNothing);
      expect(find.textContaining('Loss'), findsNothing);
    },
  );

  test('currency formatter supports international tenant currencies', () {
    expect(moneyFromMinorUnits(12000, currency: 'GBP'), '£120.00');
    expect(moneyFromMinorUnits(12000, currency: 'USD'), r'$120.00');
    expect(moneyFromMinorUnits(12000, currency: 'NGN'), '₦120.00');
    expect(moneyFromMinorUnits(12000, currency: 'KES'), 'KSh 120.00');
    expect(moneyFromMinorUnits(12000, currency: 'XYZ'), 'XYZ 120.00');
  });

  testWidgets('repeated reminder create and cancel keeps screen usable', (
    tester,
  ) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(MaterialApp(home: RemindersScreen(api: api)));
    await tester.pumpAndSettle();

    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byKey(const Key('addReminderButton')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('New reminder'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancelAddReminder')));
      await tester.pumpAndSettle();
      expect(find.text('New reminder'), findsNothing);
      expect(tester.takeException(), isNull);
    }

    expect(api.reminders, hasLength(1));
    expect(find.byKey(const Key('addReminderButton')), findsOneWidget);
  });

  testWidgets('settings logout returns to login', (tester) async {
    final api = await login(tester);
    await openSettingsHub(tester);
    await tapMoreCard(tester, const Key('moreSettings'));
    expect(find.text('Settings'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('logoutButton')),
      300,
      scrollable: scrollableByKey(const Key('settingsScroll')),
    );
    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();
    expect(api.session, isFalse);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
  });

  testWidgets('more screen opens polished module menu', (tester) async {
    await login(tester);
    await openSettingsHub(tester);
    expect(find.byKey(const Key('moreCompanyProfile')), findsOneWidget);
    await expectMoreCardVisible(tester, const Key('moreTeam'));

    await expectMoreCardVisible(tester, const Key('moreNotifications'));
    await expectMoreCardVisible(tester, const Key('moreInvoices'));
    await expectMoreCardVisible(tester, const Key('moreJobsProjects'));
    await expectMoreCardVisible(tester, const Key('moreDocuments'));
    await expectMoreCardVisible(tester, const Key('moreRevenue'));
    await expectMoreCardVisible(tester, const Key('moreTasks'));
    await expectMoreCardVisible(tester, const Key('moreReminders'));
    await expectMoreCardVisible(tester, const Key('moreAbout'));
  });

  testWidgets(
    'commercial account pages show session plan role and company data',
    (tester) async {
      await login(tester, role: CommercialRole.admin);
      await openSettingsHub(tester);

      await tapMoreCard(tester, const Key('moreCompanyProfile'));
      expect(find.text('Company Profile'), findsWidgets);
      expect(find.text('Northstar Studio'), findsWidgets);
      expect(find.text('Read-only on mobile'), findsOneWidget);
      await popPushedScreen(tester);

      await tapMoreCard(tester, const Key('moreBranding'));
      expect(find.byKey(const Key('brandingPreviewCard')), findsOneWidget);
      expect(find.text('Accent #147DE8'), findsOneWidget);
      await popPushedScreen(tester);

      await tapMoreCard(tester, const Key('morePlanAccount'));
      expect(find.text('Plan & Account'), findsWidgets);
      expect(find.text('Pilot'), findsWidgets);
      expect(find.text('Team members'), findsOneWidget);
    },
  );

  testWidgets('feature access page shows locked entitlement state', (
    tester,
  ) async {
    final api = FakeCrmApi()..sessionRole = CommercialRole.admin;
    await api.login(email: 'admin@example.test', password: 'secret');
    await tester.pumpWidget(MaterialApp(home: FeatureAccessScreen(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('Feature Access'), findsWidgets);
    expect(
      find.text('Advanced branding requires a future plan upgrade.'),
      findsOneWidget,
    );
    expect(find.text('Locked'), findsOneWidget);
  });

  testWidgets('team foundation opens for owner and admin roles', (
    tester,
  ) async {
    final api = FakeCrmApi()..sessionRole = CommercialRole.admin;
    await api.login(email: 'admin@example.test', password: 'secret');
    await tester.pumpWidget(MaterialApp(home: TeamFoundationScreen(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('Team management foundation'), findsOneWidget);
    expect(find.text('Owner/Admin visibility prepared'), findsOneWidget);
  });

  testWidgets(
    'staff keeps management screens hidden but can view own account',
    (tester) async {
      final api = await login(tester, role: CommercialRole.staff);
      await openSettingsHub(tester);

      expect(find.byKey(const Key('moreCompanyProfile')), findsNothing);
      expect(find.byKey(const Key('moreCompanySettings')), findsNothing);
      expect(find.byKey(const Key('moreTeam')), findsNothing);

      await tester.pumpWidget(MaterialApp(home: MyProfileScreen(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('My Profile'), findsWidgets);
      expect(find.text('Daphnex User'), findsOneWidget);
      expect(find.text('staff'), findsWidgets);
    },
  );

  testWidgets(
    'commercial root tabs and settings shortcuts open nested screens',
    (tester) async {
      final api = await login(tester);

      await tapBottomDestination(tester, 'Clients');
      expect(find.byKey(const Key('clientSearch')), findsOneWidget);

      await tapBottomDestination(tester, 'Reminders');
      expect(find.text('Reminders'), findsWidgets);

      await tapBottomDestination(tester, 'Outstanding');
      expect(find.text('Outstanding balance'), findsWidgets);

      await tapBottomDestination(tester, 'Turnover');
      expect(find.text('Monthly Turnover'), findsWidgets);

      await tester.pumpWidget(MaterialApp(home: JobsScreen(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('1. Website maintenance'), findsOneWidget);

      await tester.pumpWidget(MaterialApp(home: InvoicesScreen(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('INV-2026-0001'), findsOneWidget);

      await tester.pumpWidget(MaterialApp(home: DocumentsScreen(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('Signed Agreement'), findsOneWidget);
    },
  );

  testWidgets('staff More navigation hides management destinations', (
    tester,
  ) async {
    await login(tester, role: CommercialRole.staff);
    await openSettingsHub(tester);

    expect(find.byKey(const Key('moreCompanyProfile')), findsNothing);
    expect(find.byKey(const Key('moreBranding')), findsNothing);
    expect(find.byKey(const Key('moreTeam')), findsNothing);
    expect(find.text('Management restricted'), findsOneWidget);
    expect(find.byKey(const Key('moreNotifications')), findsOneWidget);
  });

  testWidgets('admin More navigation shows management foundations', (
    tester,
  ) async {
    await login(tester, role: CommercialRole.admin);
    await openSettingsHub(tester);

    expect(find.byKey(const Key('moreCompanyProfile')), findsOneWidget);
    expect(find.byKey(const Key('moreBranding')), findsOneWidget);
    await expectMoreCardVisible(tester, const Key('moreTeam'));
  });
}

class _FakeDocumentPicker implements DocumentPickerService {
  const _FakeDocumentPicker();

  @override
  Future<PickedCrmDocument?> pickDocument() async {
    return const PickedCrmDocument(
      filePath: r'C:\temp\agreement.pdf',
      fileName: 'agreement.pdf',
      mimeType: 'application/pdf',
      fileSize: 1024,
    );
  }
}
