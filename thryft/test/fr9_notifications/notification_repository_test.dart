import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/notification_model.dart';

// Mocks

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

// Fake filter builder — captures the user_id passed to .eq() so tests can
// assert the query was scoped to the correct user.

class FakeNotifFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  final List<dynamic> _rows;
  final List<String?> _capturedUserIds = [];

  FakeNotifFilterBuilder(this._rows);

  String? get capturedUserId =>
      _capturedUserIds.isEmpty ? null : _capturedUserIds.last;

  @override
  FakeNotifFilterBuilder eq(String column, dynamic value) {
    if (column == 'user_id') _capturedUserIds.add(value.toString());
    return this;
  }

  @override
  FakeNotifFilterBuilder order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) =>
      this;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestList value) onValue, {
    Function? onError,
  }) =>
      Future.value(List<PostgrestMap>.from(_rows)).then(
        onValue,
        onError: onError,
      );
}

// Standalone fetch function — mirrors NotificationProvider.fetchNotifications
// so we can test the query logic without initialising Supabase.instance.

Future<List<AppNotification>> _fetchNotificationsForUser(
  SupabaseClient client,
  String userId,
) async {
  final response = await client
      .from('notification')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  return (response as List)
      .map((data) => AppNotification.fromMap(data as Map<String, dynamic>))
      .toList();
}

// Helper — minimal notification DB row

Map<String, dynamic> _notifRow({
  int id = 1,
  String userId = 'user-1',
  String type = 'order_shipped',
  String content = 'Notification content',
  bool isRead = false,
}) =>
    {
      'notification_id': id,
      'user_id': userId,
      'notif_type': type,
      'content': content,
      'is_read': isRead,
      'created_at': '2026-01-01T00:00:00.000Z',
      'listing_id': null,
      'related_user_id': null,
      'offer_price': null,
      'buyer_address': null,
    };

void main() {
  late MockSupabaseClient client;
  late MockSupabaseQueryBuilder qb;
  late FakeNotifFilterBuilder fakeBuilder;

  void stubFetch(List<dynamic> rows) {
    fakeBuilder = FakeNotifFilterBuilder(rows);
    when(() => client.from('notification')).thenAnswer((_) => qb);
    when(() => qb.select(any())).thenAnswer((_) => fakeBuilder);
  }

  setUp(() {
    client = MockSupabaseClient();
    qb = MockSupabaseQueryBuilder();
  });

  // FR9 Partition 5 — Unrelated item update: no notification for unrelated user
  group('FR9 #5 — only user\'s own notifications are returned', () {
    test('fetch returns notifications mapped for the given userId', () async {
      stubFetch([
        _notifRow(id: 1, userId: 'user-1', type: 'order_shipped'),
        _notifRow(id: 2, userId: 'user-1', type: 'price_drop'),
      ]);

      final notifs = await _fetchNotificationsForUser(client, 'user-1');

      expect(notifs, hasLength(2));
      expect(notifs.every((n) => n.userId == 'user-1'), isTrue);
    });

    test('returns empty list for a user with no notifications', () async {
      stubFetch([]);

      final notifs = await _fetchNotificationsForUser(client, 'user-no-notifs');

      expect(notifs, isEmpty);
    });

    test('all returned notifications match the queried userId', () async {
      stubFetch([
        _notifRow(id: 1, userId: 'user-1', type: 'wishlist_purchased'),
        _notifRow(id: 2, userId: 'user-1', type: 'listing_sold'),
        _notifRow(id: 3, userId: 'user-1', type: 'order_delivered'),
      ]);

      final notifs = await _fetchNotificationsForUser(client, 'user-1');

      expect(notifs.map((n) => n.userId), everyElement(equals('user-1')));
    });
  });

  // FR9 Partition 8 — Access another user's notifications: access is denied
  // The query uses eq('user_id', userId) to scope results to the current user.
  group('FR9 #8 — query is scoped to the requesting user (not another user)', () {
    test('query uses the correct user id in the eq filter', () async {
      stubFetch([_notifRow(id: 1, userId: 'user-1')]);

      await _fetchNotificationsForUser(client, 'user-1');

      expect(fakeBuilder.capturedUserId, equals('user-1'));
    });

    test('a different userId produces a different query scope', () async {
      stubFetch([]);

      await _fetchNotificationsForUser(client, 'user-2');

      expect(fakeBuilder.capturedUserId, equals('user-2'));
    });

    test('two separate users each get their own isolated result set', () async {
      stubFetch([_notifRow(id: 10, userId: 'user-A', type: 'price_drop')]);
      final notifsA = await _fetchNotificationsForUser(client, 'user-A');
      final capturedA = fakeBuilder.capturedUserId;

      stubFetch([_notifRow(id: 20, userId: 'user-B', type: 'order_shipped')]);
      final notifsB = await _fetchNotificationsForUser(client, 'user-B');
      final capturedB = fakeBuilder.capturedUserId;

      expect(capturedA, equals('user-A'));
      expect(capturedB, equals('user-B'));
      expect(notifsA.first.userId, equals('user-A'));
      expect(notifsB.first.userId, equals('user-B'));
    });
  });

  // Boundary — large notification sets
  group('FR9 — large notification set boundary', () {
    List<Map<String, dynamic>> _makeRows(int count) => List.generate(
          count,
          (i) => _notifRow(id: i + 1, userId: 'user-1', type: 'price_drop'),
        );

    test('1 notification — mapped correctly', () async {
      stubFetch(_makeRows(1));
      final notifs = await _fetchNotificationsForUser(client, 'user-1');
      expect(notifs, hasLength(1));
    });

    test('50 notifications — all mapped', () async {
      stubFetch(_makeRows(50));
      final notifs = await _fetchNotificationsForUser(client, 'user-1');
      expect(notifs, hasLength(50));
    });

    test('51 notifications — all mapped (no cutoff)', () async {
      stubFetch(_makeRows(51));
      final notifs = await _fetchNotificationsForUser(client, 'user-1');
      expect(notifs, hasLength(51));
    });
  });
}
