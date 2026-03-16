import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thryft/models/cart_item.dart';
import 'package:thryft/providers/cart_provider.dart';
import 'package:thryft/utils/responsive.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/footer.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isMobile = Responsive.isMobile(context);
    final contentPadding = isMobile ? 16.0 : 32.0;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: cart.items.isEmpty
                ? const _EmptyCart()
                : SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Padding(
                          padding: EdgeInsets.all(contentPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shopping Cart (${cart.itemCount} items)',
                                style: TextStyle(
                                  fontSize: isMobile ? 24 : 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: isMobile ? 16 : 32),
                              if (isMobile) ...[
                                _CartItemList(items: cart.items),
                                const SizedBox(height: 24),
                                const _OrderSummary(),
                              ] else
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _CartItemList(items: cart.items),
                                    ),
                                    const SizedBox(width: 32),
                                    const Expanded(
                                      flex: 1,
                                      child: _OrderSummary(),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          if (cart.items.isEmpty) const Footer(),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: isMobile ? 80 : 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Looks like you haven\'t added any items yet.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF47A4F5),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 32,
                vertical: isMobile ? 14 : 16,
              ),
            ),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }
}

class _CartItemList extends StatelessWidget {
  final List<CartItem> items;

  const _CartItemList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemBuilder: (context, i) => _CartItemRow(item: items[i]),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final CartItem item;

  const _CartItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final imageSize = isMobile ? 80.0 : 120.0;
    final titleSize = isMobile ? 16.0 : 18.0;
    final priceSize = isMobile ? 16.0 : 20.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.product.imageUrl ?? '',
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: imageSize,
              height: imageSize,
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Product Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.product.name,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 16),
                    Text(
                      '£${(item.product.price * item.quantity).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: priceSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 8),
              if (item.product.size.isNotEmpty) ...[
                Text('Size: ${item.product.size}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 4),
              ],
              if (item.product.condition.isNotEmpty)
                Text('Condition: ${item.product.condition}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              SizedBox(height: isMobile ? 12 : 16),

              // Quantity & Mobile Price Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuantitySelector(item: item),
                  if (isMobile)
                    Text(
                      '£${(item.product.price * item.quantity).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: priceSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final CartItem item;

  const _QuantitySelector({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final isMobile = Responsive.isMobile(context);
    final btnSize = isMobile ? 28.0 : 32.0;
    final iconSize = isMobile ? 16.0 : 20.0;

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              _buildBtn(
                icon: Icons.remove,
                size: btnSize,
                iconSize: iconSize,
                onTap: () {
                  if (item.quantity > 1) {
                    cart.updateQuantity(item.product.id, item.quantity - 1);
                  } else {
                    _showRemoveDialog(context, cart, item);
                  }
                },
              ),
              Container(
                width: isMobile ? 32 : 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Text(
                  '${item.quantity}',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 14 : 16),
                ),
              ),
              _buildBtn(
                icon: Icons.add,
                size: btnSize,
                iconSize: iconSize,
                onTap: () => cart.updateQuantity(item.product.id, item.quantity + 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        TextButton.icon(
          onPressed: () => _showRemoveDialog(context, cart, item),
          icon: Icon(Icons.delete_outline,
              color: Colors.red[400], size: isMobile ? 16 : 20),
          label: Text('Remove',
              style: TextStyle(
                  color: Colors.red[400], fontSize: isMobile ? 12 : 14)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildBtn(
      {required IconData icon,
      required double size,
      required double iconSize,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: iconSize, color: Colors.grey[700]),
      ),
    );
  }

  void _showRemoveDialog(
      BuildContext context, CartProvider cart, CartItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "${item.product.name}" from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              cart.removeItem(item.product.id);
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isMobile = Responsive.isMobile(context);
    final cardPadding = isMobile ? 16.0 : 24.0;

    // Use a placeholder layout for order summary to keep this example concise
    // In a real app, this would calculate shipping, taxes, etc.
    final subtotal = cart.totalPrice;
    const shipping = 4.99;
    final total = subtotal + shipping;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Summary',
                style: TextStyle(
                    fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold)),
            SizedBox(height: isMobile ? 16 : 24),
            _SummaryRow('Subtotal', '£${subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            _SummaryRow('Shipping', '£${shipping.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _SummaryRow(
              'Total',
              '£${total.toStringAsFixed(2)}',
              isTotal: true,
            ),
            SizedBox(height: isMobile ? 24 : 32),
            SizedBox(
              width: double.infinity,
              height: isMobile ? 48 : 52,
              child: FilledButton(
                onPressed: () {
                  // TO DO: navigate to checkout
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isTotal;

  const _SummaryRow(this.label, this.amount, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
