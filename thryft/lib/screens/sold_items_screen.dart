import 'package:flutter/material.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/standard_product_grid.dart';
import 'package:thryft/models/product.dart';

class SoldItemsScreen extends StatelessWidget {
  const SoldItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initializing with empty list as per "no Supabase logic yet" rule
    final List<Product> soldItems = []; 

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
                  
                  // Reusing the standard grid for consistency
                  StandardProductGrid(
                    items: soldItems,
                    emptyIcon: Icons.sell_outlined,
                    emptyTitle: 'No sold items yet',
                    emptySubtitle: 'Your sold items will appear here once they are purchased.',
                    dateFilterLabel: 'DATE SOLD',
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
