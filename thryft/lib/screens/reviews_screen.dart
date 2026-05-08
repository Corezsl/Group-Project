// Sliver widget that renders the review list on a seller's public profile page.
// Embedded inside a CustomScrollView — not a standalone route. Receives the
// ratings list from the parent and manages local edits without re-fetching.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewsScreen extends StatefulWidget {
  final List<dynamic> ratings;
  final String sellerId;
  final String sellerName;
  final String? currentUserId; // passed in so the widget knows whose review to show edit controls for
  final VoidCallback? onReviewChanged; // called after edit or delete so the parent can refresh its average

  const ReviewsScreen({
    super.key,
    required this.ratings,
    required this.sellerId,
    required this.sellerName,
    this.currentUserId,
    this.onReviewChanged,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  late List<dynamic> _ratings;

  @override
  void initState() {
    super.initState();
    // Copy so local edits don't mutate the parent's list directly.
    _ratings = List.from(widget.ratings);
  }

  // Confirms then deletes the row — also calls onReviewChanged so the
  // parent profile page can recalculate the average rating display.
  Future<void> _deleteReview(dynamic review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('ratings')
          .delete()
          .eq('id', review['id']);
      setState(() => _ratings.removeWhere((r) => r['id'] == review['id']));
      widget.onReviewChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete review.')),
        );
      }
    }
  }

  // Opens a star-picker pre-filled with the existing values and saves the update.
  Future<void> _editReview(dynamic review) async {
    int localRating = review['rating'] as int;
    final commentController = TextEditingController(
      text: review['comment']?.toString() ?? '',
    );

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit your review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < localRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () =>
                        setDialogState(() => localRating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF47A4F5),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true) return;

    try {
      await Supabase.instance.client.from('ratings').update({
        'rating': localRating,
        'comment': commentController.text,
      }).eq('id', review['id']);

      // Patch the local copy in place so the card updates without a re-fetch.
      setState(() {
        final index = _ratings.indexWhere((r) => r['id'] == review['id']);
        if (index != -1) {
          _ratings[index] = {
            ..._ratings[index],
            'rating': localRating,
            'comment': commentController.text,
          };
        }
      });
      widget.onReviewChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update review.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ratings.isEmpty) {
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
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final review = _ratings[index];
            final buyerUsername =
                review['profiles']?['username']?.toString() ?? 'Anonymous';
            // Only the buyer who wrote the review sees the edit/delete menu.
            final isOwnReview =
                widget.currentUserId != null &&
                review['buyer_id'] == widget.currentUserId;

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
                        const Spacer(),
                        if (isOwnReview)
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              size: 18,
                              color: Colors.grey[500],
                            ),
                            onSelected: (value) {
                              if (value == 'edit') _editReview(review);
                              if (value == 'delete') _deleteReview(review);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                    // Linked product thumbnail — only shown when the product data was joined.
                    if (review['products'] != null) ...[
                      const Divider(height: 24),
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
                              'sellerId': widget.sellerId,
                              'sellerName': widget.sellerName,
                              'is_sold': p['is_sold']?.toString() ?? 'false',
                              'category':
                                  p['category']?.toString() ?? 'Other',
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
                                    review['products']['name'] ??
                                        'Unknown Item',
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
          },
          childCount: _ratings.length,
        ),
      ),
    );
  }
}
