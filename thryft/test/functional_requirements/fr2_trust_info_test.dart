import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Minimal user profile trust info stub — mirrors the profile header in UserProfileScreen
// where ratings are calculated and displayed.
class _UserProfileTrustInfoStub extends StatelessWidget {
  final List<Map<String, dynamic>> ratings;

  const _UserProfileTrustInfoStub({required this.ratings});

  @override
  Widget build(BuildContext context) {
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
          // Simulated StatBox
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

void main() {
  group('FR 2: View Seller Trust Information', () {
    testWidgets(
      'Partition 1 & 2: View existing ratings & reviews of an existing account',
      (WidgetTester tester) async {
        // Setup: Mock an account with 2 reviews and  average rating  4.5
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

        // Rating is calculated and displayed like UserProfileScreen
        expect(find.text('4.5'), findsOneWidget); 
        expect(find.text('Rating (2)'), findsOneWidget); 

        // Verify Reviews tab header
        expect(find.text('Reviews (2)'), findsOneWidget);

        // Verify individual reviews are dynamically rendered
        expect(find.text('Great seller, fast shipping!'), findsOneWidget);
        expect(find.text('Good item.'), findsOneWidget);
      },
    );

    testWidgets(
      'Partition 3 & 4: View existing account with 0 ratings and 0 reviews',
      (WidgetTester tester) async {
        // Setup: Mock a brand new account with empty ratings
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
  });
}
