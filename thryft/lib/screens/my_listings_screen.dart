import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/widgets/standard_product_grid.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Product> listings = []; // TODO: Fetch from provider/backend

    return StandardProductGrid(
      items: listings,
      emptyIcon: Icons.inventory_2_outlined,
      emptyTitle: 'You have no listings',
      emptySubtitle: 'Start selling your items today.',
      dateFilterLabel: 'DATE LISTED',
      extraButton: ElevatedButton(
        onPressed: () => context.go('/add-listing'), // Or wherever to add listing
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
          'Create a Listing',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
