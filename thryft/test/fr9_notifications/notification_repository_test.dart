import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/notification_model.dart';
import '../helpers/supabase_test_client.dart';
import '../helpers/seed_helper.dart';

const _user1Email = 'fr9.user1@thryft-test.local';
const _user1Password = 'Thryft!test99';

const _user2Email = 'fr9.user2@thryft-test.local';
const _user2Password = 'Thryft!test99';

// Uses the admin client to create the user when they don't exist yet,
// bypassing email confirmation and avoiding rate limits.
Future<String> _signInOrSignUp(
  SupabaseClient client,
  SupabaseClient admin,
  String email,
  String password,
  String username,
) async {
  try {
    final res = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.user!.id;
  } on AuthException {
    await admin.auth.admin.createUser(AdminUserAttributes(
      email: email,
      password: password,
      emailConfirm: true,
      userMetadata: {'username': username},
    ));
    final res = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.user!.id;
  }
}

// Mirrors NotificationProvider.fetchNotifications — queries the notification
// table scoped to a userId. Used directly here so we can test the query logic
// against the real DB without instantiating the full provider.
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

void main() {
  if (!hasTestCredentials) {
    test('FR9 integration tests', () {},
        skip: 'No Supabase credentials — pass '
            '--dart-define=TEST_SUPABASE_URL and TEST_SUPABASE_ANON_KEY to run');
    return;
  }

  late SupabaseClient client;
  late SupabaseClient admin;
  late String user1Id;
  late String user2Id;

  setUpAll(() async {
    client = await getTestClient();
    admin = getServiceClient();

    // Register / sign in both users; end session as user1.
    user1Id = await _signInOrSignUp(
        client, admin, _user1Email, _user1Password, 'fr9_user1');
    user2Id = await _signInOrSignUp(
        client, admin, _user2Email, _user2Password, 'fr9_user2');
    await _signInOrSignUp(client, admin, _user1Email, _user1Password, 'fr9_user1');
  });

  tearDownAll(() async {
    // Use admin client to delete all notifications seeded for both users.
    await admin
        .from('notification')
        .delete()
        .eq('user_id', user1Id);
    await admin
        .from('notification')
        .delete()
        .eq('user_id', user2Id);
    await client.auth.signOut();
  });

  // ---------------------------------------------------------------------------
  // FR9 Partition 5 — Only user's own notifications are returned
  // ---------------------------------------------------------------------------
  group('FR9 #5 — only user\'s own notifications are returned', () {
    late int notif1;
    late int notif2;

    setUp(() async {
      notif1 = await seedNotification(admin,
          userId: user1Id,
          notifType: 'order_shipped',
          content: 'Your item has been shipped');
      notif2 = await seedNotification(admin,
          userId: user1Id,
          notifType: 'price_drop',
          content: 'Price dropped on a wishlist item');
    });

    tearDown(() async {
      await admin
          .from('notification')
          .delete()
          .inFilter('notification_id', [notif1, notif2]);
    });

    test('fetch returns notifications mapped for the given userId', () async {
      final notifs = await _fetchNotificationsForUser(client, user1Id);
      final ids = notifs.map((n) => n.notificationId).toList();
      expect(ids, containsAll([notif1, notif2]));
      expect(notifs.every((n) => n.userId == user1Id), isTrue);
    });

    test('returns empty list for a user with no notifications', () async {
      // Ghost UUID — will never match any row.
      const ghost = '00000000-ffff-4000-8000-000000000099';
      final notifs = await _fetchNotificationsForUser(client, ghost);
      expect(notifs, isEmpty);
    });

    test('all returned notifications match the queried userId', () async {
      final notifs = await _fetchNotificationsForUser(client, user1Id);
      final relevant =
          notifs.where((n) => [notif1, notif2].contains(n.notificationId));
      expect(relevant.map((n) => n.userId), everyElement(equals(user1Id)));
    });
  });

  // ---------------------------------------------------------------------------
  // FR9 Partition 8 — Query is scoped to the requesting user (not another user)
  // ---------------------------------------------------------------------------
  group('FR9 #8 — query is scoped to the requesting user', () {
    late int notifForUser1;
    late int notifForUser2;

    setUp(() async {
      notifForUser1 = await seedNotification(admin,
          userId: user1Id,
          notifType: 'listing_sold',
          content: 'User1 listing sold');
      notifForUser2 = await seedNotification(admin,
          userId: user2Id,
          notifType: 'order_shipped',
          content: 'User2 order shipped');
    });

    tearDown(() async {
      await admin
          .from('notification')
          .delete()
          .inFilter('notification_id', [notifForUser1, notifForUser2]);
    });

    test('signed-in user1 cannot see user2 notifications via eq filter',
        () async {
      // Signed in as user1; RLS + eq filter should prevent seeing user2's rows.
      final notifs = await _fetchNotificationsForUser(client, user2Id);
      final ids = notifs.map((n) => n.notificationId).toList();
      expect(ids, isNot(contains(notifForUser2)));
    });

    test('signed-in user1 can fetch their own notifications', () async {
      final notifs = await _fetchNotificationsForUser(client, user1Id);
      final ids = notifs.map((n) => n.notificationId).toList();
      expect(ids, contains(notifForUser1));
    });

    test('switching session gives each user access to only their own data',
        () async {
      // user1 sees their notification.
      final user1Notifs = await _fetchNotificationsForUser(client, user1Id);
      expect(
        user1Notifs.map((n) => n.notificationId),
        contains(notifForUser1),
      );

      // Sign in as user2 and verify they see their own, not user1's.
      await _signInOrSignUp(
          client, admin, _user2Email, _user2Password, 'fr9_user2');
      final user2Notifs = await _fetchNotificationsForUser(client, user2Id);
      expect(
        user2Notifs.map((n) => n.notificationId),
        contains(notifForUser2),
      );
      expect(
        user2Notifs.map((n) => n.notificationId),
        isNot(contains(notifForUser1)),
      );

      // Restore session as user1 for remaining tests.
      await _signInOrSignUp(
          client, admin, _user1Email, _user1Password, 'fr9_user1');
    });
  });

  // ---------------------------------------------------------------------------
  // FR9 — Notification count boundary
  // ---------------------------------------------------------------------------
  group('FR9 — notification count boundary', () {
    late List<int> seededIds;

    tearDown(() async {
      if (seededIds.isNotEmpty) {
        await admin
            .from('notification')
            .delete()
            .inFilter('notification_id', seededIds);
      }
    });

    test('1 notification — mapped correctly', () async {
      seededIds = [
        await seedNotification(admin,
            userId: user1Id,
            notifType: 'price_drop',
            content: 'Boundary: 1 notification'),
      ];

      final notifs = await _fetchNotificationsForUser(client, user1Id);
      expect(
        notifs.map((n) => n.notificationId),
        contains(seededIds.first),
      );
    });

    test('3 notifications — all mapped', () async {
      seededIds = await Future.wait([
        seedNotification(admin,
            userId: user1Id,
            notifType: 'order_shipped',
            content: 'Boundary notif 1'),
        seedNotification(admin,
            userId: user1Id,
            notifType: 'order_delivered',
            content: 'Boundary notif 2'),
        seedNotification(admin,
            userId: user1Id,
            notifType: 'listing_sold',
            content: 'Boundary notif 3'),
      ]);

      final notifs = await _fetchNotificationsForUser(client, user1Id);
      final returnedIds = notifs.map((n) => n.notificationId).toList();
      expect(returnedIds, containsAll(seededIds));
    });
  });
}
