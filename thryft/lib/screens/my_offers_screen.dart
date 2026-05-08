// Shows all offers the logged-in user has made on other listings.
// Reached from the account hub. Reads from OfferProvider which fetches
// from Supabase and exposes loading/error/data states.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/offer_model.dart';
import 'package:thryft/providers/offer_provider.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/header.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  static const Color _brand = Color.fromARGB(255, 71, 164, 245); // app blue

  @override
  void initState() {
    super.initState();
    // Deferred to post-frame so the provider is available in the widget tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfferProvider>().fetchMyOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OfferProvider>();
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              // minHeight ensures the footer stays pinned to the bottom on short lists.
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Header(),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Offers',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Track offers you have made on listings.',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                                const SizedBox(height: 24),
                                // Four mutually exclusive states — guest, loading, error, or offer list.
                                if (user == null)
                                  _buildLoginPrompt(context)
                                else if (provider.isLoading)
                                  const SizedBox(
                                    height: 300,
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                else if (provider.hasError)
                                  _buildErrorState(provider.errorMessage)
                                else if (provider.offers.isEmpty)
                                  _buildEmptyState()
                                else
                                  _buildOfferList(context, provider.offers),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Footer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Shown instead of the list when the user is not logged in.
  Widget _buildLoginPrompt(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Log in to view your offers',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.push('/auth'),
              style: FilledButton.styleFrom(backgroundColor: _brand),
              child: const Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }

  // Shown when OfferProvider sets hasError — displays the raw error message if available.
  Widget _buildErrorState(String? errorMessage) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Could not load offers',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Shown when the fetch succeeded but returned no offers.
  Widget _buildEmptyState() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No offers yet',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse listings and make an offer on something you like.',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Non-scrolling list — the parent SingleChildScrollView handles all scrolling.
  Widget _buildOfferList(BuildContext context, List<Offer> offers) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: offers.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
      itemBuilder: (context, index) => _buildOfferTile(context, offers[index]),
    );
  }

  // Declined offers are not tappable — only pending and accepted ones link to the listing.
  Widget _buildOfferTile(BuildContext context, Offer offer) {
    return InkWell(
      onTap: offer.isPending || offer.isAccepted
          ? () => _navigateToListing(context, offer)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: offer.listingImageUrl != null
                  ? Image.network(
                      offer.listingImageUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.listingTitle ?? 'Listing',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your offer: £${offer.offerAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildStatusBadge(offer.status),
                      const SizedBox(width: 12),
                      Text(
                        _timeAgo(offer.createdAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (offer.isPending || offer.isAccepted)
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey[100],
      child: Icon(Icons.image_outlined, color: Colors.grey[400]),
    );
  }

  // Colour-coded pill badge — green for accepted, red for declined, orange for pending.
  Widget _buildStatusBadge(String status) {
    final (Color bg, Color fg, String label) = switch (status) {
      'accepted' => (Colors.green.shade50, Colors.green.shade700, 'Accepted'),
      'declined' => (Colors.red.shade50, Colors.red.shade700, 'Declined'),
      _ => (Colors.orange.shade50, Colors.orange.shade700, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  // Fetches the full product row before navigating so the product detail screen
  // receives all the fields it needs via the route extra map.
  Future<void> _navigateToListing(BuildContext context, Offer offer) async {
    try {
      final data = await Supabase.instance.client
          .from('products')
          .select('*, profiles(username)')
          .eq('id', offer.listingId)
          .maybeSingle();

      if (data == null || !context.mounted) return;

      // Route extra is a String map — all values are stringified here.
      final product = <String, String>{
        'id': data['id'].toString(),
        'name': data['name']?.toString() ?? '',
        'price': data['price']?.toString() ?? '0',
        'originalPrice': data['original_price']?.toString() ?? '',
        'size': data['size']?.toString() ?? '',
        'brand': data['brand']?.toString() ?? '',
        'condition': data['condition']?.toString() ?? '',
        'imageUrl': data['image_url']?.toString() ?? '',
        'sellerId': data['user_id']?.toString() ?? '',
        'sellerName': (data['profiles'] as Map?)?['username']?.toString() ?? '',
        'category': data['category']?.toString() ?? 'Other',
        'department': data['department']?.toString() ?? 'All',
        'material': data['material']?.toString() ?? '',
        'colour': data['colour']?.toString() ?? '',
        'isSold': (data['is_sold'] == true).toString(),
        if (data['description'] != null) 'description': data['description'].toString(),
      };

      if (context.mounted) {
        context.push('/product/${offer.listingId}', extra: product);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load listing.')),
        );
      }
    }
  }

  // Returns a human-readable relative timestamp — falls back to a date once older than a week.
  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
