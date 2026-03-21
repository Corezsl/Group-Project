import 'package:go_router/go_router.dart';
import 'package:thryft/screens/about_page.dart';
import 'package:thryft/screens/contact_page.dart';
import 'package:thryft/screens/help_center_page.dart';
import 'package:thryft/screens/privacy_policy_page.dart';
import 'package:thryft/screens/returns_page.dart';
import 'package:thryft/screens/account_screen.dart';
import 'package:thryft/screens/profile_settings_screen.dart';
import 'package:thryft/screens/cart_screen.dart';
import 'package:thryft/screens/create_listing_screen.dart';
import 'package:thryft/screens/home_screen.dart';
import 'package:thryft/screens/product_detail_screen.dart';
import 'package:thryft/screens/wishlist_screen.dart';
import 'package:thryft/screens/terms_of_service_page.dart';
import 'package:thryft/screens/auth_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
    GoRoute(
      path: '/wishlist',
      builder: (context, state) => const WishlistPage(),
    ),
    GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
    GoRoute(path: '/contact', builder: (context, state) => const ContactPage()),
    GoRoute(
      path: '/help-center',
      builder: (context, state) => const HelpCenterPage(),
    ),
    GoRoute(
      path: '/terms-of-service',
      builder: (context, state) => const TermsOfServicePage(),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyPage(),
    ),
    GoRoute(path: '/returns', builder: (context, state) => const ReturnsPage()),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/create-listing',
      builder: (context, state) => const CreateListingScreen(),
    ),
    GoRoute(
      path: '/profile-settings',
      builder: (context, state) => const ProfileSettingsScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final product = state.extra as Map<String, String>?;
        if (product == null) {
          return const HomeScreen();
        }
        return ProductDetailScreen(product: product);
      },
    ),
  ],
);
