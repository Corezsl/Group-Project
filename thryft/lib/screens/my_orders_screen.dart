import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Product> _orders = [];
  Map<String, int> _ratingsByProductId = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final ordersData = await Supabase.instance.client
          .from('products')
          .select('*, profiles(username)')
          .eq('buyer_id', userId)
          .order('created_at', ascending: false);

      final ratingsData = await Supabase.instance.client
          .from('ratings')
          .select('product_id, rating')
          .eq('buyer_id', userId);

      final orders = (ordersData as List)
          .map(
            (data) => Product(
              id: data['id'].toString(),
              name: data['name'].toString(),
              price: (data['price'] as num).toDouble(),
              originalPrice: data['original_price'] != null
                  ? (data['original_price'] as num).toDouble()
                  : null,
              size: data['size'].toString(),
              brand: data['brand'].toString(),
              condition: data['condition'].toString(),
              imageUrl: data['image_url']?.toString(),
              sellerId: data['user_id']?.toString(),
              sellerName: data['profiles'] != null
                  ? data['profiles']['username']?.toString()
                  : null,
              isSold: data['is_sold'] == true,
              category: data['category']?.toString() ?? 'Other',
              department: data['department']?.toString() ?? 'All',
              material: data['material'].toString(),
              colour: data['colour'].toString(),
              description: data['description']?.toString(),
            ),
          )
          .toList();

      final ratingsMap = <String, int>{
        for (final r in ratingsData as List)
          r['product_id'].toString(): (r['rating'] as num).toInt(),
      };

      setState(() {
        _orders = orders;
        _ratingsByProductId = ratingsMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showRateDialog(Product product) async {
    int localRating = 5;
    final commentController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Rate your purchase: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your experience with ${product.sellerName ?? "the seller"}?',
              ),
              const SizedBox(height: 16),
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
                  labelText: 'Leave a comment (optional)',
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
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || product.sellerId == null) return;

    try {
      await Supabase.instance.client.from('ratings').insert({
        'seller_id': product.sellerId,
        'buyer_id': user.id,
        'product_id': product.id,
        'rating': localRating,
        'comment': commentController.text,
      });
      setState(() => _ratingsByProductId[product.id] = localRating);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted. Thank you!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit review.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    'My Orders',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Items you have purchased from other sellers.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_orders.isEmpty)
                    SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No orders yet',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your purchased items will appear here.',
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
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = _orders[index];
                        final rating = _ratingsByProductId[product.id];
                        return _buildOrderCard(product, rating);
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

  Widget _buildOrderCard(Product product, int? rating) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push(
          '/product/${product.id}',
          extra: <String, String>{
            'id': product.id,
            'name': product.name,
            'price': product.price.toString(),
            'size': product.size,
            'brand': product.brand,
            'condition': product.condition,
            'imageUrl': product.imageUrl ?? '',
            'sellerId': product.sellerId ?? '',
            'sellerName': product.sellerName ?? '',
            'is_sold': product.isSold.toString(),
            'category': product.category,
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: product.imageUrl != null
                      ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.image,
                            size: 28,
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
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.brand,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '£${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (product.sellerName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Sold by ${product.sellerName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (rating != null)
                Column(
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reviewed',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                )
              else
                OutlinedButton(
                  onPressed: () => _showRateDialog(product),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF47A4F5),
                    side: const BorderSide(color: Color(0xFF47A4F5)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Rate', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
