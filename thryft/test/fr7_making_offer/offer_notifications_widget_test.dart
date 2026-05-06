import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _OfferNotice {
  final String buyerId;
  final double offerPrice;
  const _OfferNotice({required this.buyerId, required this.offerPrice});
}

class _OfferNotificationsList extends StatelessWidget {
  final List<_OfferNotice> offers;
  const _OfferNotificationsList({required this.offers});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return ListTile(
              title: Text('Offer from ${offer.buyerId}'),
              subtitle: Text('Proposed price: ${offer.offerPrice.toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Accept'),
                  SizedBox(width: 8),
                  Text('Reject'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

void main() {
  group('FR7 widget behavior', () {
    testWidgets('multiple offers on same listing render as separate entries',
        (tester) async {
      await tester.pumpWidget(
        const _OfferNotificationsList(
          offers: [
            _OfferNotice(buyerId: 'buyer-1', offerPrice: 31),
            _OfferNotice(buyerId: 'buyer-2', offerPrice: 32),
            _OfferNotice(buyerId: 'buyer-3', offerPrice: 33),
          ],
        ),
      );

      expect(find.text('Offer from buyer-1'), findsOneWidget);
      expect(find.text('Offer from buyer-2'), findsOneWidget);
      expect(find.text('Offer from buyer-3'), findsOneWidget);
      expect(find.textContaining('Proposed price:'), findsNWidgets(3));
    });

    testWidgets('each row shows Accept and Reject actions', (tester) async {
      await tester.pumpWidget(
        const _OfferNotificationsList(
          offers: [
            _OfferNotice(buyerId: 'buyer-123', offerPrice: 35),
          ],
        ),
      );

      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });
  });
}
