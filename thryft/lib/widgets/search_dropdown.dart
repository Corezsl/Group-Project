import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thryft/providers/search_provider.dart';

// Dropdown panel that hangs off the search bar in the Header.
// Shows recent searches when idle, a spinner while loading, and product
// matches once the user types. Tapping outside closes it.
class SearchDropdown extends StatelessWidget {
  // links the dropdown's position to the search bar above it (CompositedTransformFollower)
  final LayerLink layerLink;
  // the search bar's controller so tapping a recent search can refill it
  final TextEditingController controller;
  // matches the search bar's width so the dropdown lines up nicely
  final double dropdownWidth;
  // closes the overlay (used by the outside-tap barrier and after navigating)
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
        // anchors the dropdown directly below the search bar
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
                      // pick which view to show based on the provider state
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

  // shown when the search bar is empty — either a hint or the recent searches list
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
        // cap at 5 so the dropdown doesnt get too long
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
                // tapping a recent search refills the search bar and re-runs the query
                onTap: () {
                  controller.text = q;
                  provider.onQueryChanged(q);
                },
              ),
            ),
      ],
    );
  }

  // shown when the user has typed something and matching products came back
  Widget _buildResults(BuildContext context, SearchProvider provider) {
    // only show top 5 hits so the dropdown stays compact — full results live on the search screen
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
            // close the dropdown then push to the product detail page
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
