import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thryft/providers/cart_provider.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/models/notification_model.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color _brand = Color.fromARGB(255, 71, 164, 245);
  bool _isProcessingCheckout = false;

  Future<void> _handleCheckout(CartProvider cart) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to checkout')),
      );
      return;
    }

    // Fetch buyer address early — block checkout if missing
    String? buyerAddress;
    try {
      final addressData = await Supabase.instance.client
          .from('address')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (addressData != null) {
        final parts = [
          addressData['street'],
          addressData['city'],
          addressData['postal_code'],
          addressData['country'],
        ].where((p) => p != null && p.toString().isNotEmpty).toList();
        if (parts.isNotEmpty) buyerAddress = parts.join(', ');
      }
    } catch (e) {
      debugPrint('Error fetching buyer address: $e');
    }

    if (buyerAddress == null || buyerAddress.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add a delivery address in your profile settings before checkout.'),
          ),
        );
      }
      return;
    }

    try {
      final paymentData = await Supabase.instance.client
          .from('payment_methods')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (paymentData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add a payment method in your profile settings before checkout.'),
            ),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('Error fetching payment method: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error verifying payment method.')),
        );
      }
      return;
    }

    setState(() => _isProcessingCheckout = true);

    final cartItems = List.from(cart.items);

    try {
      for (var item in cartItems) {
        await Supabase.instance.client.from('products').update({
          'is_sold': true,
          'buyer_id': user.id,
          'order_status': 'pending',
        }).eq('id', item.product.id);

        // Remove this product from all users' carts
        await Supabase.instance.client
            .from('cart_items')
            .delete()
            .eq('product_id', item.product.id);
      }
    } catch (e) {
      debugPrint('Error marking checkout items as sold: $e');
    }



    for (var item in cartItems) {
      debugPrint('Checkout item: ${item.product.name}, sellerId=${item.product.sellerId}');
      if (item.product.sellerId != null) {
        try {
          await NotificationProvider.insertNotification(
            userId: item.product.sellerId!,
            type: NotificationType.listingSold,
            content: 'Your listing "${item.product.name}" has been sold!',
            listingId: item.product.id,
            relatedUserId: user.id,
            buyerAddress: buyerAddress,
          );
        } catch (e) {
          debugPrint('Failed to notify seller: $e');
        }
      }

      try {
        final wishlistEntries = await Supabase.instance.client
            .from('wishlist')
            .select('user_id')
            .eq('listing_id', item.product.id);
        for (final entry in wishlistEntries as List) {
          final wishlisterId = entry['user_id']?.toString();
          if (wishlisterId != null && wishlisterId != user.id) {
            await NotificationProvider.insertNotification(
              userId: wishlisterId,
              type: NotificationType.wishlistPurchased,
              content: 'An item on your wishlist "${item.product.name}" has been sold.',
              listingId: item.product.id,
            );
          }
        }
      } catch (e) {
        debugPrint('Error sending wishlist purchase notifications: $e');
      }
    }

    await cart.clear();

    if (!mounted) return;
    setState(() => _isProcessingCheckout = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Purchase successful!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
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
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 40, horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title row
                                Row(
                                  children: [
                                    Text(
                                      'My Cart',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    if (cart.items.isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _brand.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${cart.items.length} ${cart.items.length == 1 ? 'item' : 'items'}',
                                          style: const TextStyle(
                                            color: _brand,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 32),
                                if (cart.items.isEmpty)
                                  _buildEmptyCart(context)
                                else
                                  constraints.maxWidth >= 800
                                      ? _buildDesktopLayout(context, cart)
                                      : _buildMobileLayout(context, cart),
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

  Widget _buildEmptyCart(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_cart_outlined,
                  size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse listings and add something you love.',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text('Browse listings',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // Desktop: items on the left, summary panel on the right.
  Widget _buildDesktopLayout(BuildContext context, CartProvider cart) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: _buildItemList(cart)),
        const SizedBox(width: 32),
        SizedBox(width: 300, child: _buildSummaryPanel(context, cart)),
      ],
    );
  }

  // Mobile: items stacked above summary.
  Widget _buildMobileLayout(BuildContext context, CartProvider cart) {
    return Column(
      children: [
        _buildItemList(cart),
        const SizedBox(height: 32),
        _buildSummaryPanel(context, cart),
      ],
    );
  }

  Widget _buildItemList(CartProvider cart) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cart.items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
      itemBuilder: (context, index) {
        final product = cart.items[index].product;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 88,
                  height: 88,
                  color: Colors.grey[100],
                  child: product.imageUrl != null
                      ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                      : Icon(Icons.image_outlined,
                          size: 32, color: Colors.grey[400]),
                ),
              ),
              const SizedBox(width: 20),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.brand} · ${product.size} · ${product.condition}',
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    if (product.sellerName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Sold by ${product.sellerName}',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      '£${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _brand,
                      ),
                    ),
                  ],
                ),
              ),
              // Remove button
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
                tooltip: 'Remove',
                onPressed: () => cart.removeItem(product.id),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryPanel(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${cart.items.length} ${cart.items.length == 1 ? 'item' : 'items'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text('£${cart.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shipping', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text('Calculated at checkout',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('£${cart.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _brand)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _isProcessingCheckout
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: () => _handleCheckout(cart),
                    style: FilledButton.styleFrom(
                      backgroundColor: _brand,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Checkout',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
          ),
        ],
      ),
    );
  }
}
