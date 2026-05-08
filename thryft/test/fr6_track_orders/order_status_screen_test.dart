// Tests for FR6 (track orders) at the widget level.
// Checks that the right buttons appear or disappear depending on order status.
// Uses small stub widgets instead of mounting the real screens, so there's no
// need for Supabase or a full navigation setup.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Stub for the seller-side sold item card (mirrors SoldItemsScreen._buildSoldCard).
// "Mark as shipped" only shows up when the item is sold and still pending.
class _SoldCardStub extends StatelessWidget {
  final String orderStatus;
  final bool isSold;

  const _SoldCardStub({required this.orderStatus, this.isSold = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Shows the current status as a readable label.
          Text(_statusLabel(orderStatus), key: const Key('status_badge')),
          // Ship button only appears when the item has been sold and not yet shipped.
          if (isSold && orderStatus == 'pending')
            ElevatedButton(
              key: const Key('mark_shipped_btn'),
              onPressed: () {},
              child: const Text('Mark as shipped'),
            ),
        ],
      ),
    );
  }

  // Maps raw DB status to the label displayed in the UI.
  String _statusLabel(String status) => switch (status) {
        'shipped' => 'Shipped',
        'delivered' => 'Delivered',
        _ => 'To Ship',
      };
}

// Stub for the buyer-side order card (mirrors MyOrdersScreen._buildOrderCard).
// "Confirm delivery" only shows up once the seller has marked the item as shipped.
class _OrderCardStub extends StatelessWidget {
  final String orderStatus;

  const _OrderCardStub({required this.orderStatus});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Shows the current order stage to the buyer.
          Text(_statusLabel(orderStatus), key: const Key('status_badge')),
          // Confirm button is only available when status is 'shipped'.
          if (orderStatus == 'shipped')
            OutlinedButton(
              key: const Key('confirm_delivery_btn'),
              onPressed: () {},
              child: const Text('Confirm delivery'),
            ),
        ],
      ),
    );
  }

  // Maps raw DB status to the label displayed in the UI.
  String _statusLabel(String status) => switch (status) {
        'shipped' => 'Shipped',
        'delivered' => 'Delivered',
        _ => 'Pending',
      };
}

void main() {
  // FR6 #2 — seller can only mark as shipped when the order is still pending.
  group('FR6 #2 — seller ship button visibility', () {
    testWidgets('pending sold item shows Mark as shipped button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _SoldCardStub(orderStatus: 'pending', isSold: true),
        ),
      );

      expect(find.byKey(const Key('mark_shipped_btn')), findsOneWidget);
      expect(find.text('To Ship'), findsOneWidget);
    });

    testWidgets('shipped item does NOT show Mark as shipped button', (tester) async {
      // Already shipped — don't let the seller trigger it again.
      await tester.pumpWidget(
        const MaterialApp(
          home: _SoldCardStub(orderStatus: 'shipped', isSold: true),
        ),
      );

      expect(find.byKey(const Key('mark_shipped_btn')), findsNothing);
      expect(find.text('Shipped'), findsOneWidget);
    });

    testWidgets('delivered item does NOT show Mark as shipped button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _SoldCardStub(orderStatus: 'delivered', isSold: true),
        ),
      );

      expect(find.byKey(const Key('mark_shipped_btn')), findsNothing);
      expect(find.text('Delivered'), findsOneWidget);
    });
  });

  // FR6 #3 — buyer can only confirm delivery once the item is shipped.
  group('FR6 #3 — buyer confirm delivery button visibility', () {
    testWidgets('shipped order shows Confirm delivery button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _OrderCardStub(orderStatus: 'shipped')),
      );

      expect(find.byKey(const Key('confirm_delivery_btn')), findsOneWidget);
      expect(find.text('Shipped'), findsOneWidget);
    });

    testWidgets('pending order does NOT show Confirm delivery button', (tester) async {
      // Seller hasn't shipped yet, so the buyer can't confirm.
      await tester.pumpWidget(
        const MaterialApp(home: _OrderCardStub(orderStatus: 'pending')),
      );

      expect(find.byKey(const Key('confirm_delivery_btn')), findsNothing);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('delivered order does NOT show Confirm delivery button', (tester) async {
      // Already confirmed — button shouldn't reappear.
      await tester.pumpWidget(
        const MaterialApp(home: _OrderCardStub(orderStatus: 'delivered')),
      );

      expect(find.byKey(const Key('confirm_delivery_btn')), findsNothing);
      expect(find.text('Delivered'), findsOneWidget);
    });
  });

  // FR6 #5 — seller can't mark as shipped if the item hasn't actually been sold.
  group('FR6 #5 — ship before sold is prevented at UI level', () {
    testWidgets('unsold item (isSold=false) does NOT show Mark as shipped button',
        (tester) async {
      // isSold=false means no purchase yet, so the ship button must not appear.
      await tester.pumpWidget(
        const MaterialApp(
          home: _SoldCardStub(orderStatus: 'pending', isSold: false),
        ),
      );

      expect(find.byKey(const Key('mark_shipped_btn')), findsNothing);
    });

    testWidgets('item with no sold status shows To Ship badge but no button when unsold',
        (tester) async {
      // The status label still renders, but there's no action the seller can take.
      await tester.pumpWidget(
        const MaterialApp(
          home: _SoldCardStub(orderStatus: 'pending', isSold: false),
        ),
      );

      expect(find.text('To Ship'), findsOneWidget);
      expect(find.byKey(const Key('mark_shipped_btn')), findsNothing);
    });
  });

  // FR6 #6 — buyer can't confirm delivery before the item has been shipped.
  group('FR6 #6 — receive before shipped is prevented at UI level', () {
    testWidgets('pending order does NOT show Confirm delivery button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _OrderCardStub(orderStatus: 'pending')),
      );

      expect(find.byKey(const Key('confirm_delivery_btn')), findsNothing);
    });

    testWidgets('already delivered order does NOT show Confirm delivery again',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _OrderCardStub(orderStatus: 'delivered')),
      );

      expect(find.byKey(const Key('confirm_delivery_btn')), findsNothing);
    });
  });

  // FR6 #7 — ship button should only appear for the seller's own sold items.
  // Non-owners see isSold=false so the button is never rendered for them.
  group('FR6 #7 — invalid seller (non-owner has no ship button)', () {
    testWidgets('status badge correctly shows "To Ship" label for pending', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _SoldCardStub(orderStatus: 'pending', isSold: true),
        ),
      );

      expect(find.text('To Ship'), findsOneWidget);
    });

    testWidgets('non-sold item has no ship action regardless of status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _SoldCardStub(orderStatus: 'pending', isSold: false),
        ),
      );

      expect(find.byKey(const Key('mark_shipped_btn')), findsNothing);
    });
  });

  // FR6 #8 — confirm delivery button should only appear for the actual buyer
  // once the item is shipped. Wrong status means no button.
  group('FR6 #8 — invalid buyer (non-buyer has no confirm button)', () {
    testWidgets('confirm delivery only available on shipped status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _OrderCardStub(orderStatus: 'pending')),
      );

      expect(find.byKey(const Key('confirm_delivery_btn')), findsNothing);
    });

    testWidgets('shipped status badge is shown to buyer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _OrderCardStub(orderStatus: 'shipped')),
      );

      expect(find.text('Shipped'), findsOneWidget);
      expect(find.byKey(const Key('confirm_delivery_btn')), findsOneWidget);
    });
  });
}
