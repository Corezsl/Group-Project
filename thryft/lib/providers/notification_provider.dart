import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/notification_model.dart';
import 'package:thryft/providers/offer_provider.dart';

/// Manages user notifications and offer interactions using Supabase.
class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  RealtimeChannel? _realtimeChannel;

  NotificationProvider() {
    _init();
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;

  /// Initializes authentication listeners to sync notifications.
  Future<void> _init() async {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        fetchNotifications();
        _subscribeToNotifications();
      } else {
        _notifications.clear();
        _unsubscribeFromNotifications();
        notifyListeners();
      }
    });

    if (Supabase.instance.client.auth.currentUser != null) {
      fetchNotifications();
      _subscribeToNotifications();
    }
  }

  void _subscribeToNotifications() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _unsubscribeFromNotifications();

    _realtimeChannel = Supabase.instance.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notification',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newNotification =
                AppNotification.fromMap(payload.newRecord);
            _notifications.insert(0, newNotification);
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'notification',
          callback: (payload) {
            final deletedId = payload.oldRecord['notification_id'] as int?;
            if (deletedId != null) {
              _notifications.removeWhere((n) => n.notificationId == deletedId);
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  void _unsubscribeFromNotifications() {
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  @override
  void dispose() {
    _unsubscribeFromNotifications();
    super.dispose();
  }

  /// Fetches user notifications from the database.
  Future<void> fetchNotifications() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('notification')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _notifications = (response as List)
          .map((data) => AppNotification.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks all notifications for the current user as read.
  Future<void> markAllAsRead() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final hasUnread = _notifications.any((n) => !n.isRead);
    if (!hasUnread) return;

    // Optimistic update
    _notifications = _notifications
        .map((n) => n.isRead ? n : n.copyWith(isRead: true))
        .toList();
    notifyListeners();

    try {
      await Supabase.instance.client
          .from('notification')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
      fetchNotifications();
    }
  }

  /// Accepts an offer: updates the product, cleans up, then notifies the buyer.
  Future<void> acceptOffer(AppNotification notification) async {
    if (notification.listingId == null || notification.offerPrice == null) return;

    // Guard against accepting an already-sold item.
    final product = await Supabase.instance.client
        .from('products')
        .select('is_sold, name')
        .eq('id', notification.listingId!)
        .single();

    if (product['is_sold'] == true) {
      await _deleteNotification(notification.notificationId);
      throw Exception('already_sold');
    }

    final listingTitle = product['name']?.toString() ?? 'the item';

    // Mark product as sold at the agreed price — this is the critical step.
    await Supabase.instance.client
        .from('products')
        .update({
          'price': notification.offerPrice,
          'is_sold': true,
          if (notification.relatedUserId != null)
            'buyer_id': notification.relatedUserId,
        })
        .eq('id', notification.listingId!);

    // Remove the seller's notification regardless of what follows.
    await _deleteNotification(notification.notificationId);

    // Best-effort: update offer record and notify the buyer.
    if (notification.relatedUserId != null) {
      try {
        await OfferProvider.updateOfferStatus(
          listingId: notification.listingId!,
          buyerId: notification.relatedUserId!,
          status: 'accepted',
        );
        await insertNotification(
          userId: notification.relatedUserId!,
          type: NotificationType.offerAccepted,
          content:
              'Your offer of £${notification.offerPrice!.toStringAsFixed(2)} for "$listingTitle" was accepted! The seller will ship it soon.',
          listingId: notification.listingId,
          offerPrice: notification.offerPrice,
        );
      } catch (e) {
        debugPrint('Could not send accept notification to buyer: $e');
      }
    }
  }

  /// Declines an offer: removes the notification, then notifies the buyer.
  Future<void> declineOffer(AppNotification notification) async {
    // Remove the seller's notification first — this must always succeed.
    await _deleteNotification(notification.notificationId);

    if (notification.listingId == null) return;

    // Best-effort: update offer record and notify the buyer.
    try {
      // Resolve buyer ID — prefer the one stored on the notification, but fall
      // back to the offers table for notifications created before the migration.
      String? buyerId = notification.relatedUserId;
      double? offerPrice = notification.offerPrice;

      if (buyerId == null) {
        final offerRow = await Supabase.instance.client
            .from('offers')
            .select('buyer_id, offer_amount')
            .eq('listing_id', notification.listingId!)
            .eq('status', 'pending')
            .maybeSingle();
        buyerId = offerRow?['buyer_id']?.toString();
        offerPrice ??= offerRow?['offer_amount'] != null
            ? (offerRow!['offer_amount'] as num).toDouble()
            : null;
      }

      if (buyerId == null) {
        debugPrint('declineOffer: could not resolve buyer ID — skipping buyer notification');
        return;
      }

      String listingTitle = 'the item';
      try {
        final product = await Supabase.instance.client
            .from('products')
            .select('name')
            .eq('id', notification.listingId!)
            .single();
        listingTitle = product['name']?.toString() ?? listingTitle;
      } catch (_) {}

      await OfferProvider.updateOfferStatus(
        listingId: notification.listingId!,
        buyerId: buyerId,
        status: 'declined',
      );

      await insertNotification(
        userId: buyerId,
        type: NotificationType.offerDeclined,
        content:
            'Your offer of £${offerPrice?.toStringAsFixed(2) ?? '—'} for "$listingTitle" was declined.',
        listingId: notification.listingId,
        offerPrice: offerPrice,
      );
    } catch (e) {
      debugPrint('Could not send decline notification to buyer: $e');
    }
  }

  /// Helper to remove a notification locally and from the database.
  Future<void> _deleteNotification(int notificationId) async {
    _notifications.removeWhere((n) => n.notificationId == notificationId);
    notifyListeners();

    await Supabase.instance.client
        .from('notification')
        .delete()
        .eq('notification_id', notificationId);
  }

  /// Static method to create a new notification entry.
  static Future<void> insertNotification({
    required String userId,
    required NotificationType type,
    required String content,
    String? listingId,
    String? relatedUserId,
    double? offerPrice,
    String? buyerAddress,
  }) async {
    try {
      await Supabase.instance.client.from('notification').insert({
        'user_id': userId,
        'notif_type': type.toDbString(),
        'content': content,
        'is_read': false,
        if (listingId != null) 'listing_id': listingId,
        if (relatedUserId != null) 'related_user_id': relatedUserId,
        if (offerPrice != null) 'offer_price': offerPrice,
        if (buyerAddress != null) 'buyer_address': buyerAddress,
      });
    } catch (e, stack) {
      debugPrint('Error inserting notification: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }
}
