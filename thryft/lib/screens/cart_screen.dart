import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thryft/providers/cart_provider.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/header.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _selectedSortOption;
  String? _selectedFilterOption;

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
                  Align(
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
                            hint: const Text(
                              'Best selling',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF111827),
                              ),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: Color(0xFF111827),
                            ),
                            borderRadius: BorderRadius.circular(8),
                            items: _sortOptions
                                .map(
                                  (option) => DropdownMenuItem(
                                    value: option,
                                    child: Text(
                                      option,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedSortOption = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 36),
                        const Text(
                          'FILTER BY',
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
                            value: _selectedFilterOption,
                            hint: const Text(
                              'Still active',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF111827),
                              ),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: Color(0xFF111827),
                            ),
                            borderRadius: BorderRadius.circular(8),
                            items: _filterOptions
                                .map(
                                  (option) => DropdownMenuItem(
                                    value: option,
                                    child: Text(
                                      option,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedFilterOption = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE5E7EB),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                        child: cart.items.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 80,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Your cart is empty',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.5),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add items you love to find them later',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.4),
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : _buildCartContent(context, cart),
                      ),
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

  Widget _buildCartContent(BuildContext context, CartProvider cart) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: cart.items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = cart.items[index];
            final product = item.product;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  // Product image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: product.imageUrl != null
                        ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${product.brand} · ${product.size}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '£${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Quantity stepper
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => context
                            .read<CartProvider>()
                            .updateQuantity(product.id, item.quantity - 1),
                      ),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => context
                            .read<CartProvider>()
                            .updateQuantity(product.id, item.quantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: TextStyle(fontSize: 16)),
                  Text(
                    '£${cart.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Proceed to Checkout',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

