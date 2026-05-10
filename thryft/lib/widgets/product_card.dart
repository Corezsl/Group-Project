import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/providers/wishlist_provider.dart';

// Single product tile shown across home carousels, search results, listings,
// orders, wishlist etc. Renders the image, seller, brand/size/price, a SOLD
// overlay if applicable, and a wishlist heart button.
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Must be unique within the current route subtree to avoid Hero tag collisions
    // when the same product appears in multiple carousels/sections.
    final heroTag = 'product_image_${product.id}_${identityHashCode(this)}';

    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          // tapping the card opens the product detail page, passing the heroTag
          // through so the image transition lines up with the same Hero on the next screen
          onTap: () {
            context.push(
              '/product/${product.id}',
              extra: {
                ...product.toRouteExtra(),
                'heroTag': heroTag,
              },
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Seller Info ─────────────────────────────────────────
              if (product.sellerName != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.person, size: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          product.sellerName!,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // ── Image area ──────────────────────────────────────────
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // product image — darkened with a black blend if sold
                    Hero(
                      tag: heroTag,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: product.imageUrl != null
                            ? Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                color: product.isSold
                                    ? Colors.black.withValues(alpha: 0.35)
                                    : null,
                                colorBlendMode: product.isSold
                                    ? BlendMode.darken
                                    : null,
                              )
                            // fallback when there's no image url
                            : const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    // SOLD overlay badge
                    if (product.isSold)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SOLD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    // Wishlist button (hidden for sold items in orders).
                    // Consumer rebuilds just the heart icon when the wishlist state changes.
                    if (!product.isSold)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Consumer<WishlistProvider>(
                            builder: (context, wishlist, _) {
                              final wishlisted = wishlist.isWishlisted(product.id);
                              return IconButton(
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  wishlisted ? Icons.favorite : Icons.favorite_border,
                                  size: 20,
                                  color: wishlisted ? Colors.red : Colors.grey,
                                ),
                                onPressed: () => wishlist.toggleWishlist(product),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Text content ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand
                    Text(
                      product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // ── Description row: size · condition ──────
                    Text(
                      '${product.size} · ${product.condition}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),

                    // ── Price row ──────────────────────────────────────
                    // shows current price, the crossed-out original if reduced, and a "Sold" label if sold
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // Current price (always shown) — red if there's a price drop, grey if sold
                        Text(
                          '£${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: product.isSold
                                ? Colors.grey[500]
                                : (product.originalPrice != null
                                    ? Colors.red[700]
                                    : Colors.black87),
                          ),
                        ),
                        // Strikethrough original price (only when reduced and not sold)
                        if (product.originalPrice != null && !product.isSold) ...[
                          const SizedBox(width: 5),
                          Text(
                            '£${product.originalPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                        // SOLD label inline
                        if (product.isSold) ...[
                          const SizedBox(width: 6),
                          Text(
                            'Sold',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Buyer address summary (sold items only)
                    if (product.isSold && product.buyerAddress != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.buyerAddress!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
