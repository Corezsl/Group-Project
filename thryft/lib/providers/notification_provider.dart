import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/notification_model.dart';

/// Manages user notifications and offer interactions using Supabase.
class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

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
      } else {
        _notifications.clear();
        notifyListeners();
      }
    });

    if (Supabase.instance.client.auth.currentUser != null) {
      fetchNotifications();
    }
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
    if (notification.listingId == null || notification.offerPrice == null)
      return;

    //Check  product is not already sold
    final product = await Supabase.instance.client
        .from('products')
        .select('is_sold')
        .eq('id', notification.listingId!)
        .single();

    if (product['is_sold'] == true) {
      await _deleteNotification(notification.notificationId);
      throw Exception('already_sold');
    }

    await Supabase.instance.client
        .from('products')
        .update({
          'price': notification.offerPrice,
          'is_sold': true,
          if (notification.relatedUserId != null)
            'buyer_id': notification.relatedUserId,
        })
        .eq('id', notification.listingId!);

    await _deleteNotification(notification.notificationId);
  }

  /// Removes a notification when an offer is declined.
  Future<void> declineOffer(AppNotification notification) async {
    await _deleteNotification(notification.notificationId);
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
    } catch (e) {
      debugPrint('Error inserting notification: $e');
    }
  }
}