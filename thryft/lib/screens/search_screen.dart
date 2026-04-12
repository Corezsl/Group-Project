import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/providers/search_provider.dart';
import 'package:thryft/widgets/product_card.dart';

const _kSearchCategories = [
  'Shirts',
  'Trousers',
  'Shoes',
  'Accessories',
  'Jackets',
  'Dresses',
];

class SearchScreen extends StatefulWidget {
  final String initialQuery;

  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  static const _sizes = [
    'XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL', 'One Size',
  ];

  static const _conditions = [
    'New',
    'Like New',
    'Good',
    'Fair',
    'Poor',
  ];

  static const _priceRanges = [
    'Under £25',
    '£25 – £50',
    '£50 – £100',
    '£100 – £250',
    'Over £250',
  ];

  static const _sortOptions = [
    ('newest', 'Newest first'),
    ('price_asc', 'Price: low to high'),
    ('price_desc', 'Price: high to low'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();

    if (widget.initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SearchProvider>().onQueryChanged(widget.initialQuery);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    context.read<SearchProvider>().clearResults();
    super.dispose();
  }

  void _onChanged(String value) {
    context.read<SearchProvider>().onQueryChanged(value);
  }

  void _onSubmitted(String value) {
    context.read<SearchProvider>().submitSearch(value);
    _focusNode.unfocus();
  }

  void _runRecentSearch(String query) {
    _controller.text = query;
    _controller.selection =
        TextSelection.collapsed(offset: query.length);
    context.read<SearchProvider>().submitSearch(query);
    _focusNode.unfocus();
  }

  void _clear() {
    _controller.clear();
    context.read<SearchProvider>().onQueryChanged('');
    _focusNode.requestFocus();
  }

  // Filter helpers 

  double? _minFromRange(String? range) {
    if (range == null) return null;
    if (range == '£25 – £50') return 25;
    if (range == '£50 – £100') return 50;
    if (range == '£100 – £250') return 100;
    if (range == 'Over £250') return 250;
    return null;
  }

  double? _maxFromRange(String? range) {
    if (range == null) return null;
    if (range == 'Under £25') return 25;
    if (range == '£25 – £50') return 50;
    if (range == '£50 – £100') return 100;
    if (range == '£100 – £250') return 250;
    return null;
  }

  String? _rangeFromFilters(SearchFilters f) {
    if (f.maxPrice == 25 && f.minPrice == null) return 'Under £25';
    if (f.minPrice == 25 && f.maxPrice == 50) return '£25 – £50';
    if (f.minPrice == 50 && f.maxPrice == 100) return '£50 – £100';
    if (f.minPrice == 100 && f.maxPrice == 250) return '£100 – £250';
    if (f.minPrice == 250 && f.maxPrice == null) return 'Over £250';
    return null;
  }

  void _applyFilter({
    Object? size = _kSentinel,
    Object? category = _kSentinel,
    Object? condition = _kSentinel,
    Object? priceRange = _kSentinel,
    String? sortBy,
  }) {
    final provider = context.read<SearchProvider>();
    final current = provider.filters;

    final resolvedPriceRange =
        priceRange == _kSentinel ? _rangeFromFilters(current) : priceRange as String?;

    provider.updateFilters(
      SearchFilters(
        size: size == _kSentinel ? current.size : size as String?,
        category: category == _kSentinel ? current.category : category as String?,
        condition: condition == _kSentinel ? current.condition : condition as String?,
        minPrice: _minFromRange(resolvedPriceRange),
        maxPrice: _maxFromRange(resolvedPriceRange),
        sortBy: sortBy ?? current.sortBy,
      ),
    );
  }

  // ── Build 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
              onSubmitted: _onSubmitted,
              onClear: _clear,
              onBack: () => context.pop(),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, provider, _) {
                  if (provider.query.isEmpty) {
                    return _IdleBody(
                      recentSearches: provider.recentSearches,
                      onRunSearch: _runRecentSearch,
                      onRemove: provider.removeRecentSearch,
                      onClearAll: provider.clearRecentSearches,
                      onCategoryTap: (cat) {
                        _controller.text = cat;
                        _onSubmitted(cat);
                      },
                    );
                  }

                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.results.isEmpty) {
                    return _EmptyResults(query: provider.query);
                  }

                  return _ResultsBody(
                    results: provider.results,
                    query: provider.query,
                    filters: provider.filters,
                    sizes: _sizes,
                    conditions: _conditions,
                    priceRanges: _priceRanges,
                    sortOptions: _sortOptions,
                    currentPriceRange: _rangeFromFilters(provider.filters),
                    onSizeChanged: (v) => _applyFilter(size: v),
                    onCategoryChanged: (v) => _applyFilter(category: v),
                    onConditionChanged: (v) => _applyFilter(condition: v),
                    onPriceChanged: (v) => _applyFilter(priceRange: v),
                    onSortChanged: (v) {
                      if (v != null) _applyFilter(sortBy: v);
                    },
                    onClearFilters: provider.clearFilters,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: constant_identifier_names
const _kSentinel = Object();

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onBack;

  static const _brandBlue = Color.fromARGB(255, 71, 164, 245);

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: _brandBlue,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: false,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search for items, brands...',
                hintStyle: const TextStyle(color: Colors.white70, fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (_, value, __) => value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: onClear,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Idle body (no query yet) ──────────────────────────────────────────────────

class _IdleBody extends StatelessWidget {
  final List<String> recentSearches;
  final ValueChanged<String> onRunSearch;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;
  final ValueChanged<String> onCategoryTap;


  const _IdleBody({
    required this.recentSearches,
    required this.onRunSearch,
    required this.onRemove,
    required this.onClearAll,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        if (recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent searches',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              TextButton(
                onPressed: onClearAll,
                child: const Text('Clear all', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...recentSearches.map(
            (q) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, size: 18, color: Colors.grey),
              title: Text(q, style: const TextStyle(fontSize: 14)),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                onPressed: () => onRemove(q),
              ),
              onTap: () => onRunSearch(q),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 20),
        ],
        const Text(
          'Browse categories',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kSearchCategories
              .map(
                (cat) => ActionChip(
                  label: Text(cat),
                  onPressed: () => onCategoryTap(cat),
                  backgroundColor: const Color(0xFFF3F4F6),
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ── Empty results ─────────────────────────────────────────────────────────────

class _EmptyResults extends StatelessWidget {
  final String query;

  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 72,
                color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different spelling, brand name, or browse by category.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Results body ──────────────────────────────────────────────────────────────

class _ResultsBody extends StatelessWidget {
  final List<Product> results;
  final String query;
  final SearchFilters filters;
  final List<String> sizes;
  final List<String> conditions;
  final List<String> priceRanges;
  final List<(String, String)> sortOptions;
  final String? currentPriceRange;
  final ValueChanged<String?> onSizeChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onConditionChanged;
  final ValueChanged<String?> onPriceChanged;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback onClearFilters;

  const _ResultsBody({
    required this.results,
    required this.query,
    required this.filters,
    required this.sizes,
    required this.conditions,
    required this.priceRanges,
    required this.sortOptions,
    required this.currentPriceRange,
    required this.onSizeChanged,
    required this.onCategoryChanged,
    required this.onConditionChanged,
    required this.onPriceChanged,
    required this.onSortChanged,
    required this.onClearFilters,
  });

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> options,
    required String Function(T) display,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Text('All',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 18, color: Color(0xFF111827)),
              borderRadius: BorderRadius.circular(8),
              items: [
                DropdownMenuItem<T>(
                  value: null,
                  child: const Text('All', style: TextStyle(fontSize: 13)),
                ),
                ...options.map(
                  (o) => DropdownMenuItem<T>(
                    value: o,
                    child:
                        Text(display(o), style: const TextStyle(fontSize: 13)),
                  ),
                ),
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
    final sortLabel = sortOptions
        .firstWhere(
          (e) => e.$1 == filters.sortBy,
          orElse: () => sortOptions.first,
        )
        .$2;

    return CustomScrollView(
      slivers: [
        // ── Result count + clear filters ─────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Text(
                  '${results.length} result${results.length == 1 ? '' : 's'} for "$query"',
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13),
                ),
                const Spacer(),
                if (filters.hasActiveFilters)
                  TextButton(
                    onPressed: onClearFilters,
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0)),
                    child: const Text('Clear filters',
                        style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ),
        ),
        // ── Filter dropdowns ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _dropdown<String>(
                  label: 'SIZE',
                  value: filters.size,
                  options: sizes,
                  display: (s) => s,
                  onChanged: onSizeChanged,
                ),
                const SizedBox(width: 20),
                _dropdown<String>(
                  label: 'CONDITION',
                  value: filters.condition,
                  options: conditions,
                  display: (s) => s,
                  onChanged: onConditionChanged,
                ),
                const SizedBox(width: 20),
                _dropdown<String>(
                  label: 'PRICE',
                  value: currentPriceRange,
                  options: priceRanges,
                  display: (s) => s,
                  onChanged: onPriceChanged,
                ),
                const SizedBox(width: 20),
                _dropdown<String>(
                  label: 'SORT',
                  value: sortLabel,
                  options: sortOptions.map((e) => e.$2).toList(),
                  display: (s) => s,
                  onChanged: (label) {
                    if (label == null) {
                      onSortChanged('newest');
                    } else {
                      final match = sortOptions.firstWhere(
                        (e) => e.$2 == label,
                        orElse: () => sortOptions.first,
                      );
                      onSortChanged(match.$1);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        ),
        // ── Product grid ─────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisExtent: 240,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(product: results[index]),
              childCount: results.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
