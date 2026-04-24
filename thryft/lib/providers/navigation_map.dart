class AppNavigationMap {
  /// Maps logical page names to your Flutter route strings.
  static const Map<String, String> routes = {
    'home': '/',
    'cart': '/cart',
    'wishlist': '/wishlist',
    'support': '/help-center',
    'notifications': '/notifications',
    'account': '/account',
    'settings': '/profile-settings',
    'orders': '/my-orders',
  };

  /// Defines natural language keywords that trigger specific routes.
  static const Map<String, List<String>> keywords = {
    'account': ['account', 'my account', 'my info', 'personal details', 'me'],
    'cart': ['checkout', 'buy', 'basket', 'shopping bag', 'items'],
    'orders': ['history', 'track', 'shipping', 'my purchases', 'package'],
    'settings': ['settings', 'preferences', 'password', 'theme', 'dark mode', 'privacy'],
    'wishlist': ['saved', 'favorites', 'likes', 'bookmarks'],
    'support': ['help', 'contact', 'agent', 'problem', 'issue'],
  };
}