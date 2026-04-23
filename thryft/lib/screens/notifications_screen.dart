import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/notification_model.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Header(),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE5E7EB),
                      ),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 40,
                              horizontal: 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notifications',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 24),
                                if (provider.isLoading)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else if (provider.notifications.isEmpty)
                                  _buildEmptyState()
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: provider.notifications.length,
                                    separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      color: Color(0xFFE5E7EB),
                                    ),
                                    itemBuilder: (context, index) =>
                                        _buildNotificationTile(
                                          context,
                                          provider,
                                          provider.notifications[index],
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Footer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationProvider provider,
    AppNotification notif,
  ) {
    final isTappable = notif.listingId != null &&
        notif.notifType != NotificationType.offerReceived;

    return InkWell(
      onTap: isTappable ? () => _navigateToListing(context, notif) : null,
      child: Container(
        color: notif.isRead ? Colors.white : const Color(0xFFF0F7FF),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(notif.notifType),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.content,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: notif.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(notif.createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    if (notif.notifType == NotificationType.listingSold &&
                        notif.buyerAddress != null)
                      _buildShippingAddress(notif.buyerAddress!),
                    if (notif.notifType == NotificationType.offerReceived)
                      _buildOfferActions(context, provider, notif),
                    if ((notif.notifType == NotificationType.offerAccepted ||
                            notif.notifType == NotificationType.offerDeclined) &&
                        notif.listingId != null)
                      _buildViewOfferLink(context, notif),
                  ],
                ),
              ),
              if (!notif.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4, left: 8),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 71, 164, 245),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(NotificationType type) {
    final (IconData icon, Color color) = switch (type) {
      NotificationType.listingSold => (Icons.sell_outlined, Colors.green),
      NotificationType.wishlistAdd => (Icons.favorite_outline, Colors.pink),
      NotificationType.wishlistPurchased => (
        Icons.shopping_bag_outlined,
        Colors.orange,
      ),
      NotificationType.offerReceived => (
        Icons.local_offer_outlined,
        Colors.purple,
      ),
      NotificationType.offerAccepted => (
        Icons.check_circle_outline,
        Colors.green,
      ),
      NotificationType.offerDeclined => (
        Icons.cancel_outlined,
        Colors.red,
      ),
      _ => (Icons.notifications_outlined, Colors.grey),
    };

    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildShippingAddress(String address) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.local_shipping_outlined, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Ship to: $address',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOfferLink(BuildContext context, AppNotification notif) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: () => _navigateToListing(context, notif),
        child: Text(
          'View listing →',
          style: TextStyle(
            color: const Color.fromARGB(255, 71, 164, 245),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOfferActions(
    BuildContext context,
    NotificationProvider provider,
    AppNotification notif,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          FilledButton(
            onPressed: () => _handleAccept(context, provider, notif),
            style: FilledButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 71, 164, 245),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Accept'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _handleDecline(context, provider, notif),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept(
    BuildContext context,
    NotificationProvider provider,
    AppNotification notif,
  ) async {
    try {
      await provider.acceptOffer(notif);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer accepted. Item marked as sold.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final message = e.toString().contains('already_sold')
            ? 'This item is already sold.'
            : e.toString().contains('offer_not_found')
                ? 'This offer is no longer pending.'
                : 'Failed to accept offer. Try again.';        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _handleDecline(
    BuildContext context,
    NotificationProvider provider,
    AppNotification notif,
  ) async {
    try {
      await provider.declineOffer(notif);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer declined.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final message = e.toString().contains('offer_not_found')
            ? 'This offer is no longer pending.'
            : 'Failed to decline offer. Try again.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _navigateToListing(
      BuildContext context, AppNotification notif) async {
    if (notif.listingId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('products')
          .select('*, profiles(username)')
          .eq('id', notif.listingId!)
          .maybeSingle();

      if (data == null || !context.mounted) return;

      final product = <String, String>{
        'id': data['id'].toString(),
        'name': data['name']?.toString() ?? '',
        'price': data['price']?.toString() ?? '0',
        'originalPrice': data['original_price']?.toString() ?? '',
        'size': data['size']?.toString() ?? '',
        'brand': data['brand']?.toString() ?? '',
        'condition': data['condition']?.toString() ?? '',
        'imageUrl': data['image_url']?.toString() ?? '',
        'sellerId': data['user_id']?.toString() ?? '',
        'sellerName': (data['profiles'] as Map?)?['username']?.toString() ?? '',
        'category': data['category']?.toString() ?? 'Other',
        'department': data['department']?.toString() ?? 'All',
        'material': data['material']?.toString() ?? '',
        'colour': data['colour']?.toString() ?? '',
        'isSold': (data['is_sold'] == true).toString(),
      };

      if (context.mounted) {
        context.push('/product/${notif.listingId}', extra: product);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load listing.')),
        );
      }
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
