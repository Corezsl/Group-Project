import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/providers/cart_provider.dart';
import 'package:thryft/providers/wishlist_provider.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/providers/interaction_service.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/providers/offer_provider.dart';
import 'package:thryft/models/notification_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, String> product;

  const ProductDetailScreen({super.key, required this.product});

  static const Color brandColor = Color.fromARGB(255, 71, 164, 245);

  // Fixed: Defined the missing helper method
  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800;

  @override
  Widget build(BuildContext context) {
    InteractionService().logInteraction(
      productId: product['id'] ?? '',
      type: 'view',
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              final id = product['id'] ?? '';
              final uri = Uri.base.resolve('/product/$id').toString();
              Clipboard.setData(ClipboardData(text: uri));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
          ),
          Consumer<WishlistProvider>(
            builder: (context, wishlist, _) {
              final wishlisted = wishlist.isWishlisted(product['id'] ?? '');
              return IconButton(
                icon: Icon(
                  wishlisted ? Icons.favorite : Icons.favorite_border,
                  color: wishlisted ? Colors.red : null,
                ),
                onPressed: () {
                  wishlist.toggleWishlist(
                    Product(
                      id: product['id'] ?? '',
                      name: product['name'] ?? '',
                      price: double.tryParse(product['price'] ?? '0') ?? 0,
                      size: product['size'] ?? '',
                      brand: product['brand'] ?? '',
                      condition: product['condition'] ?? '',
                      imageUrl: product['imageUrl'],
                      sellerId: product['sellerId'],
                      sellerName: product['sellerName'],
                      category: product['category'] ?? 'Other',
                      department: product['department'] ?? 'All',
                      material: product['material'] ?? '',
                      colour: product['colour'] ?? '',
                      description: product['description'],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktopView = constraints.maxWidth >= 800;

          if (isDesktopView) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    color: Colors.white,
                    child: _buildImageGallery(context),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: _buildInfoPanel(context),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImageGallery(context),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildInfoPanel(context),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    final allImages = [
      product['imageUrl'],
      product['image_url_2'],
      product['image_url_3'],
      product['image_url_4'],
      product['image_url_5'],
    ].where((u) => u != null && u.isNotEmpty).cast<String>().toList();

    if (allImages.isEmpty) {
      return Hero(
        tag: product['heroTag'] ?? 'product_image_${product['id'] ?? product['name']}',
        child: Container(
          height: 400,
          width: double.infinity,
          color: Colors.grey[100],
          child: const Icon(Icons.image, size: 100, color: Colors.grey),
        ),
      );
    }

    // Single image — no PageView needed
    if (allImages.length == 1) {
      return Hero(
        tag: product['heroTag'] ?? 'product_image_${product['id'] ?? product['name']}',
        child: Container(
          height: 400,
          width: double.infinity,
          color: Colors.grey[100],
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.network(allImages[0], fit: BoxFit.contain),
              if (product['is_sold'] == 'true') _buildSoldOverlay(context),
            ],
          ),
        ),
      );
    }

    // Multiple images — use ValueNotifier for selected index
    final indexNotifier = ValueNotifier<int>(0);

    return Hero(
      tag: product['heroTag'] ?? 'product_image_${product['id'] ?? product['name']}',
      child: ValueListenableBuilder<int>(
        valueListenable: indexNotifier,
        builder: (context, currentIndex, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 400,
              width: double.infinity,
              color: Colors.grey[100],
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(allImages[currentIndex], fit: BoxFit.contain),
                  if (product['is_sold'] == 'true') _buildSoldOverlay(context),
                  // Left arrow
                  if (currentIndex > 0)
                    Positioned(
                      left: 8,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, size: 32),
                        color: Colors.black87,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.8),
                        ),
                        onPressed: () => indexNotifier.value = currentIndex - 1,
                      ),
                    ),
                  // Right arrow
                  if (currentIndex < allImages.length - 1)
                    Positioned(
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right, size: 32),
                        color: Colors.black87,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.8),
                        ),
                        onPressed: () => indexNotifier.value = currentIndex + 1,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(allImages.length, (i) => GestureDetector(
                  onTap: () => indexNotifier.value = i,
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.network(
                      allImages[i],
                      fit: BoxFit.cover,
                    ),
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoldOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        'SOLD',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 4.0,
        ),
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product['name'] ?? 'Unknown Item',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "${product['size'] ?? 'N/A'} • ${product['condition'] ?? 'N/A'} • ${product['brand'] ?? 'Unbranded'}",
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 16),
        if (product['originalPrice'] != null)
          Text(
            "£${product['originalPrice']}",
            style: TextStyle(
              color: Colors.grey[500],
              decoration: TextDecoration.lineThrough,
              fontSize: 14,
            ),
          ),
        Text(
          "£${product['price'] ?? '0.00'}",
          style: const TextStyle(
            color: brandColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 16),
        _buildDetailRow("Brand", product['brand'] ?? '-', isLink: true),
        const SizedBox(height: 12),
        _buildDetailRow("Department", product['department'] ?? '-'),
        const SizedBox(height: 12),
        _buildDetailRow("Size", product['size'] ?? '-'),
        const SizedBox(height: 12),
        _buildDetailRow("Condition", product['condition'] ?? '-'),
        const SizedBox(height: 24),
        if (product['description'] != null && product['description']!.isNotEmpty) ...[
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            product['description']!,
            style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
        ],

        // Action Buttons with logic for single items [cite: 2026-02-20]
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            final currentUser = Supabase.instance.client.auth.currentUser;
            final isOwner =
                currentUser != null && product['sellerId'] == currentUser.id;
            final isSold = product['is_sold'] == 'true';
            final isInCart = cart.isInCart(product['id'] ?? '');

            if (isSold) {
              return _buildFullWidthBanner(
                Icons.sell_outlined,
                'This item has been sold',
                Colors.grey[600]!,
                Colors.grey[100]!,
              );
            }

            if (isOwner) {
              return _buildOwnerActions(context);
            }

            return Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: isInCart
                      ? _buildFullWidthBanner(
                          Icons.shopping_cart,
                          'Already in cart',
                          brandColor,
                          brandColor.withOpacity(0.05),
                          borderColor: brandColor.withOpacity(0.2),
                        )
                      : FilledButton(
                          onPressed: () => _addItemToCart(context, cart),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: brandColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            "Add to cart",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                _buildSecondaryButton(
                    "Make an offer", () => _showOfferDialog(context)),
              ],
            );
          },
        ),

        const SizedBox(height: 32),
        _buildBuyerProtectionBox(),
        const SizedBox(height: 32),
        _buildSellerProfile(context),
        const SizedBox(height: 40),
        if (!_isDesktop(context)) const Footer(),
      ],
    );
  }

  void _addItemToCart(BuildContext context, CartProvider cart) {
    cart.addItem(
      Product(
        id: product['id'] ?? product['name']!,
        name: product['name'] ?? 'Product',
        price: double.tryParse(product['price'] ?? '0') ?? 0,
        originalPrice: product['originalPrice'] != null
            ? double.tryParse(product['originalPrice']!)
            : null,
        size: product['size'] ?? '',
        brand: product['brand'] ?? '',
        condition: product['condition'] ?? '',
        imageUrl: product['imageUrl'],
        category: product['category'] ?? 'Other',
        department: product['department'] ?? 'All',
        material: product['material'] ?? '',
        colour: product['colour'] ?? '',
        description: product['description'],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => context.push('/cart'),
        ),
      ),
    );
  }

  Widget _buildFullWidthBanner(
    IconData icon,
    String label,
    Color textColor,
    Color bgColor, {
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => context.push('/create-listing', extra: product),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: brandColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              "Edit listing",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _confirmAndDelete(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Delete listing', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete listing'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    //Deletes product from backend.
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    final id = product['id'];
    try {
      if (id != null && currentUser != null) {
        await supabase
            .from('products')
            .delete()
            .eq('id', id)
            .eq('user_id', currentUser.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
        context.go('/my-listings');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting product: $e')));
      }
    }
  }

  void _showOfferDialog(BuildContext context) {
    final sellerId = product['sellerId'];
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make an offer')),
      );
      context.push('/auth');
      return;
    }
    if (sellerId == null || sellerId == currentUser.id) return;

    final priceController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Make an Offer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Listed price: £${product['price']}'),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Your offer (£)',
                  border: OutlineInputBorder(),
                  prefixText: '£',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final offerPrice = double.tryParse(priceController.text.trim());
                      final listingPrice = double.tryParse(product['price'] ?? '');
                      if (offerPrice == null || offerPrice <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter a valid offer price')),
                        );
                        return;
                      }
                      if (listingPrice != null && offerPrice >= listingPrice) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Your offer must be less than the listed price of £${listingPrice.toStringAsFixed(2)}',
                            ),
                          ),
                        );
                        return;
                      }
                      setDialogState(() => isSending = true);
                      try {
                        // Prevent duplicate pending offers.
                        final alreadyPending = await OfferProvider.hasPendingOffer(
                          buyerId: currentUser.id,
                          listingId: product['id'] ?? '',
                        );
                        if (alreadyPending) {
                          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You already have a pending offer on this item.'),
                              ),
                            );
                          }
                          return;
                        }

                        // Record the offer in the offers table.
                        await OfferProvider.createOffer(
                          buyerId: currentUser.id,
                          sellerId: sellerId,
                          listingId: product['id'] ?? '',
                          offerAmount: offerPrice,
                          listingTitle: product['name'],
                          listingImageUrl: product['imageUrl'],
                        );

                        // Notify the seller.
                        await NotificationProvider.insertNotification(
                          userId: sellerId,
                          type: NotificationType.offerReceived,
                          content:
                              '${currentUser.userMetadata?['username'] ?? currentUser.email ?? 'Someone'} offered £${offerPrice.toStringAsFixed(2)} for "${product['name']}"',
                          listingId: product['id'],
                          relatedUserId: currentUser.id,
                          offerPrice: offerPrice,
                        );

                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Offer sent!')),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSending = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to send offer: $e')),
                          );
                        }
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Offer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          foregroundColor: brandColor,
          side: const BorderSide(color: brandColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String key, String value, {bool isLink = false}) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            key,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isLink ? brandColor : Colors.black87,
              fontWeight: isLink ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBuyerProtectionBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield, color: brandColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Buyer Protection fee",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "Includes our Refund Policy and helps keep our community safe.",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchSellerRating(String sellerId) async {
    final data = await Supabase.instance.client
        .from('ratings')
        .select('rating')
        .eq('seller_id', sellerId);
    final list = data as List;
    if (list.isEmpty) return {'avg': 0.0, 'count': 0};
    final avg = list
            .map((r) => (r['rating'] as num).toDouble())
            .reduce((a, b) => a + b) /
        list.length;
    return {'avg': avg, 'count': list.length};
  }

  Widget _buildSellerProfile(BuildContext context) {
    if (product['sellerId'] == null) return const SizedBox.shrink();
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchSellerRating(product['sellerId']!),
      builder: (context, snapshot) {
        final count = snapshot.data?['count'] as int? ?? 0;
        final avg = snapshot.data?['avg'] as double? ?? 0.0;

        return InkWell(
          onTap: () => context.push('/user/${product['sellerId']}'),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.grey, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['sellerName'] ?? 'Unknown Seller',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (count == 0)
                        Text(
                          'No reviews yet',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${avg.toStringAsFixed(1)} ($count)',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
