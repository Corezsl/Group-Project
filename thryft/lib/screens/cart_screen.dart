import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thryft/providers/cart_provider.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _selectedSortOption;
  String? _selectedFilterOption;
  bool _isProcessingCheckout = false;

  final List<String> _sortOptions = [
    'Price: High to Low',
    'Price: Low to High',
    'A-Z',
    'Z-A',
  ];

  final List<String> _filterOptions = [
    'Still active',
    'Shirts',
    'Trousers',
    'Shoes',
    'Accessories',
  ];

  Future<void> _handleCheckout(CartProvider cart) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to checkout')),
      );
      return;
    }

    setState(() => _isProcessingCheckout = true);

    // 1. Capture items to rate before clearing cart
    final itemsToRate = List.from(cart.items);

    // 1.5 Update items as sold in database
    try {
      for (var item in itemsToRate) {
        await Supabase.instance.client.from('products').update({
          'is_sold': true,
          'buyer_id': user.id,
        }).eq('id', item.product.id);
      }
    } catch (e) {
      debugPrint('Error marking checkout items as sold: $e');
    }

    // 2. Clear cart
    await cart.clear();

    if (!mounted) return;
    setState(() => _isProcessingCheckout = false);

    // 3. Show Success & Start Rating Flow
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Purchase successful!')),
    );

    // 4. Prompt for ratings
    for (var item in itemsToRate) {
      if (!mounted) break;
      await _showRatingDialog(item.product);
    }
  }

  Future<void> _showRatingDialog(Product product) async {
    int localRating = 5;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Rate your purchase: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How was your experience with ${product.sellerName ?? "the seller"}?'),
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
                    onPressed: () {
                      setDialogState(() => localRating = index + 1);
                    },
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null && product.sellerId != null) {
                  try {
                    await Supabase.instance.client.from('ratings').insert({
                      'seller_id': product.sellerId,
                      'buyer_id': user.id,
                      'product_id': product.id,
                      'rating': localRating,
                      'comment': commentController.text,
                    });
                  } catch (e) {
                    debugPrint('Error saving rating: $e');
                  }
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  _buildSortAndFilter(),
                  const SizedBox(height: 20),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: cart.items.isEmpty
                          ? _buildEmptyCart(context, colorScheme)
                          : _buildCartContent(context, cart),
                    ),
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

  Widget _buildSortAndFilter() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const SizedBox(width: 24),
          const Text(
            'SORT BY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 18),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSortOption,
              hint: const Text('Best selling', style: TextStyle(fontSize: 15, color: Color(0xFF111827))),
              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF111827)),
              borderRadius: BorderRadius.circular(8),
              items: _sortOptions.map((option) => DropdownMenuItem(value: option, child: Text(option, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (value) => setState(() => _selectedSortOption = value),
            ),
          ),
          const SizedBox(width: 36),
          const Text(
            'FILTER BY',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.6, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 18),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilterOption,
              hint: const Text('Still active', style: TextStyle(fontSize: 15, color: Color(0xFF111827))),
              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF111827)),
              borderRadius: BorderRadius.circular(8),
              items: _filterOptions.map((option) => DropdownMenuItem(value: option, child: Text(option, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (value) => setState(() => _selectedFilterOption = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 8),
          Text('Add items you love to find them later', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, CartProvider cart) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cart.items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = cart.items[index];
            final product = item.product;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                    clipBehavior: Clip.antiAlias,
                    child: product.imageUrl != null ? Image.network(product.imageUrl!, fit: BoxFit.cover) : const Icon(Icons.image, color: Colors.grey),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${product.brand} · ${product.size}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 8),
                        Text('£${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => cart.removeItem(product.id),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total price', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('£${cart.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _isProcessingCheckout
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: () => _handleCheckout(cart),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 71, 164, 245),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
