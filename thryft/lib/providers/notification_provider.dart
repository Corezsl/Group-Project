import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/notification_model.dart';

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

  /// Updates product status and price upon accepting an offer.
  Future<void> acceptOffer(AppNotification notification) async {
    if (notification.listingId == null || notification.relatedUserId == null) {
      return;
    }

    //Check  product is not already sold
    final product = await Supabase.instance.client
        .from('products')
        .select('is_sold')
        .eq('id', notification.listingId!)
        .single();

    if (product['is_sold'] == true) {
      await _syncOfferStatus(notification, 'declined');
      await _deleteNotification(notification.notificationId);
      throw Exception('already_sold');
    }

    final updatedOffer = await _syncOfferStatus(notification, 'accepted');
    final acceptedPrice = (updatedOffer['offered_price'] as num).toDouble();

    await Supabase.instance.client
        .from('products')
        .update({
          'price': acceptedPrice,
          'is_sold': true,
          if (notification.relatedUserId != null)
            'buyer_id': notification.relatedUserId,
        })
        .eq('id', notification.listingId!);

    final listingName = await _resolveListingName(notification.listingId!);
    await NotificationProvider.insertNotification(
      userId: notification.relatedUserId!,
      type: NotificationType.listingSold,
      content:
          'Your offer of £${acceptedPrice.toStringAsFixed(2)} for $listingName was accepted.',
      listingId: notification.listingId,
      relatedUserId: notification.relatedUserId,
      offerPrice: acceptedPrice,
    );

    await _deleteNotification(notification.notificationId);
  }

  /// Removes a notification when an offer is declined.
  Future<void> declineOffer(AppNotification notification) async {
    final updatedOffer = await _syncOfferStatus(notification, 'declined');
    final declinedPrice = (updatedOffer['offered_price'] as num).toDouble();
    final listingName = notification.listingId == null
        ? 'this item'
        : await _resolveListingName(notification.listingId!);

    if (notification.relatedUserId != null) {
      await NotificationProvider.insertNotification(
        userId: notification.relatedUserId!,
        type: NotificationType.other,
        content:
            'Your offer of £${declinedPrice.toStringAsFixed(2)} for $listingName was declined.',
        listingId: notification.listingId,
        relatedUserId: notification.relatedUserId,
        offerPrice: declinedPrice,
      );
    }

    await _deleteNotification(notification.notificationId);
  }

  Future<Map<String, dynamic>> _syncOfferStatus(
    AppNotification notification,
    String status,
  ) async {
    if (notification.listingId == null || notification.relatedUserId == null) {
      throw Exception('missing_offer_identity');
    }

    final latestOffer = await Supabase.instance.client
        .from('offers')
        .select('offer_id, offered_price')
        .eq('listing_id', notification.listingId!)
        .eq('buyer_id', notification.relatedUserId!)
        .eq('status', 'pending')
        .order('updated_at', ascending: false)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (latestOffer == null) {
      throw Exception('offer_not_found');
    }

    final updatedOffer = await Supabase.instance.client
        .from('offers')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('offer_id', latestOffer['offer_id'])
        .select('offer_id, offered_price, status')
        .maybeSingle();

    if (updatedOffer == null) {
      throw Exception('offer_update_failed');
    }

    return Map<String, dynamic>.from(updatedOffer as Map);
  }

  Future<String> _resolveListingName(String listingId) async {
    try {
      final product = await Supabase.instance.client
          .from('products')
          .select('name')
          .eq('id', listingId)
          .maybeSingle();
      final name = product?['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
      return 'this item';
    } catch (_) {
      return 'this item';
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