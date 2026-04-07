import 'package:go_router/go_router.dart';
import 'package:thryft/screens/about_screen.dart';
import 'package:thryft/screens/contact_screen.dart';
import 'package:thryft/screens/help_center_screen.dart';
import 'package:thryft/screens/privacy_policy_screen.dart';
import 'package:thryft/screens/returns_screen.dart';
import 'package:thryft/screens/account_screen.dart';
import 'package:thryft/screens/profile_settings_screen.dart';
import 'package:thryft/screens/cart_screen.dart';
import 'package:thryft/screens/create_listing_screen.dart';
import 'package:thryft/screens/home_screen.dart';
import 'package:thryft/screens/product_detail_screen.dart';
import 'package:thryft/screens/wishlist_screen.dart';
import 'package:thryft/screens/user_listings_screen.dart';
import 'package:thryft/screens/my_orders_screen.dart';
import 'package:thryft/screens/terms_of_service_screen.dart';
import 'package:thryft/screens/auth_screen.dart';
import 'package:thryft/screens/user_profile_screen.dart';
import 'package:thryft/screens/sold_items_screen.dart';
import 'package:thryft/screens/category_screen.dart';
import 'package:thryft/screens/notifications_screen.dart';
import 'package:thryft/screens/forgot_password_screen.dart';
import 'package:thryft/screens/nav_assistant_chat_screen.dart'; //

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
    GoRoute(
      path: '/wishlist',
      builder: (context, state) => const WishlistScreen(),
    ),
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
    GoRoute(path: '/contact', builder: (context, state) => const ContactScreen()),
    GoRoute(
      path: '/help-center',
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      path: '/terms-of-service',
      builder: (context, state) => const TermsOfServiceScreen(),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(path: '/returns', builder: (context, state) => const ReturnsScreen()),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/create-listing',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        return CreateListingScreen(initialData: data);
      },
    ),
    GoRoute(
      path: '/my-listings',
      builder: (context, state) => const MyListingsScreen(),
    ),
    GoRoute(
      path: '/my-orders',
      builder: (context, state) => const MyOrdersScreen(),
    ),
    GoRoute(
      path: '/sold-items',
      builder: (context, state) => const SoldItemsScreen(),
    ),
    GoRoute(
      path: '/profile-settings',
      builder: (context, state) => const ProfileSettingsScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final raw = state.extra;
        if (raw == null) return const HomeScreen();
        final product = Map<String, String>.from(raw as Map);
        return ProductDetailScreen(product: product);
      },
    ),
    GoRoute(
      path: '/user/:id',
      builder: (context, state) {
        final userId = state.pathParameters['id'];
        if (userId == null) return const HomeScreen();
        return UserProfileScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/category/:name',
      builder: (context, state) {
        final category = state.pathParameters['name'] ?? '';
        return CategoryScreen(category: category);
      },
    ),
    GoRoute(
      path: '/chat-assistant',
      builder: (context, state) => const NavAssistantChatScreen(), //
    ),
  ],
);