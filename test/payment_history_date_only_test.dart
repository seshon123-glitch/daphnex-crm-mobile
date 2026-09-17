import 'package:daphnex_crm_mobile/features/invoices/invoices_screen.dart';
import 'package:daphnex_crm_mobile/models/invoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_crm_api.dart';

void main() {
  testWidgets('Payment History preserves business date and hides time', (
    tester,
  ) async {
    for (final timestamp in [
      '2026-09-17',
      '2026-09-17 00:00:00',
      '2026-09-17T23:35:42-07:00',
    ]) {
      final api = FakeCrmApi();
      final invoice = Invoice.fromJson({
        'id': 1,
        'client_id': 1,
        'invoice_number': 'DATE-ONLY-1',
        'total_amount': 55000,
        'amount_paid': 15000,
        'balance': 40000,
        'status': 'part_paid',
        'payment_history': [
          {
            'id': 1,
            'amount': 15000,
            'paid_at': timestamp,
            'payment_method': 'bank_transfer',
            'payment_reference': 'DATE-ONLY-REF',
          },
        ],
      });
      api.invoices
        ..clear()
        ..add(invoice);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(home: InvoiceDetailScreen(api: api, invoice: invoice)),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('Payment Date:'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.text('Payment Date: 2026-09-17 · Bank Transfer · DATE-ONLY-REF'),
        findsOneWidget,
      );
      expect(find.textContaining('00:00'), findsNothing);
      expect(find.textContaining('23:35'), findsNothing);
      expect(find.text('£150.00'), findsWidgets);
      expect(invoice.payments.single.paidAt, timestamp);
      expect(invoice.payments.single.amount, 15000);
      expect(invoice.amountPaid, 15000);
      expect(invoice.totalAmount, 55000);
      expect(invoice.balance, 40000);
      expect(invoice.status, 'part_paid');
      expect(api.invoices.single, same(invoice));
    }
  });
}
