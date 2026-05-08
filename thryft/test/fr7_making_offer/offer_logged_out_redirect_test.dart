import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal widget that mimics product detail 'Make an offer' behaviour when
/// the user is logged out: shows a SnackBar prompting login.
class _MakeOfferButton extends StatelessWidget {
  final bool loggedIn;
  const _MakeOfferButton({required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      key: const Key('make_offer_btn'),
      onPressed: () {
        if (!loggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to make an offer')),
          );
        }
      },
      child: const Text('Make an offer'),
    );
  }
}

void main() {
  group('FR7 Partition 5 — Logged-out behavior', () {
    testWidgets('tapping Make an offer when logged out shows login SnackBar',
        (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _MakeOfferButton(loggedIn: false))));

      await tester.tap(find.byKey(const Key('make_offer_btn')));
      await tester.pump();

      expect(find.text('Please log in to make an offer'), findsOneWidget);
    });
  });
}
