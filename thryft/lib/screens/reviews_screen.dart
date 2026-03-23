import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReviewsScreen extends StatelessWidget {
  final List<dynamic> ratings;
  final String sellerId;
  final String sellerName;

  const ReviewsScreen({
    super.key,
    required this.ratings,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              'No reviews yet.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final review = ratings[index];
          final buyerUsername =
              review['profiles']?['username']?.toString() ?? 'Anonymous';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reviewer info row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        buyerUsername,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Star rating
                  Row(
                    children: List.generate(5, (starIndex) {
                      return Icon(
                        starIndex < (review['rating'] as int)
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  if (review['comment'] != null &&
                      review['comment'].toString().isNotEmpty)
                    Text(
                      review['comment'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (review['products'] != null) ...[
                    const Divider(height: 24),
                    // Product preview
                    InkWell(
                      onTap: () {
                        final p = review['products'];
                        context.push(
                          '/product/${p['id']}',
                          extra: <String, String>{
                            'id': p['id'].toString(),
                            'name': p['name'].toString(),
                            'price': p['price'].toString(),
                            'size': p['size'].toString(),
                            'condition': p['condition'].toString(),
                            'brand': p['brand'].toString(),
                            'imageUrl': p['image_url']?.toString() ?? '',
                            'sellerId': sellerId,
                            'sellerName': sellerName,
                            'is_sold': p['is_sold']?.toString() ?? 'false',
                            'category': p['category']?.toString() ?? 'Other',
                          },
                        );
                      },
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: review['products']['image_url'] != null
                                  ? Image.network(
                                      review['products']['image_url'],
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey[100],
                                      child: const Icon(
                                        Icons.image,
                                        size: 24,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review['products']['name'] ?? 'Unknown Item',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  review['products']['brand'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '£${(review['products']['price'] as num).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: const Text(
                              'SOLD',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.red[400],
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }, childCount: ratings.length),
      ),
    );
  }
}
