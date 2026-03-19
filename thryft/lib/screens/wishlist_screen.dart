import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thryft/models/wishlist_item.dart';
import 'package:thryft/providers/wishlist_provider.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/product_card.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  String? _selectedSize;
  String? _selectedPriceRange;
  String? _selectedDateSort;

  static const List<String> _priceRanges = [
    'Under £25',
    '£25 – £50',
    '£50 – £100',
    'Over £100',
  ];

  static const List<String> _sizeOrder = [
    'XXS',
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
    '6',
    '8',
    '10',
    '12',
    '14',
    '16',
    '18',
    '20',
    '28',
    '30',
    '32',
    '34',
    '36',
    '38',
    '40',
    'One Size',
  ];

  int _compareSizes(String a, String b) {
    final ai = _sizeOrder.indexOf(a);
    final bi = _sizeOrder.indexOf(b);
    if (ai == -1 && bi == -1) return a.compareTo(b);
    if (ai == -1) return 1;
    if (bi == -1) return -1;
    return ai.compareTo(bi);
  }

  static const List<String> _dateSortOptions = ['Newest first', 'Oldest first'];

  List<WishlistItem> _applyFilters(List<WishlistItem> all) {
    var result = all.toList();

    // Filter by size
    if (_selectedSize != null) {
      result = result.where((i) => i.product.size == _selectedSize).toList();
    }

    // Filter by price range
    if (_selectedPriceRange != null) {
      result = result.where((i) {
        final p = i.product.price;
        switch (_selectedPriceRange) {
          case 'Under £25':
            return p < 25;
          case '£25 – £50':
            return p >= 25 && p < 50;
          case '£50 – £100':
            return p >= 50 && p < 100;
          case 'Over £100':
            return p >= 100;
          default:
            return true;
        }
      }).toList();
    }

    // Sort by date saved (default: newest first)
    if (_selectedDateSort == 'Oldest first') {
      result.sort((a, b) => a.savedAt.compareTo(b.savedAt));
    } else {
      result.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    }

    return result;
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> options,
    required String Function(T) display,
    required void Function(T?) onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.6,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            hint: Text(
              'All',
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Color(0xFF111827),
            ),
            borderRadius: BorderRadius.circular(8),
            items: [
              DropdownMenuItem<T>(
                value: null,
                child: const Text('All', style: TextStyle(fontSize: 14)),
              ),
              ...options.map(
                (o) => DropdownMenuItem<T>(
                  value: o,
                  child: Text(display(o), style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allItems = context.watch<WishlistProvider>().wishlistItems;
    final uniqueSizes = allItems.map((i) => i.product.size).toSet().toList()
      ..sort(_compareSizes);
    final displayed = _applyFilters(allItems.toList());

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
                  // ── Filter bar ────────────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _buildFilterDropdown<String>(
                          label: 'SIZE',
                          value: _selectedSize,
                          options: uniqueSizes,
                          display: (s) => s,
                          onChanged: (v) => setState(() => _selectedSize = v),
                        ),
                        const SizedBox(width: 32),
                        _buildFilterDropdown<String>(
                          label: 'PRICE',
                          value: _selectedPriceRange,
                          options: _priceRanges,
                          display: (s) => s,
                          onChanged: (v) =>
                              setState(() => _selectedPriceRange = v),
                        ),
                        const SizedBox(width: 32),
                        _buildFilterDropdown<String>(
                          label: 'DATE SAVED',
                          value: _selectedDateSort,
                          options: _dateSortOptions,
                          display: (s) => s,
                          onChanged: (v) =>
                              setState(() => _selectedDateSort = v),
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

                  //  Content area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: allItems.isEmpty
                          ? SizedBox(
                              height: MediaQuery.of(context).size.height * 0.55,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.favorite_border,
                                      size: 80,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Your wishlist is empty',
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
                                      'Save items you love to find them later',
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
                              ),
                            )
                          : displayed.isEmpty
                          ? SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: Center(
                                child: Text(
                                  'No items match your filters',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.5),
                                      ),
                                ),
                              ),
                            )
                          : Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: displayed
                                  .map(
                                    (i) => SizedBox(
                                      height: 240,
                                      child: ProductCard(product: i.product),
                                    ),
                                  )
                                  .toList(),
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
