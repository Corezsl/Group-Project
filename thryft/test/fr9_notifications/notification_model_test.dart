import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/models/notification_model.dart';

// Helper — build a minimal raw DB row map for a notification

Map<String, dynamic> _notifRow({
  int id = 1,
  String? userId = 'user-1',
  String type = 'order_shipped',
  String content = 'Your item has been shipped',
  bool isRead = false,
  String? listingId,
  String? relatedUserId,
  double? offerPrice,
  String? buyerAddress,
}) =>
    {
      'notification_id': id,
      'user_id': userId,
      'notif_type': type,
      'content': content,
      'is_read': isRead,
      'created_at': '2026-01-01T00:00:00.000Z',
      'listing_id': listingId,
      'related_user_id': relatedUserId,
      'offer_price': offerPrice,
      'buyer_address': buyerAddress,
    };

void main() {
  // FR9 Partition 1 — Price change on wishlist item
  group('FR9 #1 — price change notification', () {
    test('fromMap parses price_drop type correctly', () {
      final notif = AppNotification.fromMap(
        _notifRow(type: 'price_drop', content: 'Price has changed'),
      );

      expect(notif.notifType, equals(NotificationType.priceDrop));
      expect(notif.content, equals('Price has changed'));
    });

    test('toDbString returns price_drop for priceDrop', () {
      expect(NotificationType.priceDrop.toDbString(), equals('price_drop'));
    });

    test('fromString converts price_drop to priceDrop', () {
      expect(
        NotificationType.fromString('price_drop'),
        equals(NotificationType.priceDrop),
      );
    });
  });

  // FR9 Partition 2 — Wishlist item sold
  group('FR9 #2 — wishlist item sold notification', () {
    test('fromMap parses wishlist_purchased type correctly', () {
      final notif = AppNotification.fromMap(
        _notifRow(
          type: 'wishlist_purchased',
          content: 'Item is no longer available',
        ),
      );

      expect(notif.notifType, equals(NotificationType.wishlistPurchased));
      expect(notif.content, equals('Item is no longer available'));
    });

    test('toDbString returns wishlist_purchased for wishlistPurchased', () {
      expect(
        NotificationType.wishlistPurchased.toDbString(),
        equals('wishlist_purchased'),
      );
    });

    test('fromMap parses listing_sold type correctly', () {
      final notif = AppNotification.fromMap(
        _notifRow(type: 'listing_sold', content: 'Your listing has been sold!'),
      );

      expect(notif.notifType, equals(NotificationType.listingSold));
    });
  });

  // FR9 Partition 3 — Item shipped notification (buyer receives it)
  group('FR9 #3 — item shipped notification', () {
    test('fromMap parses order_shipped type correctly', () {
      final notif = AppNotification.fromMap(
        _notifRow(
          type: 'order_shipped',
          content: 'Your item has been shipped',
          listingId: 'listing-42',
        ),
      );

      expect(notif.notifType, equals(NotificationType.orderShipped));
      expect(notif.content, contains('shipped'));
      expect(notif.listingId, equals('listing-42'));
    });

    test('toDbString returns order_shipped for orderShipped', () {
      expect(NotificationType.orderShipped.toDbString(), equals('order_shipped'));
    });

    test('notification is unread by default when is_read is false', () {
      final notif = AppNotification.fromMap(_notifRow(isRead: false));

      expect(notif.isRead, isFalse);
    });
  });

  // FR9 Partition 4 — Item received notification (seller receives it)
  group('FR9 #4 — item received (delivered) notification', () {
    test('fromMap parses order_delivered type correctly', () {
      final notif = AppNotification.fromMap(
        _notifRow(
          type: 'order_delivered',
          content: 'The buyer confirmed delivery. Order complete!',
        ),
      );

      expect(notif.notifType, equals(NotificationType.orderDelivered));
      expect(notif.content, contains('delivery'));
    });

    test('toDbString returns order_delivered for orderDelivered', () {
      expect(
        NotificationType.orderDelivered.toDbString(),
        equals('order_delivered'),
      );
    });
  });

  // FR9 Partition 6 — Missing user causes a parse error
  group('FR9 #6 — missing user causes parse error', () {
    test('fromMap throws when user_id is null', () {
      final badRow = _notifRow(userId: null);

      expect(() => AppNotification.fromMap(badRow), throwsA(anything));
    });

    test('fromMap throws when notification_id is null', () {
      final badRow = _notifRow()..['notification_id'] = null;

      expect(() => AppNotification.fromMap(badRow), throwsA(anything));
    });

    test('fromMap throws when created_at is missing or invalid', () {
      final badRow = _notifRow()..['created_at'] = 'not-a-date';

      expect(() => AppNotification.fromMap(badRow), throwsA(anything));
    });
  });

  // All NotificationType round-trips (fromString ↔ toDbString)
  group('NotificationType round-trip — fromString and toDbString', () {
    const cases = {
      'listing_sold': NotificationType.listingSold,
      'price_drop': NotificationType.priceDrop,
      'wishlist_add': NotificationType.wishlistAdd,
      'wishlist_purchased': NotificationType.wishlistPurchased,
      'offer_received': NotificationType.offerReceived,
      'offer_accepted': NotificationType.offerAccepted,
      'offer_declined': NotificationType.offerDeclined,
      'order_shipped': NotificationType.orderShipped,
      'order_delivered': NotificationType.orderDelivered,
      'other': NotificationType.other,
    };

    for (final entry in cases.entries) {
      test('${entry.key} round-trips correctly', () {
        expect(NotificationType.fromString(entry.key), equals(entry.value));
        expect(entry.value.toDbString(), equals(entry.key));
      });
    }

    test('unknown type string maps to other', () {
      expect(
        NotificationType.fromString('completely_unknown_type'),
        equals(NotificationType.other),
      );
    });
  });

  // AppNotification — optional fields and copyWith
  group('AppNotification — optional fields and copyWith', () {
    test('optional fields are null when absent from map', () {
      final notif = AppNotification.fromMap(_notifRow());

      expect(notif.listingId, isNull);
      expect(notif.relatedUserId, isNull);
      expect(notif.offerPrice, isNull);
      expect(notif.buyerAddress, isNull);
    });

    test('optional fields are populated when present in map', () {
      final notif = AppNotification.fromMap(
        _notifRow(
          type: 'offer_received',
          listingId: 'listing-1',
          relatedUserId: 'buyer-2',
          offerPrice: 15.50,
          buyerAddress: '1 Main St, London',
        ),
      );

      expect(notif.listingId, equals('listing-1'));
      expect(notif.relatedUserId, equals('buyer-2'));
      expect(notif.offerPrice, equals(15.50));
      expect(notif.buyerAddress, equals('1 Main St, London'));
    });

    test('copyWith isRead true creates updated notification', () {
      final notif = AppNotification.fromMap(_notifRow(isRead: false));
      final updated = notif.copyWith(isRead: true);

      expect(updated.isRead, isTrue);
      expect(updated.notificationId, equals(notif.notificationId));
      expect(updated.content, equals(notif.content));
    });

    test('copyWith without args preserves isRead', () {
      final notif = AppNotification.fromMap(_notifRow(isRead: true));
      final same = notif.copyWith();

      expect(same.isRead, isTrue);
    });
  });
}
