import 'package:flutter/material.dart';
import 'package:thryft/providers/recommendation_provider.dart';
import 'package:thryft/widgets/product_card.dart';

class RecommendedProductsSection extends StatefulWidget {
  final RecommendationProvider provider;
  final String title;
  final int limit;

  const RecommendedProductsSection({
    super.key,
    required this.provider,
    this.title = 'Recommended for you',
    this.limit = 20,
  });

  @override
  State<RecommendedProductsSection> createState() =>
      _RecommendedProductsSectionState();
}

class _RecommendedProductsSectionState extends State<RecommendedProductsSection> {
  final ScrollController _scrollController = ScrollController();
  static const double _scrollAmount = 344;

  @override
  void initState() {
    super.initState();
    // Fire and forget; provider exposes loading/error state.
    widget.provider.refresh(limit: widget.limit);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      (_scrollController.offset - _scrollAmount).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      (_scrollController.offset + _scrollAmount).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final products = p.products;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: p.isLoading ? null : () => p.refresh(limit: widget.limit),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 280,
          child: Builder(
            builder: (context) {
              if (p.isLoading && products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (p.error != null && products.isEmpty) {
                return Center(child: Text('Error loading recommendations.'));
              }
              if (products.isEmpty) {
                return const Center(
                  child: Text(
                    'No recommendations yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 32),
                    onPressed: _scrollLeft,
                    color: Colors.black87,
                  ),
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      controller: _scrollController,
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return ProductCard(product: products[index]);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 32),
                    onPressed: _scrollRight,
                    color: Colors.black87,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

