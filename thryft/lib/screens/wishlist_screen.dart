import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thryft/providers/wishlist_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:thryft/widgets/standard_product_grid.dart';

import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/header.dart';

// Screen showing the products the user has saved to their wishlist.
// Routed at /wishlist. Just renders Header + StandardProductGrid + Footer
// with the data coming from WishlistProvider.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch so the grid rebuilds when items are added/removed elsewhere
    final products = context.watch<WishlistProvider>().wishlistItems;

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
                    'My Wishlist',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Items you have saved for later.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  // shared grid handles filters/paging — we just feed it the products
                  // and customise the empty-state copy + a "Start Shopping" CTA
                  SizedBox(
                    width: double.infinity,
                    child: StandardProductGrid(
                      items: products,
                      emptyIcon: Icons.favorite_border,
                      emptyTitle: 'Your wishlist is empty',
                      emptySubtitle:
                          'Save your favorite items to keep track of them.',
                      dateFilterLabel: 'DATE SAVED',
                      // shown under the empty state — sends the user back to home
                      extraButton: ElevatedButton(
                        onPressed: () => context.go('/'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Start Shopping',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
}
