class AppNavigationMap {
  /// Maps logical page names to your Flutter route strings.
  static const Map<String, String> routes = {
    'home': '/',
    'profile': '/profile',
    'settings': '/settings',
    'cart': '/cart',
    'orders': '/orders',
    'wishlist': '/wishlist',
    'support': '/help-center',
    'notifications': '/notifications',
  };

  /// Defines natural language keywords that trigger specific routes.
  static const Map<String, List<String>> keywords = {
    'profile': ['account', 'my info', 'personal details', 'edit profile', 'me'],
    'cart': ['checkout', 'buy', 'basket', 'shopping bag', 'items'],
    'orders': ['history', 'track', 'shipping', 'my purchases', 'package'],
    'settings': ['preferences', 'password', 'theme', 'dark mode', 'privacy'],
    'wishlist': ['saved', 'favorites', 'likes', 'bookmarks'],
    'support': ['help', 'contact', 'agent', 'problem', 'issue'],
  };
}