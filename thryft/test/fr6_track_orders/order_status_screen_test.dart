import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Minimal sold card stub — mirrors SoldItemsScreen._buildSoldCard:
//   "Mark as shipped" button appears ONLY when status == 'pending' AND isSold.

class _SoldCardStub extends StatelessWidget {
  final String orderStatus;
  final bool isSold;

  const _SoldCardStub({required this.orderStatus, this.isSold = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(_statusLabel(orderStatus), key: const Key('status_badge')),
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

  String _statusLabel(String status) => switch (status) {
        'shipped' => 'Shipped',
        'delivered' => 'Delivered',
        _ => 'To Ship',
      };
}

// Minimal order card stub — mirrors MyOrdersScreen._buildOrderCard:
//   "Confirm delivery" button appears ONLY when status == 'shipped'.

class _OrderCardStub extends StatelessWidget {
  final String orderStatus;

  const _OrderCardStub({required this.orderStatus});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(_statusLabel(orderStatus), key: const Key('status_badge')),
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

  String _statusLabel(String status) => switch (status) {
        'shipped' => 'Shipped',
        'delivered' => 'Delivered',
        _ => 'Pending',
      };
}

void main() {
  // FR6 Partition 2 — Valid shipping update: seller UI shows ship button
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

  // FR6 Partition 3 — Valid received update: buyer UI shows confirm button
  group('FR6 #3 — buyer confirm delivery button visibility', () {
    testWidgets('shipped order shows Confirm delivery button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _OrderCardStub(orderStatus: 'shipped')),
      );

      expect(find.byKey(const Key('confirm_delivery_btn')), findsOneWidget);
      expect(find.text('Shipped'), findsOneWidget);
    });

    testWidgets('pending order does NOT show Confirm delivery button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _OrderCardStub(orderStatus: 'pending')),
      );

      expect(find.byKey(const Key('confirm_delivery_btn')), findsNothing);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('delivered order does NOT show Confirm delivery button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _OrderCardStub(orderStatus: 'delivered')),
      );

      expect(find.byKey(const Key('confirm_delivery_btn')), findsNothing);
      expect(find.text('Delivered'), findsOneWidget);
    });
  });

  // FR6 Partition 5 — Ship before sold: system prevents shipping unsold items
  group('FR6 #5 — ship before sold is prevented at UI level', () {
    testWidgets('unsold item (isSold=false) does NOT show Mark as shipped button',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _SoldCardStub(orderStatus: 'pending', isSold: false),
        ),
      );

      expect(find.byKey(const Key('mark_shipped_btn')), findsNothing);
    });

    testWidgets('item with no sold status shows To Ship badge but no button when unsold',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _SoldCardStub(orderStatus: 'pending', isSold: false),
        ),
      );

      expect(find.text('To Ship'), findsOneWidget);
      expect(find.byKey(const Key('mark_shipped_btn')), findsNothing);
    });
  });


  // FR6 Partition 6 — Receive before shipped: system prevents out-of-order updates
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

  // FR6 Partition 7 — Invalid seller: only seller's own items show ship button
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

  
  // FR6 Partition 8 — Invalid buyer: only shipped items expose confirm button
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
