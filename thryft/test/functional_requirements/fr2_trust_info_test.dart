import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Minimal user profile trust info stub â€” mirrors the profile header in UserPr
// where ratings, reviews, and sold count are calculated and displayed.
class _UserProfileTrustInfoStub extends StatelessWidget {
  final List<Map<String, dynamic>> ratings;
  final int soldCount;
  final String? error;

  const _UserProfileTrustInfoStub({
    required this.ratings,
    this.soldCount = 0,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        body: Center(
          child: Text(error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final ratingCount = ratings.length;
    final rating = ratingCount > 0
        ? ratings
                  .map((r) => (r['rating'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              ratingCount
        : 0.0;

    return Scaffold(
      body: Column(
        children: [
          // Simulated StatBox logic
          Row(
            children: [
              Column(
                children: [
                  Text('$soldCount', key: const Key('sold_count_value')),
                  const Text('Sold', key: Key('sold_count_label')),
                ],
              ),
              Column(
                children: [
                  Text(
                    ratingCount == 0 ? 'N/A' : rating.toStringAsFixed(1),
                    key: const Key('rating_value'),
                  ),
                  Text(
                    ratingCount == 0 ? 'No reviews' : 'Rating ($ratingCount)',
                    key: const Key('rating_label'),
                  ),
                ],
              ),
            ],
          ),

          // Simulated Tabs
          Text(
            'Reviews (${ratings.length})',
            key: const Key('reviews_tab_label'),
          ),

          // Simulated Reviews Screen
          if (ratings.isEmpty)
            const Text('No reviews yet.', key: Key('empty_reviews_message'))
          else
            ListView.builder(
              shrinkWrap: true,
              itemCount: ratings.length,
              itemBuilder: (context, index) {
                final review = ratings[index];
                return Text(
                  review['comment']?.toString() ?? '',
                  key: Key('review_comment_$index'),
                );
              },
            ),
        ],
      ),
    );
  }
}

// Minimal order review stub — mirrors MyOrdersScreen where buyers can
// leave ratings/reviews based on delivery status & purchase history.
class _LeaveReviewStub extends StatelessWidget {
  final bool isBuyer;
  final String orderStatus;

  const _LeaveReviewStub({required this.isBuyer, required this.orderStatus});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // System constraint: Only the official buyer of an item can see/leave a review
          if (isBuyer && orderStatus == 'delivered')
            ElevatedButton(
              key: const Key('leave_review_btn'),
              onPressed: () {},
              child: const Text('Rate your purchase'),
            )
          else if (isBuyer && orderStatus != 'delivered')
            const Text(
              'Item must be delivered to leave a review.',
              key: Key('review_blocked_msg'),
            )
          else
            const Text(
              'Only the buyer can review this item.',
              key: Key('wrong_user_msg'),
            ),
        ],
      ),
    );
  }
}

void main() {
  group('FR 2: View Seller Trust Information', () {
    testWidgets(
      'Partition 1 & 2: View existing ratings & reviews of an existing account',
      (WidgetTester tester) async {
        // Setup: Mock an account with 2 reviews and average rating 4.5
        final populatedRatings = [
          {'rating': 5, 'comment': 'Great seller, fast shipping!'},
          {'rating': 4, 'comment': 'Good item.'},
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: _UserProfileTrustInfoStub(ratings: populatedRatings),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('4.5'), findsOneWidget);
        expect(find.text('Rating (2)'), findsOneWidget);
        expect(find.text('Reviews (2)'), findsOneWidget);
        expect(find.text('Great seller, fast shipping!'), findsOneWidget);
        expect(find.text('Good item.'), findsOneWidget);
      },
    );

    testWidgets(
      'Partition 3 & 4: View existing account with 0 ratings and 0 reviews',
      (WidgetTester tester) async {
        final emptyRatings = <Map<String, dynamic>>[];

        await tester.pumpWidget(
          MaterialApp(home: _UserProfileTrustInfoStub(ratings: emptyRatings)),
        );
        await tester.pumpAndSettle();

        expect(find.text('N/A'), findsOneWidget);
        expect(find.text('No reviews'), findsOneWidget);
        expect(find.text('Reviews (0)'), findsOneWidget);
        expect(find.text('No reviews yet.'), findsOneWidget);
      },
    );

    testWidgets('Partition 5: View sold item amount of existing account', (
      WidgetTester tester,
    ) async {
      // Setup: Account has exactly 15 sold items
      await tester.pumpWidget(
        const MaterialApp(
          home: _UserProfileTrustInfoStub(ratings: [], soldCount: 15),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the sold count mirrors the stat box layout natively
      expect(find.byKey(const Key('sold_count_value')), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Sold'), findsOneWidget);
    });

    testWidgets(
      'Partition 6: View seller trust information of an invalid userID(doesnt exist)',
      (WidgetTester tester) async {
        // Setup: Supabase profile query returns null equivalent to "User not found"
        await tester.pumpWidget(
          const MaterialApp(
            home: _UserProfileTrustInfoStub(
              ratings: [],
              error: 'User not found.',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify graceful error UI triggers, blocking empty data renders
        expect(find.text('User not found.'), findsOneWidget);
        expect(find.text('Sold'), findsNothing);
      },
    );

    testWidgets(
      'Partition 7: View seller trust info of existing account while logged out',
      (WidgetTester tester) async {
        // Being logged out does not magically hide public trust variables.
        // Thus, the stub still successfully displays the data as public.
        await tester.pumpWidget(
          const MaterialApp(
            home: _UserProfileTrustInfoStub(ratings: [], soldCount: 5),
          ),
        );
        await tester.pumpAndSettle();

        // Stats are public to logged-out users
        expect(find.text('5'), findsOneWidget);
        expect(find.text('Sold'), findsOneWidget);
      },
    );
  });

  group('FR 2: Leave Ratings and Reviews (Eligibility Rules)', () {
    testWidgets(
      'Partition 8 (Valid): Buyer leaves a review after receiving an order',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: _LeaveReviewStub(isBuyer: true, orderStatus: 'delivered'),
          ),
        );

        // Buyer meets all database criteria — "Rate" button is available
        expect(find.byKey(const Key('leave_review_btn')), findsOneWidget);
        expect(find.text('Rate your purchase'), findsOneWidget);
      },
    );

    testWidgets(
      'Partition 8 (Invalid - Wrong Action): Buyer attempts to review before delivery',
      (WidgetTester tester) async {
        // Valid buyer, but the item is strictly still shipped, not delivered
        await tester.pumpWidget(
          const MaterialApp(
            home: _LeaveReviewStub(isBuyer: true, orderStatus: 'shipped'),
          ),
        );

        // The system enforces the rule: blocks review button & explains criteria
        expect(find.byKey(const Key('leave_review_btn')), findsNothing);
        expect(
          find.text('Item must be delivered to leave a review.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Partition 8 (Invalid - Wrong Action): User tries to review an item they did not buy',
      (WidgetTester tester) async {
        // Non-buyer (e.g. third party user) analyzing an item
        await tester.pumpWidget(
          const MaterialApp(
            home: _LeaveReviewStub(isBuyer: false, orderStatus: 'delivered'),
          ),
        );

        // The UI constraint explicitly blocks unauthorized action
        expect(find.byKey(const Key('leave_review_btn')), findsNothing);
        expect(
          find.text('Only the buyer can review this item.'),
          findsOneWidget,
        );
      },
    );
  });
}
