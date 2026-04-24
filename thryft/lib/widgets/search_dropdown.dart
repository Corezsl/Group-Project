import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thryft/providers/search_provider.dart';

class SearchDropdown extends StatelessWidget {
  final LayerLink layerLink;
  final TextEditingController controller;
  final double dropdownWidth;
  final VoidCallback onDismiss;
  final VoidCallback onNavigate;

  const SearchDropdown({
    super.key,
    required this.layerLink,
    required this.controller,
    required this.dropdownWidth,
    required this.onDismiss,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-screen barrier: tap outside dismisses
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          showWhenUnlinked: false,
          child: GestureDetector(
            // Absorb taps so they don't hit the barrier above
            onTap: () {},
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: dropdownWidth,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 380),
                  child: Consumer<SearchProvider>(
                    builder: (context, provider, _) {
                      if (provider.query.isEmpty) {
                        return _buildIdle(context, provider);
                      }
                      if (provider.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      if (provider.results.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No results for "${provider.query}"',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        );
                      }
                      return _buildResults(context, provider);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdle(BuildContext context, SearchProvider provider) {
    if (provider.recentSearches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Start typing to search...',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent searches',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              TextButton(
                onPressed: provider.clearRecentSearches,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Clear all', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        ...provider.recentSearches
            .take(5)
            .map(
              (q) => ListTile(
                dense: true,
                leading: const Icon(
                  Icons.history,
                  size: 18,
                  color: Colors.grey,
                ),
                title: Text(q, style: const TextStyle(fontSize: 14)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  onPressed: () => provider.removeRecentSearch(q),
                ),
                onTap: () {
                  controller.text = q;
                  provider.onQueryChanged(q);
                },
              ),
            ),
      ],
    );
  }

  Widget _buildResults(BuildContext context, SearchProvider provider) {
    final shown = provider.results.take(5).toList();
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ...shown.map(
          (product) => ListTile(
            dense: true,
            leading: SizedBox(
              width: 36,
              height: 36,
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported,
                          size: 24,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.image_not_supported,
                      size: 24,
                      color: Colors.grey,
                    ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '£${product.price.toStringAsFixed(2)} · ${product.brand}',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              onDismiss();
              context.push(
                '/product/${product.id}',
                extra: product.toRouteExtra(),
              );
            },
          ),
        ),
      ],
    );
  }
}
