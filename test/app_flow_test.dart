import 'package:daphnex_crm_mobile/app.dart';
import 'package:daphnex_crm_mobile/core/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_crm_api.dart';

void main() {
  Finder scrollableByKey(Key key) {
    return find
        .descendant(of: find.byKey(key), matching: find.byType(Scrollable))
        .first;
  }

  Future<FakeCrmApi> login(WidgetTester tester) async {
    final api = FakeCrmApi();
    await tester.pumpWidget(DaphnexCrmApp(api: api));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'admin@example.test',
    );
    await tester.enterText(find.byKey(const Key('passwordField')), 'secret');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();
    return api;
  }

  testWidgets('live login opens dashboard values', (tester) async {
    final api = await login(tester);
    expect(api.lastLoginEmail, 'admin@example.test');
    expect(find.text('Business overview'), findsOneWidget);
    expect(find.text('Total Clients'), findsOneWidget);
    expect(find.text('Active Jobs / Projects'), findsOneWidget);
    expect(find.text('Unread Alerts'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Quick actions'),
      300,
      scrollable: scrollableByKey(const Key('dashboardScroll')),
    );
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Turnover / Revenue'), findsWidgets);
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
    expect(
      find.textContaining('API base URL: ${ApiConfig.baseUrl}'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Endpoint called: ${ApiConfig.endpoint('login')}'),
      findsOneWidget,
    );
  });

  testWidgets('clients search and live profile work', (tester) async {
    await login(tester);
    await tester.tap(find.text('Clients'));
    await tester.pumpAndSettle();
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

  testWidgets('reminder completion calls API and updates UI', (tester) async {
    final api = await login(tester);
    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reminder-1')));
    await tester.pumpAndSettle();
    expect(api.completedReminderId, 1);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('add reminder posts and refreshes list', (tester) async {
    final api = await login(tester);
    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addReminderButton')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(
      find.byKey(const Key('newReminderField')),
      'Mobile API reminder',
    );
    await tester.tap(find.byKey(const Key('confirmAddReminder')));
    await tester.pumpAndSettle();
    expect(api.reminders.length, 2);
    expect(find.text('Mobile API reminder'), findsOneWidget);
  });

  testWidgets('settings logout returns to login', (tester) async {
    final api = await login(tester);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('logoutButton')),
      300,
      scrollable: scrollableByKey(const Key('settingsScroll')),
    );
    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();
    expect(api.session, isFalse);
    expect(find.text('Daphnex CRM'), findsOneWidget);
  });

  testWidgets('more screen opens polished module menu', (tester) async {
    await login(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Invoices'), findsWidgets);
    expect(find.text('Jobs / Projects'), findsWidgets);
    expect(find.text('Documents'), findsWidgets);

    await tester.tap(find.text('Invoices').last);
    await tester.pumpAndSettle();
    expect(find.text('INV-2026-0001'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jobs / Projects').last);
    await tester.pumpAndSettle();
    expect(find.text('Website maintenance'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Documents').last);
    await tester.pumpAndSettle();
    expect(find.text('Signed Agreement'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Notifications'),
      300,
      scrollable: scrollableByKey(const Key('moreScroll')),
    );
    expect(find.text('Notifications'), findsWidgets);
    await tester.tap(find.text('Notifications').last);
    await tester.pumpAndSettle();
    expect(find.text('Follow up with Olivia'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Turnover / Revenue'),
      300,
      scrollable: scrollableByKey(const Key('moreScroll')),
    );
    expect(find.text('Turnover / Revenue'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Tasks'),
      300,
      scrollable: scrollableByKey(const Key('moreScroll')),
    );
    expect(find.text('Tasks'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('About Daphnex CRM'),
      300,
      scrollable: scrollableByKey(const Key('moreScroll')),
    );
    expect(find.text('About Daphnex CRM'), findsWidgets);
  });
}
