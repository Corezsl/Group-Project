import 'package:flutter/material.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/widgets/product_card.dart';

class StandardProductGrid extends StatefulWidget {
  final List<Product> items;
  final String title;
  final String subtitle;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget? extraButton;
  final String dateFilterLabel;

  const StandardProductGrid({
    super.key,
    required this.items,
    this.title = '',
    this.subtitle = '',
    this.emptyIcon = Icons.inventory_2_outlined,
    this.emptyTitle = 'No items found',
    this.emptySubtitle = 'Try adjusting your filters or check back later.',
    this.extraButton,
    this.dateFilterLabel = 'DATE',
  });

  @override
  State<StandardProductGrid> createState() => _StandardProductGridState();
}

class _StandardProductGridState extends State<StandardProductGrid> {
  String? _selectedSize;
  String? _selectedPriceRange;
  String? _selectedDateSort;

  final List<String> _priceRanges = [
    'Under \$25',
    '\$25 - \$50',
    '\$50 - \$100',
    '\$100 - \$250',
    'Over \$250',
  ];

  final List<String> _dateSortOptions = [
    'Newest First',
    'Oldest First',
  ];

  int _compareSizes(String a, String b) {
    const sizeOrder = {
      'XXS': 0, 'XS': 1, 'S': 2, 'M': 3, 'L': 4, 'XL': 5, 'XXL': 6,
      '3XL': 7, '4XL': 8, 'One Size': 9
    };
    return (sizeOrder[a] ?? 100).compareTo(sizeOrder[b] ?? 100);
  }

  List<Product> _applyFilters(List<Product> items) {
    var filtered = List<Product>.from(items);

    if (_selectedSize != null) {
      filtered = filtered.where((p) => p.size == _selectedSize).toList();
    }

    if (_selectedPriceRange != null) {
      filtered = filtered.where((p) {
        if (_selectedPriceRange == 'Under \$25') return p.price < 25;
        if (_selectedPriceRange == '\$25 - \$50') return p.price >= 25 && p.price <= 50;
        if (_selectedPriceRange == '\$50 - \$100') return p.price >= 50 && p.price <= 100;
        if (_selectedPriceRange == '\$100 - \$250') return p.price >= 100 && p.price <= 250;
        if (_selectedPriceRange == 'Over \$250') return p.price > 250;
        return true;
      }).toList();
    }

    if (_selectedDateSort == 'Newest First') {
      // Assuming ID or created_at mock
      filtered.sort((a, b) => b.id.compareTo(a.id));
    } else if (_selectedDateSort == 'Oldest First') {
      filtered.sort((a, b) => a.id.compareTo(b.id));
    }

    return filtered;
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> options,
    required String Function(T) display,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Text('All', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF111827)),
              borderRadius: BorderRadius.circular(8),
              items: [
                DropdownMenuItem<T>(
                  value: null,
                  child: const Text('All', style: TextStyle(fontSize: 14)),
                ),
                ...options.map((o) => DropdownMenuItem<T>(
                  value: o,
                  child: Text(display(o), style: const TextStyle(fontSize: 14)),
                )),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final uniqueSizes = widget.items.map((p) => p.size).toSet().toList()
      ..sort(_compareSizes);
    final displayed = _applyFilters(widget.items);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
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
                  onChanged: (v) => setState(() => _selectedPriceRange = v),
                ),
                const SizedBox(width: 32),
                _buildFilterDropdown<String>(
                  label: widget.dateFilterLabel,
                  value: _selectedDateSort,
                  options: _dateSortOptions,
                  display: (s) => s,
                  onChanged: (v) => setState(() => _selectedDateSort = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: widget.items.isEmpty
                  ? SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(widget.emptyIcon, size: 80, color: colorScheme.onSurface.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(widget.emptyTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.5))),
                            const SizedBox(height: 8),
                            Text(widget.emptySubtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.4))),
                            if (widget.extraButton != null) ...[
                              const SizedBox(height: 24),
                              widget.extraButton!,
                            ],
                          ],
                        ),
                      ),
                    )
                  : displayed.isEmpty
                      ? SizedBox(
                          height: 200,
                          child: Center(
                            child: Text('No items match your filters', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.5))),
                          ),
                        )
                      : Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: displayed.map((p) => SizedBox(height: 240, child: ProductCard(product: p))).toList(),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
