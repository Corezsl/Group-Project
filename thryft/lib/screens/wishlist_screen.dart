import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thryft/providers/wishlist_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:thryft/widgets/standard_product_grid.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final allItems = context.watch<WishlistProvider>().wishlistItems;
    final products = allItems.map((i) => i.product).toList();

    return StandardProductGrid(
      items: products,
      emptyIcon: Icons.favorite_border,
      emptyTitle: 'Your wishlist is empty',
      emptySubtitle: 'Save your favorite items to keep track of them.',
      dateFilterLabel: 'DATE SAVED',
      extraButton: ElevatedButton(
        onPressed: () => context.go('/'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Start Shopping',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
