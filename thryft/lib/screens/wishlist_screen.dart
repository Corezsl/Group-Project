import 'package:flutter/material.dart';
import 'package:thryft/models/product.dart';

// ── In-memory wishlist state (persists for app lifetime) ──────────────────────
final Set<String> _wishlistedIds = {
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '10',
};

// ── Shared product catalogue ──────────────────────────────────────────────────
const List<Product> kAllProducts = [
  Product(
    id: '1',
    name: 'Vintage Denim Jacket',
    price: 24.99,
    originalPrice: 39.99,
    size: 'M',
    brand: "Levi's",
    condition: 'Good',
  ),
  Product(
    id: '2',
    name: 'White Sneakers',
    price: 18.00,
    size: '42',
    brand: 'Nike',
    condition: 'Like New',
  ),
  Product(
    id: '3',
    name: 'Floral Summer Dress',
    price: 12.50,
    originalPrice: 22.00,
    size: 'S',
    brand: 'Zara',
    condition: 'Like New',
  ),
  Product(
    id: '4',
    name: 'Wool Coat',
    price: 45.00,
    size: 'L',
    brand: 'H&M',
    condition: 'Good',
  ),
  Product(
    id: '5',
    name: 'Leather Belt',
    price: 8.00,
    size: 'One Size',
    brand: 'Unbranded',
    condition: 'Fair',
  ),
  Product(
    id: '6',
    name: 'Graphic Tee',
    price: 6.99,
    originalPrice: 14.99,
    size: 'XL',
    brand: 'ASOS',
    condition: 'Good',
  ),
  Product(
    id: '7',
    name: 'Chino Trousers',
    price: 15.00,
    size: '32',
    brand: 'Gap',
    condition: 'Like New',
  ),
  Product(
    id: '8',
    name: 'Puffer Jacket',
    price: 30.00,
    size: 'M',
    brand: 'The North Face',
    condition: 'Good',
  ),
  Product(
    id: '9',
    name: 'Silk Blouse',
    price: 10.00,
    size: 'S',
    brand: 'Reiss',
    condition: 'Like New',
  ),
  Product(
    id: '10',
    name: 'Running Shoes',
    price: 22.00,
    originalPrice: 35.00,
    size: '40',
    brand: 'Adidas',
    condition: 'Good',
  ),
];

// ── Enums ─────────────────────────────────────────────────────────────────────
enum PriceSortOption { none, lowToHigh, highToLow }

enum SavedSortOption { newest, oldest }

// ── WishlistPage ──────────────────────────────────────────────────────────────
class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final Set<String> _selectedSizes = {};
  PriceSortOption _priceSort = PriceSortOption.none;
  SavedSortOption _savedSort = SavedSortOption.newest;

  List<String> get _availableSizes {
    final sizes = kAllProducts
        .where((p) => _wishlistedIds.contains(p.id))
        .map((p) => p.size)
        .toSet()
        .toList();
    sizes.sort();
    return sizes;
  }

  List<Product> get _filteredProducts {
    List<Product> items = kAllProducts
        .where((p) => _wishlistedIds.contains(p.id))
        .toList();

    if (_selectedSizes.isNotEmpty) {
      items = items.where((p) => _selectedSizes.contains(p.size)).toList();
    }

    if (_priceSort == PriceSortOption.lowToHigh) {
      items.sort((a, b) => a.price.compareTo(b.price));
    } else if (_priceSort == PriceSortOption.highToLow) {
      items.sort((a, b) => b.price.compareTo(a.price));
    } else {
      final ids = _wishlistedIds.toList();
      if (_savedSort == SavedSortOption.newest) {
        items.sort((a, b) => ids.indexOf(b.id).compareTo(ids.indexOf(a.id)));
      } else {
        items.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
      }
    }

    return items;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedSizes.isNotEmpty) count++;
    if (_priceSort != PriceSortOption.none) count++;
    return count;
  }

  void _toggleWishlist(String id) {
    setState(() {
      if (_wishlistedIds.contains(id)) {
        _wishlistedIds.remove(id);
        _selectedSizes.removeWhere((s) => !_availableSizes.contains(s));
      } else {
        _wishlistedIds.add(id);
      }
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        availableSizes: _availableSizes,
        selectedSizes: Set.from(_selectedSizes),
        priceSort: _priceSort,
        savedSort: _savedSort,
        onApply: (sizes, price, saved) {
          setState(() {
            _selectedSizes
              ..clear()
              ..addAll(sizes);
            _priceSort = price;
            _savedSort = saved;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = _filteredProducts;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        title: const Text(
          'Wishlist',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: _showFilterSheet,
                tooltip: 'Filters',
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_activeFilterCount',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedSizes.isNotEmpty || _priceSort != PriceSortOption.none)
            _ActiveFilterChips(
              selectedSizes: _selectedSizes,
              priceSort: _priceSort,
              onRemoveSize: (s) => setState(() => _selectedSizes.remove(s)),
              onRemovePrice: () =>
                  setState(() => _priceSort = PriceSortOption.none),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '${items.length} ${items.length == 1 ? 'item' : 'items'}',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),

          Expanded(
            child: items.isEmpty
                ? _EmptyState(hasFilters: _activeFilterCount > 0)
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 210,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _WishlistCard(
                        product: items[index],
                        onRemove: () => _toggleWishlist(items[index].id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Wishlist Card ─────────────────────────────────────────────────────────────
class _WishlistCard extends StatelessWidget {
  final Product product;
  final VoidCallback onRemove;

  const _WishlistCard({required this.product, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Image area ────────────────────────────────────────────
        SizedBox(
          height: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _PlaceholderImage(colorScheme: colorScheme),
                      )
                    : _PlaceholderImage(colorScheme: colorScheme),
              ),

              // Heart remove button
              Positioned(
                bottom: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.favorite, color: Colors.red, size: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Text content ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.brand,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                '${product.size} · ${product.condition}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '£${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: product.originalPrice != null
                          ? Colors.red[700]
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (product.originalPrice != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '£${product.originalPrice!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Placeholder image ─────────────────────────────────────────────────────────
class _PlaceholderImage extends StatelessWidget {
  final ColorScheme colorScheme;
  const _PlaceholderImage({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorScheme.surfaceVariant,
      child: Icon(
        Icons.checkroom_rounded,
        size: 48,
        color: colorScheme.onSurfaceVariant.withOpacity(0.4),
      ),
    );
  }
}

// ── Active Filter Chips ───────────────────────────────────────────────────────
class _ActiveFilterChips extends StatelessWidget {
  final Set<String> selectedSizes;
  final PriceSortOption priceSort;
  final ValueChanged<String> onRemoveSize;
  final VoidCallback onRemovePrice;

  const _ActiveFilterChips({
    required this.selectedSizes,
    required this.priceSort,
    required this.onRemoveSize,
    required this.onRemovePrice,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ...selectedSizes.map(
            (size) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('Size: $size'),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => onRemoveSize(size),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          if (priceSort != PriceSortOption.none)
            Chip(
              label: Text(
                priceSort == PriceSortOption.lowToHigh
                    ? 'Price: Low → High'
                    : 'Price: High → Low',
              ),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: onRemovePrice,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off_rounded : Icons.favorite_border,
            size: 72,
            color: colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'No items match your filters'
                : 'Your wishlist is empty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting or clearing your filters'
                : 'Tap the ♡ on any item to save it here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final List<String> availableSizes;
  final Set<String> selectedSizes;
  final PriceSortOption priceSort;
  final SavedSortOption savedSort;
  final void Function(Set<String>, PriceSortOption, SavedSortOption) onApply;

  const _FilterSheet({
    required this.availableSizes,
    required this.selectedSizes,
    required this.priceSort,
    required this.savedSort,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<String> _sizes;
  late PriceSortOption _price;
  late SavedSortOption _saved;

  @override
  void initState() {
    super.initState();
    _sizes = Set.from(widget.selectedSizes);
    _price = widget.priceSort;
    _saved = widget.savedSort;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _sizes.clear();
                  _price = PriceSortOption.none;
                  _saved = SavedSortOption.newest;
                }),
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Size',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          widget.availableSizes.isEmpty
              ? Text(
                  'No sizes available',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 13,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: widget.availableSizes.map((size) {
                    final selected = _sizes.contains(size);
                    return FilterChip(
                      label: Text(size),
                      selected: selected,
                      onSelected: (val) => setState(
                        () => val ? _sizes.add(size) : _sizes.remove(size),
                      ),
                      selectedColor: colorScheme.primary.withOpacity(0.15),
                      checkmarkColor: colorScheme.primary,
                      labelStyle: TextStyle(
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 20),

          Text(
            'Price',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Low to High'),
                selected: _price == PriceSortOption.lowToHigh,
                onSelected: (val) => setState(
                  () => _price = val
                      ? PriceSortOption.lowToHigh
                      : PriceSortOption.none,
                ),
                selectedColor: colorScheme.primary.withOpacity(0.15),
              ),
              ChoiceChip(
                label: const Text('High to Low'),
                selected: _price == PriceSortOption.highToLow,
                onSelected: (val) => setState(
                  () => _price = val
                      ? PriceSortOption.highToLow
                      : PriceSortOption.none,
                ),
                selectedColor: colorScheme.primary.withOpacity(0.15),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'Saved Order',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Newest First'),
                selected: _saved == SavedSortOption.newest,
                onSelected: (_) =>
                    setState(() => _saved = SavedSortOption.newest),
                selectedColor: colorScheme.primary.withOpacity(0.15),
              ),
              ChoiceChip(
                label: const Text('Oldest First'),
                selected: _saved == SavedSortOption.oldest,
                onSelected: (_) =>
                    setState(() => _saved = SavedSortOption.oldest),
                selectedColor: colorScheme.primary.withOpacity(0.15),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(_sizes, _price, _saved);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
