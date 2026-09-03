import 'package:daphnex_crm_mobile/app.dart';
import 'package:daphnex_crm_mobile/core/errors/api_exception.dart';
import 'package:daphnex_crm_mobile/features/documents/documents_screen.dart';
import 'package:daphnex_crm_mobile/models/commercial_session.dart';
import 'package:daphnex_crm_mobile/models/dashboard_data.dart';
import 'package:daphnex_crm_mobile/services/document_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_crm_api.dart';

void main() {
  Finder scrollableByKey(Key key) {
    return find
        .descendant(of: find.byKey(key), matching: find.byType(Scrollable))
        .first;
  }

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
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('commercialBottomNavigation')),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openWorkHub(WidgetTester tester) async {
    await tapBottomDestination(tester, 'Work');
    expect(find.byKey(const Key('workClientsCard')), findsOneWidget);
  }

  Future<void> tapWorkCard(WidgetTester tester, Key key) async {
    await tester.scrollUntilVisible(
      find.byKey(key),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    if (key != const Key('workClientsCard')) {
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -160));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Future<void> tapMoreCard(WidgetTester tester, Key key) async {
    await tester.scrollUntilVisible(
      find.byKey(key),
      260,
      scrollable: scrollableByKey(const Key('moreScroll')),
    );
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Future<void> expectMoreCardVisible(WidgetTester tester, Key key) async {
    await tester.scrollUntilVisible(
      find.byKey(key),
      240,
      scrollable: scrollableByKey(const Key('moreScroll')),
    );
    expect(find.byKey(key), findsOneWidget);
  }

  Future<void> popPushedScreen(WidgetTester tester) async {
    Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
    await tester.pumpAndSettle();
  }

  testWidgets('live login opens dashboard values', (tester) async {
    final api = await login(tester);
    expect(api.lastLoginEmail, 'admin@example.test');
    expect(find.byKey(const Key('dashboardHeader')), findsOneWidget);
    expect(find.text('Northstar Studio'), findsWidgets);
    expect(find.textContaining('Daphnex'), findsOneWidget);
    expect(find.byKey(const Key('commercialBottomNavigation')), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.byKey(const Key('needsAttentionSection')), findsOneWidget);
    expect(find.text('Invoices need attention'), findsOneWidget);
    expect(find.text('Tasks due soon'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('kpiSection')),
      300,
      scrollable: scrollableByKey(const Key('dashboardScroll')),
    );
    expect(find.byKey(const Key('kpiSection')), findsOneWidget);
    expect(find.text('KPI Summary'), findsOneWidget);
    expect(find.text('Clients'), findsWidgets);
    expect(find.text('Active Jobs'), findsOneWidget);
    expect(find.text('Outstanding'), findsOneWidget);
    expect(find.text('£150'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const Key('quickActionsSection')),
      300,
      scrollable: scrollableByKey(const Key('dashboardScroll')),
    );
    expect(find.text('Quick Actions'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('recentActivitySection')),
      300,
      scrollable: scrollableByKey(const Key('dashboardScroll')),
    );
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('Follow up with Olivia'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const Key('financeSummarySection')),
      300,
      scrollable: scrollableByKey(const Key('dashboardScroll')),
    );
    expect(find.text('Revenue / Finance Summary'), findsOneWidget);
  });

  testWidgets('empty dashboard still gives useful first-use state', (
    tester,
  ) async {
    final api = FakeCrmApi()
      ..dashboardData = const DashboardData(
        totalClients: 0,
        activeJobs: 0,
        pendingInvoices: 0,
        upcomingReminders: 0,
      )
      ..notifications.clear();

    await login(tester, api: api);

    expect(find.text('Nothing urgent right now.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('recentActivitySection')),
      300,
      scrollable: scrollableByKey(const Key('dashboardScroll')),
    );
    expect(find.text('No recent activity yet.'), findsOneWidget);
    expect(find.text('Clients'), findsWidgets);
    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Invoices'), findsWidgets);
    expect(find.text('Jobs / Projects'), findsWidgets);
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

    await login(tester, api: api);

    expect(find.byKey(const Key('dashboardHeader')), findsOneWidget);
    expect(find.textContaining('Northstar Commercial'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('£9876543'),
      300,
      scrollable: scrollableByKey(const Key('dashboardScroll')),
    );
    expect(find.text('£9876543'), findsWidgets);
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

  testWidgets('clients search and live profile work', (tester) async {
    await login(tester);
    await openWorkHub(tester);
    await tapWorkCard(tester, const Key('workClientsCard'));
    await tester.enterText(find.byKey(const Key('clientSearch')), 'Brightline');
    await tester.pump();
    expect(find.text('Marcus Chen'), findsOneWidget);
    expect(find.text('Olivia Bennett'), findsNothing);
    await tester.tap(find.text('Marcus Chen'));
    await tester.pumpAndSettle();
    expect(find.text('Client profile'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('No recent activity.'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('No recent activity.'), findsOneWidget);
  });

  testWidgets('client create and edit use live API methods', (tester) async {
    final api = await login(tester);
    await openWorkHub(tester);
    await tapWorkCard(tester, const Key('workClientsCard'));
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
    await tester.tap(find.byKey(const Key('saveClientForm')));
    await tester.pumpAndSettle();
    expect(api.clients, hasLength(3));
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
  });

  testWidgets('reminder completion calls API and updates UI', (tester) async {
    final api = await login(tester);
    await openWorkHub(tester);
    await tapWorkCard(tester, const Key('workRemindersCard'));
    await tester.tap(find.byKey(const Key('reminder-1')));
    await tester.pumpAndSettle();
    expect(api.completedReminderId, 1);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('add reminder posts and refreshes list', (tester) async {
    final api = await login(tester);
    await openWorkHub(tester);
    await tapWorkCard(tester, const Key('workRemindersCard'));
    await tester.tap(find.byKey(const Key('addReminderButton')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(
      find.byKey(const Key('newReminderField')),
      'Mobile API reminder',
    );
    await tester.tap(find.byKey(const Key('confirmAddReminder')));
    await tester.pumpAndSettle();
    expect(api.reminders.length, 2);
    expect(api.fetchRemindersCalls, 2);
    expect(find.text('New reminder'), findsNothing);
    expect(find.text('Mobile API reminder'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await openWorkHub(tester);
    await tapWorkCard(tester, const Key('workRemindersCard'));
    expect(find.text('Mobile API reminder'), findsOneWidget);
  });

  testWidgets('job and invoice creation use client selectors', (tester) async {
    final api = await login(tester);

    await openWorkHub(tester);
    await tapWorkCard(tester, const Key('workProjectsCard'));
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
    expect(find.text('Mobile rollout'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapBottomDestination(tester, 'Finance');
    await tester.tap(find.byKey(const Key('financeInvoicesCard')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createInvoiceButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invoiceClientField')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('invoiceDescriptionField')),
      'Mobile support',
    );
    await tester.enterText(find.byKey(const Key('invoiceAmountField')), '250');
    await tester.tap(find.text('Create').last);
    await tester.pumpAndSettle();
    expect(api.invoices, hasLength(2));
    expect(find.text('INV-TEST-2'), findsOneWidget);
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

  testWidgets('repeated reminder create and cancel keeps screen usable', (
    tester,
  ) async {
    final api = await login(tester);
    await openWorkHub(tester);
    await tapWorkCard(tester, const Key('workRemindersCard'));

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
    await tapBottomDestination(tester, 'More');
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
    await tapBottomDestination(tester, 'More');
    expect(find.byKey(const Key('moreCompanyProfile')), findsOneWidget);
    expect(find.byKey(const Key('moreTeam')), findsOneWidget);

    await expectMoreCardVisible(tester, const Key('moreNotifications'));
    await expectMoreCardVisible(tester, const Key('moreInvoices'));
    await expectMoreCardVisible(tester, const Key('moreJobsProjects'));
    await expectMoreCardVisible(tester, const Key('moreDocuments'));
    await expectMoreCardVisible(tester, const Key('moreRevenue'));
    await expectMoreCardVisible(tester, const Key('moreTasks'));
    await expectMoreCardVisible(tester, const Key('moreAbout'));
  });

  testWidgets(
    'commercial account pages show session plan role and company data',
    (tester) async {
      await login(tester, role: CommercialRole.admin);
      await tapBottomDestination(tester, 'More');

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
    await login(tester, role: CommercialRole.admin);
    await tapBottomDestination(tester, 'More');
    await tapMoreCard(tester, const Key('moreFeatureAccess'));

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
    await login(tester, role: CommercialRole.admin);
    await tapBottomDestination(tester, 'More');
    await tapMoreCard(tester, const Key('moreTeam'));

    expect(find.text('Team management foundation'), findsOneWidget);
    expect(find.text('Owner/Admin visibility prepared'), findsOneWidget);
  });

  testWidgets(
    'staff keeps management screens hidden but can view own account',
    (tester) async {
      await login(tester, role: CommercialRole.staff);
      await tapBottomDestination(tester, 'More');

      expect(find.byKey(const Key('moreCompanyProfile')), findsNothing);
      expect(find.byKey(const Key('moreCompanySettings')), findsNothing);
      expect(find.byKey(const Key('moreTeam')), findsNothing);

      await tapMoreCard(tester, const Key('moreMyProfile'));
      expect(find.text('My Profile'), findsWidgets);
      expect(find.text('Daphnex User'), findsOneWidget);
      expect(find.text('staff'), findsWidgets);
    },
  );

  testWidgets(
    'commercial root tabs open Work Finance Files and nested screens',
    (tester) async {
      await login(tester);

      await tapBottomDestination(tester, 'Work');
      expect(find.byKey(const Key('workClientsCard')), findsOneWidget);
      await tapWorkCard(tester, const Key('workProjectsCard'));
      expect(find.text('Website maintenance'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('workClientsCard')), findsOneWidget);

      await tapBottomDestination(tester, 'Finance');
      expect(find.text('Money in and money due'), findsOneWidget);
      await tester.tap(find.byKey(const Key('financeInvoicesCard')));
      await tester.pumpAndSettle();
      expect(find.text('INV-2026-0001'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tapBottomDestination(tester, 'Files');
      expect(find.text('Files'), findsWidgets);
      expect(find.byKey(const Key('filesDocumentsCard')), findsOneWidget);
      await tester.tap(find.byKey(const Key('filesDocumentsCard')));
      await tester.pumpAndSettle();
      expect(find.text('Signed Agreement'), findsOneWidget);
    },
  );

  testWidgets('staff More navigation hides management destinations', (
    tester,
  ) async {
    await login(tester, role: CommercialRole.staff);
    await tapBottomDestination(tester, 'More');

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
    await tapBottomDestination(tester, 'More');

    expect(find.byKey(const Key('moreCompanyProfile')), findsOneWidget);
    expect(find.byKey(const Key('moreBranding')), findsOneWidget);
    expect(find.byKey(const Key('moreTeam')), findsOneWidget);
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
