// Notification model used across the app for the bell icon, notifications screen,
// and anywhere we need to react to an event (sold listing, accepted offer, etc).
// Loaded from the supabase 'notifications' table via NotificationProvider.

// every kind of notification we currently send — keep in sync with the db enum
enum NotificationType {
  listingSold,
  priceDrop,
  other,
  wishlistAdd,
  wishlistPurchased,
  offerReceived,
  offerAccepted,
  offerDeclined,
  orderShipped,
  orderDelivered;

  // maps the snake_case string from the db row into our enum
  static NotificationType fromString(String value) {
    switch (value) {
      case 'listing_sold':
        return NotificationType.listingSold;
      case 'price_drop':
        return NotificationType.priceDrop;
      case 'wishlist_add':
        return NotificationType.wishlistAdd;
      case 'wishlist_purchased':
        return NotificationType.wishlistPurchased;
      case 'offer_received':
        return NotificationType.offerReceived;
      case 'offer_accepted':
        return NotificationType.offerAccepted;
      case 'offer_declined':
        return NotificationType.offerDeclined;
      case 'order_shipped':
        return NotificationType.orderShipped;
      case 'order_delivered':
        return NotificationType.orderDelivered;
      default:
        return NotificationType.other;
    }
  }

  // reverse of fromString, used when inserting new rows
  String toDbString() {
    switch (this) {
      case NotificationType.listingSold:
        return 'listing_sold';
      case NotificationType.priceDrop:
        return 'price_drop';
      case NotificationType.wishlistAdd:
        return 'wishlist_add';
      case NotificationType.wishlistPurchased:
        return 'wishlist_purchased';
      case NotificationType.offerReceived:
        return 'offer_received';
      case NotificationType.offerAccepted:
        return 'offer_accepted';
      case NotificationType.offerDeclined:
        return 'offer_declined';
      case NotificationType.orderShipped:
        return 'order_shipped';
      case NotificationType.orderDelivered:
        return 'order_delivered';
      case NotificationType.other:
        return 'other';
    }
  }
}

// A notification belonging to a single user. Named AppNotification so it doesnt
// clash with flutter's own Notification class.
class AppNotification {
  final int notificationId;
  // user this notification is for (the recipient)
  final String userId;
  final NotificationType notifType;
  // the message text shown in the notifications list
  final String content;
  // false until the user opens the notifications screen
  final bool isRead;
  final DateTime createdAt;

  // optional extras depending on the notif type — e.g. an offer notif has offerPrice,
  // a shipped order notif has buyerAddress. Most types only use a couple of these.
  final String? listingId;
  final String? relatedUserId;
  final double? offerPrice;
  final String? buyerAddress;

  const AppNotification({
    required this.notificationId,
    required this.userId,
    required this.notifType,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.listingId,
    this.relatedUserId,
    this.offerPrice,
    this.buyerAddress,
  });

  // builds a notification from a supabase row
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    final userId = map['user_id'];
    if (userId == null) {
      throw ArgumentError('notification row is missing user_id');
    }
    return AppNotification(
      notificationId: map['notification_id'] as int,
      userId: userId.toString(),
      notifType: NotificationType.fromString(map['notif_type'].toString()),
      content: map['content'].toString(),
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'].toString()),
      listingId: map['listing_id']?.toString(),
      relatedUserId: map['related_user_id']?.toString(),
      offerPrice: map['offer_price'] != null
          ? (map['offer_price'] as num).toDouble()
          : null,
      buyerAddress: map['buyer_address']?.toString(),
    );
  }

  // only isRead ever changes after creation, so thats all copyWith handles
  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      notificationId: notificationId,
      userId: userId,
      notifType: notifType,
      content: content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      listingId: listingId,
      relatedUserId: relatedUserId,
      offerPrice: offerPrice,
      buyerAddress: buyerAddress,
    );
  }
}
