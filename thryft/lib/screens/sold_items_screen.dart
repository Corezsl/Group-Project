import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/models/notification_model.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SoldItemsScreen extends StatefulWidget {
  const SoldItemsScreen({super.key});

  @override
  State<SoldItemsScreen> createState() => _SoldItemsScreenState();
}

class _SoldItemsScreenState extends State<SoldItemsScreen> {
  List<Product> _soldItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSoldItems();
  }

  Future<void> _fetchSoldItems() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('*, profiles(username)')
          .eq('user_id', userId)
          .eq('is_sold', true)
          .order('created_at', ascending: false);

      final items = (response as List)
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
              buyerId: data['buyer_id']?.toString(),
              orderStatus: data['order_status']?.toString(),
              createdAt: data['created_at'] != null
                  ? DateTime.tryParse(data['created_at'].toString())
                  : null,
              description: data['description']?.toString(),
            ),
          )
          .toList();

      setState(() {
        _soldItems = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching sold items: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsShipped(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Shipped'),
        content: Text(
          'Confirm that you have posted "${product.name}" to the buyer?',
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
            child: const Text('Yes, shipped'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await Supabase.instance.client
          .from('products')
          .update({'order_status': 'shipped'})
          .eq('id', product.id);

      if (product.buyerId != null) {
        await NotificationProvider.insertNotification(
          userId: product.buyerId!,
          type: NotificationType.orderShipped,
          content:
              'Good news! Your order "${product.name}" has been shipped and is on its way.',
          listingId: product.id,
        );
      }

      setState(() {
        final idx = _soldItems.indexWhere((p) => p.id == product.id);
        if (idx != -1) {
          _soldItems[idx] = Product(
            id: product.id,
            name: product.name,
            price: product.price,
            originalPrice: product.originalPrice,
            size: product.size,
            brand: product.brand,
            condition: product.condition,
            imageUrl: product.imageUrl,
            sellerId: product.sellerId,
            sellerName: product.sellerName,
            isSold: product.isSold,
            category: product.category,
            department: product.department,
            material: product.material,
            colour: product.colour,
            buyerId: product.buyerId,
            orderStatus: 'shipped',
            createdAt: product.createdAt,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as shipped. Buyer notified.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status.')),
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
                    'Sold Items',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Items you have successfully sold to other users.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_soldItems.isEmpty)
                    SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sell_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No sold items yet',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your sold items will appear here once purchased.',
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
                      itemCount: _soldItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildSoldCard(_soldItems[index]);
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

  Widget _buildSoldCard(Product product) {
    final status = product.orderStatus ?? 'pending';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(status),
                if (product.createdAt != null)
                  Text(
                    _formatDate(product.createdAt!),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Product row
            InkWell(
              borderRadius: BorderRadius.circular(6),
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '£${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action row — only show for pending items
            if (status == 'pending') ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: () => _markAsShipped(product),
                    icon: const Icon(Icons.local_shipping_outlined, size: 16),
                    label: const Text(
                      'Mark as shipped',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF47A4F5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (label, color, bg) = switch (status) {
      'shipped' => ('Shipped', const Color(0xFF1D6FB8), const Color(0xFFE0F0FF)),
      'delivered' => ('Delivered', Colors.green[700]!, Colors.green[50]!),
      _ => ('To Ship', Colors.orange[700]!, Colors.orange[50]!),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
