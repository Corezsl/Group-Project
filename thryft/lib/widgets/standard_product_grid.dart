import 'package:flutter/material.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/widgets/product_card.dart';
import 'package:thryft/utils/size_options.dart';
import 'dart:math';

class StandardProductGrid extends StatefulWidget {
  final List<Product> items;
  final String title;
  final String subtitle;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget? extraButton;
  final Widget? extraGridCard;
  final String dateFilterLabel;
  final String priceFilterLabel;

  const StandardProductGrid({
    super.key,
    required this.items,
    this.title = '',
    this.subtitle = '',
    this.emptyIcon = Icons.inventory_2_outlined,
    this.emptyTitle = 'No items found',
    this.emptySubtitle = 'Try adjusting your filters or check back later.',
    this.extraButton,
    this.extraGridCard,
    this.dateFilterLabel = 'DATE',
    this.priceFilterLabel = 'PRICE',
  });

  @override
  State<StandardProductGrid> createState() => _StandardProductGridState();
}

class _StandardProductGridState extends State<StandardProductGrid> {
  String? _selectedSize;
  String? _selectedDateSort;
  String? _selectedPriceSort;

  // Pagination state
  final List<int> _itemsPerPageOptions = [10, 20, 30, 40, 50];
  int _itemsPerPage = 50;
  int _currentPage = 1;

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

    if (_selectedDateSort == dateSortOptions[0]) {
      filtered.sort((a, b) => b.id.compareTo(a.id));
    } else if (_selectedDateSort == dateSortOptions[1]) {
      filtered.sort((a, b) => a.id.compareTo(b.id));
    }

    if (_selectedPriceSort == priceSortOptions[0]) {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedPriceSort == priceSortOptions[1]) {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }
    return filtered;
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> options,
    required String Function(T) display,
    required ValueChanged<T?> onChanged,
    bool includeAll = true,
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
              hint: includeAll ? Text('All', style: TextStyle(color: Colors.grey[400], fontSize: 14)) : null,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF111827)),
              borderRadius: BorderRadius.circular(8),
              items: [
                if (includeAll)
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

    // Apply filters first
    final filtered = _applyFilters(widget.items);

    // Ensure current page is valid after filters/items-per-page change
    final totalItems = filtered.length;
    final totalPages = max(1, (totalItems / _itemsPerPage).ceil());
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }

    // Slice for pagination
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, totalItems);
    final paginated = (totalItems == 0) ? <Product>[] : filtered.sublist(startIndex, endIndex);

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
                  onChanged: (v) => setState(() {
                    _selectedSize = v;
                    _currentPage = 1;
                  }),
                ),

                const SizedBox(width: 32),
                _buildFilterDropdown<String>(
                  label: widget.dateFilterLabel,
                  value: _selectedDateSort,
                  options: dateSortOptions,
                  display: (s) => s,
                  onChanged: (v) => setState(() {
                    _selectedDateSort = v;
                    _currentPage = 1;
                  }),
                ),

                const SizedBox(width: 32),
                _buildFilterDropdown<String>(
                  label: widget.priceFilterLabel,
                  value: _selectedPriceSort,
                  options: priceSortOptions,
                  display: (s) => s,
                  onChanged: (v) => setState(() {
                    _selectedPriceSort = v;
                    _currentPage = 1;
                  }),
                ),

                const SizedBox(width: 32),
                // Items per page dropdown
                _buildFilterDropdown<int>(
                  label: 'PER PAGE',
                  value: _itemsPerPage,
                  options: _itemsPerPageOptions,
                  display: (i) => i.toString(),
                  includeAll: false,
                  onChanged: (v) => setState(() {
                    if (v != null) {
                      _itemsPerPage = v;
                      _currentPage = 1;
                    }
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),

          // Pagination controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: summary
                  Text(
                    totalItems == 0
                        ? 'No items'
                        : 'Showing ${min(totalItems, startIndex + 1)}-${endIndex} of $totalItems',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),

                  // Right: page nav
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                      ),
                      Text('Page $_currentPage of $totalPages', style: Theme.of(context).textTheme.bodySmall),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: widget.items.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(widget.emptyIcon, size: 80, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(widget.emptyTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5))),
                            const SizedBox(height: 8),
                            Text(widget.emptySubtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.4))),
                            if (widget.extraButton != null) ...[
                              const SizedBox(height: 24),
                              widget.extraButton!,
                            ],
                            // show create-listing card even when there are no items
                            if (widget.extraGridCard != null) ...[
                              const SizedBox(height: 24),
                              widget.extraGridCard!,
                            ],
                          ],
                        ),
                      ),
                    )
                  : paginated.isEmpty
                      ? SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('No items match your filters', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5))),
                                if (widget.extraGridCard != null) ...[
                                  const SizedBox(height: 16),
                                  widget.extraGridCard!,
                                ],
                              ],
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            if (widget.extraGridCard != null) widget.extraGridCard!,
                            ...paginated.map((p) => SizedBox(height: 240, child: ProductCard(product: p))).toList(),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
