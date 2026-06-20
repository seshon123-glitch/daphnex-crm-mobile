import 'package:daphnex_crm_mobile/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> login(WidgetTester tester) async {
    await tester.pumpWidget(const DaphnexCrmApp());
    expect(find.text('Welcome to Daphnex'), findsOneWidget);
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();
  }

  testWidgets('login opens the dashboard', (tester) async {
    await login(tester);
    expect(find.text('Business overview'), findsOneWidget);
    expect(find.text('Total Clients'), findsOneWidget);
  });

  testWidgets('client search and profile navigation work', (tester) async {
    await login(tester);
    await tester.tap(find.text('Clients'));
    await tester.pumpAndSettle();
    expect(find.text('Olivia Bennett'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('clientSearch')), 'Brightline');
    await tester.pump();
    expect(find.text('Marcus Chen'), findsOneWidget);
    expect(find.text('Olivia Bennett'), findsNothing);
    await tester.tap(find.text('Marcus Chen'));
    await tester.pumpAndSettle();
    expect(find.text('Client profile'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recent activity'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Recent activity'), findsOneWidget);
  });

  testWidgets('reminders can be completed', (tester) async {
    await login(tester);
    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reminder-0')));
    await tester.pump();
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('settings loads and logout returns to login', (tester) async {
    await login(tester);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('App version'), findsOneWidget);
    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Daphnex'), findsOneWidget);
  });
}
