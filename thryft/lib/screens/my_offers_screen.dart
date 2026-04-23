  import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  late Future<List<_OfferHistoryItem>> _offersFuture;

  @override
  void initState() {
    super.initState();
    _offersFuture = _fetchOffers();
  }

  Future<List<_OfferHistoryItem>> _fetchOffers() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    List<dynamic> offers = [];
    var usingNotificationFallback = false;

    try {
      offers = await Supabase.instance.client
          .from('offers')
          .select('offer_id, listing_id, offered_price, status, created_at')
          .eq('buyer_id', userId)
          .order('created_at', ascending: false);
    } catch (_) {
      usingNotificationFallback = true;
      offers = await Supabase.instance.client
          .from('notification')
          .select('notification_id, listing_id, offer_price, created_at')
          .eq('user_id', userId)
          .eq('notif_type', 'other')
          .not('offer_price', 'is', null)
          .like('content', 'You successfully made an offer%')
          .order('created_at', ascending: false);
    }

    if (offers.isEmpty) return [];

    final listingIds = offers
        .map((offer) => offer['listing_id']?.toString())
        .whereType<String>()
        .toList();

    final products = listingIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await Supabase.instance.client
              .from('products')
              .select('id, name, image_url, price, size, brand, condition, user_id')
              .inFilter('id', listingIds);

    final productById = <String, Map<String, dynamic>>{
      for (final row in products) row['id'].toString(): row,
    };

    return offers.map<_OfferHistoryItem>((row) {
      final listingId = row['listing_id']?.toString() ?? '';
      final product = productById[listingId];
      return _OfferHistoryItem(
        offerId: (row['offer_id'] ?? row['notification_id']).toString(),
        listingId: listingId,
        offeredPrice:
          ((row['offered_price'] ?? row['offer_price']) as num?)?.toDouble() ??
          0,
        status: usingNotificationFallback
          ? 'pending'
          : (row['status']?.toString() ?? 'pending'),
        createdAt:
            DateTime.tryParse(row['created_at']?.toString() ?? '') ??
            DateTime.now(),
        productName: product?['name']?.toString() ?? 'Listing #$listingId',
        imageUrl: product?['image_url']?.toString(),
        productPrice: (product?['price'] as num?)?.toDouble(),
        productBrand: product?['brand']?.toString() ?? '',
        productSize: product?['size']?.toString() ?? '',
        productCondition: product?['condition']?.toString() ?? '',
        sellerId: product?['user_id']?.toString(),
      );
    }).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _offersFuture = _fetchOffers();
    });
    await _offersFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Offers')),
      body: FutureBuilder<List<_OfferHistoryItem>>(
        future: _offersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Failed to load offer history.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final offers = snapshot.data ?? const <_OfferHistoryItem>[];
          if (offers.isEmpty) {
            return const Center(
              child: Text('You have not made any offers yet.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: offers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = offers[index];
                final statusColor = _statusColor(item.status);

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: _buildLeadingImage(item.imageUrl),
                    title: Text(
                      item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text('Your offer: £${item.offeredPrice.toStringAsFixed(2)}'),
                        if (item.productPrice != null)
                          Text(
                            'Listed price: £${item.productPrice!.toStringAsFixed(2)}',
                          ),
                        if (item.productBrand.isNotEmpty ||
                            item.productSize.isNotEmpty ||
                            item.productCondition.isNotEmpty)
                          Text(
                            '${item.productBrand} ${item.productSize} ${item.productCondition}'
                                .trim(),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        Text(
                          'Made on ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: item.listingId.isEmpty
                        ? null
                        : () {
                            context.push(
                              '/product/${item.listingId}',
                              extra: {
                                'id': item.listingId,
                                'name': item.productName,
                                'price': (item.productPrice ?? item.offeredPrice)
                                    .toStringAsFixed(2),
                                'size': item.productSize,
                                'brand': item.productBrand,
                                'condition': item.productCondition,
                                if (item.imageUrl != null)
                                  'imageUrl': item.imageUrl!,
                                if (item.sellerId != null)
                                  'sellerId': item.sellerId!,
                              },
                            );
                          },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeadingImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.local_offer_outlined));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

class _OfferHistoryItem {
  final String offerId;
  final String listingId;
  final double offeredPrice;
  final String status;
  final DateTime createdAt;
  final String productName;
  final String? imageUrl;
  final double? productPrice;
  final String productBrand;
  final String productSize;
  final String productCondition;
  final String? sellerId;

  const _OfferHistoryItem({
    required this.offerId,
    required this.listingId,
    required this.offeredPrice,
    required this.status,
    required this.createdAt,
    required this.productName,
    required this.imageUrl,
    required this.productPrice,
    required this.productBrand,
    required this.productSize,
    required this.productCondition,
    required this.sellerId,
  });
}