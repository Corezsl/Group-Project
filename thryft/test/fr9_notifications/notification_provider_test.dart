import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/models/notification_model.dart';

// FR9 Partition 7 — Duplicate notification prevention

// Helpers

AppNotification _makeNotif({
  int id = 1,
  String userId = 'user-1',
  bool isRead = false,
  NotificationType type = NotificationType.orderShipped,
  String content = 'Test notification',
}) =>
    AppNotification(
      notificationId: id,
      userId: userId,
      notifType: type,
      content: content,
      isRead: isRead,
      createdAt: DateTime(2026, 1, 1),
    );

List<AppNotification> _deduplicate(List<AppNotification> notifications) =>
    notifications
        .fold<Map<int, AppNotification>>({}, (map, n) {
          map[n.notificationId] = n;
          return map;
        })
        .values
        .toList();

void main() {
  // FR9 Partition 7 — Duplicate notification prevention
  group('FR9 #7 — duplicate notification prevention', () {
    test('two notifications with the same id deduplicate to one entry', () {
      final n1 = _makeNotif(id: 1, content: 'First');
      final n2 = _makeNotif(id: 1, content: 'Duplicate');

      final result = _deduplicate([n1, n2]);

      expect(result, hasLength(1));
    });

    test('two notifications with different ids are both retained', () {
      final n1 = _makeNotif(id: 1);
      final n2 = _makeNotif(id: 2);

      final result = _deduplicate([n1, n2]);

      expect(result, hasLength(2));
    });

    test('three notifications where one is a duplicate deduplicate to two', () {
      final notifications = [
        _makeNotif(id: 1),
        _makeNotif(id: 2),
        _makeNotif(id: 1),
      ];

      final result = _deduplicate(notifications);

      expect(result, hasLength(2));
    });

    test('empty list deduplicates to empty list', () {
      expect(_deduplicate([]), isEmpty);
    });
  });

  // FR9 — unreadCount logic
  group('FR9 — unread count calculation', () {
    test('unreadCount is 0 when all notifications are read', () {
      final notifications = [
        _makeNotif(id: 1, isRead: true),
        _makeNotif(id: 2, isRead: true),
      ];

      final unreadCount = notifications.where((n) => !n.isRead).length;

      expect(unreadCount, equals(0));
    });

    test('unreadCount equals the number of unread notifications', () {
      final notifications = [
        _makeNotif(id: 1, isRead: false),
        _makeNotif(id: 2, isRead: true),
        _makeNotif(id: 3, isRead: false),
      ];

      final unreadCount = notifications.where((n) => !n.isRead).length;

      expect(unreadCount, equals(2));
    });

    test('unreadCount is 0 for an empty list', () {
      final notifications = <AppNotification>[];

      final unreadCount = notifications.where((n) => !n.isRead).length;

      expect(unreadCount, equals(0));
    });

    test('unreadCount is total length when all are unread', () {
      final notifications = List.generate(5, (i) => _makeNotif(id: i, isRead: false));

      final unreadCount = notifications.where((n) => !n.isRead).length;

      expect(unreadCount, equals(5));
    });
  });


  // FR9 — markAllAsRead logic (via copyWith)
  group('FR9 — markAllAsRead sets all notifications to read', () {
    test('all notifications become read after markAllAsRead', () {
      final notifications = [
        _makeNotif(id: 1, isRead: false),
        _makeNotif(id: 2, isRead: false),
        _makeNotif(id: 3, isRead: true),
      ];

      final updated = notifications
          .map((n) => n.isRead ? n : n.copyWith(isRead: true))
          .toList();

      expect(updated.every((n) => n.isRead), isTrue);
    });

    test('markAllAsRead on empty list produces empty list', () {
      final notifications = <AppNotification>[];

      final updated = notifications
          .map((n) => n.isRead ? n : n.copyWith(isRead: true))
          .toList();

      expect(updated, isEmpty);
    });

    test('markAllAsRead preserves notification ids and content', () {
      final notif = _makeNotif(id: 42, content: 'Important', isRead: false);
      final updated = notif.copyWith(isRead: true);

      expect(updated.notificationId, equals(42));
      expect(updated.content, equals('Important'));
      expect(updated.isRead, isTrue);
    });

    test('already-read notifications are unchanged by markAllAsRead', () {
      final notif = _makeNotif(id: 1, isRead: true);
      final after = notif.isRead ? notif : notif.copyWith(isRead: true);

      expect(identical(after, notif), isTrue);
    });
  });

  // FR9 — realtime insert logic
  group('FR9 — realtime notification insert', () {
    test('new notification is prepended to the front of the list', () {
      final existing = [_makeNotif(id: 1), _makeNotif(id: 2)];
      final newNotif = _makeNotif(id: 3, content: 'New arrival');

      final updated = [newNotif, ...existing];

      expect(updated.first.notificationId, equals(3));
      expect(updated, hasLength(3));
    });

    test('delete removes the notification with matching id', () {
      final notifications = [
        _makeNotif(id: 1),
        _makeNotif(id: 2),
        _makeNotif(id: 3),
      ];

      final updated = notifications
          .where((n) => n.notificationId != 2)
          .toList();

      expect(updated, hasLength(2));
      expect(updated.map((n) => n.notificationId), isNot(contains(2)));
    });
  });
}
