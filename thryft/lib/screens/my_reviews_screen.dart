// Shows all buyer reviews left on the logged-in user's sold listings.
// Reached from the account hub.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/footer.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<Map<String, dynamic>> _ratings = [];
  bool _isLoading = true;
  String? _sellerId;   // current user's id — used when building product navigation extras
  String? _sellerName; // current user's username — displayed on product detail

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  // Fetches the seller's username then all ratings on their listings, newest first.
  Future<void> _fetchReviews() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    _sellerId = user.id;

    try {
      final profileData = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();

      _sellerName = profileData?['username']?.toString();

      // The foreign-key hint on profiles selects the buyer's username, not the seller's.
      final ratingsData = await _supabase
          .from('ratings')
          .select(
            '*, products(*), profiles!ratings_buyer_profile_fkey(username)',
          )
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _ratings = List<Map<String, dynamic>>.from(ratingsData as List);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      setState(() => _isLoading = false);
    }
  }

  // Asks for confirmation before removing the review row from the ratings table.
  Future<void> _deleteReview(Map<String, dynamic> review) async {
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
      await _supabase.from('ratings').delete().eq('id', review['id']);
      setState(() => _ratings.removeWhere((r) => r['id'] == review['id']));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete review.')),
        );
      }
    }
  }

  // Opens a star-picker pre-filled with the existing rating and saves the update.
  Future<void> _editReview(Map<String, dynamic> review) async {
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
      await _supabase
          .from('ratings')
          .update({
            'rating': localRating,
            'comment': commentController.text.trim(),
          })
          .eq('id', review['id']);

      // Patch the local list in place so the card reflects the new values immediately.
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
    final currentUserId = _supabase.auth.currentUser?.id;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Reviews',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reviews left by buyers on your sold items.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  // Three states: loading spinner, empty message, or the review list.
                  if (_isLoading)
                    const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_ratings.isEmpty)
                    SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.reviews_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No reviews yet',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Reviews from buyers will appear here.',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ratings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final review = _ratings[index];
                        final buyerUsername =
                            review['profiles']?['username']?.toString() ??
                            'Anonymous';
                        // Only the buyer who left the review can edit or delete it.
                        final isOwnReview =
                            currentUserId != null &&
                            review['buyer_id'] == currentUserId;

                        return _buildReviewCard(
                          review: review,
                          buyerUsername: buyerUsername,
                          isOwnReview: isOwnReview,
                        );
                      },
                    ),
                ],
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  // Review card: buyer avatar and name at top, star row, optional comment,
  // and a tappable product thumbnail that navigates to the listing detail.
  Widget _buildReviewCard({
    required Map<String, dynamic> review,
    required String buyerUsername,
    required bool isOwnReview,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, size: 14, color: Colors.grey),
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
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
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
              children: List.generate(5, (i) {
                return Icon(
                  i < (review['rating'] as int)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                );
              }),
            ),
            if (review['comment'] != null &&
                review['comment'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review['comment'],
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
            if (review['products'] != null) ...[
              const Divider(height: 24),
              InkWell(
                borderRadius: BorderRadius.circular(4),
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
                      'sellerId': _sellerId ?? '',
                      'sellerName': _sellerName ?? '',
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
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
