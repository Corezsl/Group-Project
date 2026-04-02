import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    return Container(
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
                  if (notif.notifType == NotificationType.offerReceived)
                    _buildOfferActions(context, provider, notif),
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
      _ => (Icons.notifications_outlined, Colors.grey),
    };

    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color, size: 20),
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
            : 'Failed to accept offer. Try again.';
        ScaffoldMessenger.of(
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to decline offer. Try again.')),
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
