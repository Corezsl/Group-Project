import 'navigation_map.dart';

class NavMatch {
  final String route;
  final double confidence; // 0..1
  final String key;

  const NavMatch({required this.route, required this.confidence, required this.key});
}

class NavAssistantService {
  static final RegExp _navVerb = RegExp(
    r'\b(go to|open|show|take me to|navigate to|bring me to|head to)\b',
    caseSensitive: false,
  );

  // Patterns for search-with-query and category-browsing
  static final RegExp _searchForPattern = RegExp(
    r'\b(?:search|find|look for|look up)\s+(?:for\s+)?(.+)',
    caseSensitive: false,
  );

  static final RegExp _categoryPattern = RegExp(
    r'\b(?:show|browse|view|see|shop)\s+(?:me\s+)?(?:the\s+)?(\w+)\s*(?:category|collection|section)?',
    caseSensitive: false,
  );

  /// Analyzes the user's message to find a matching route based on keywords.
  /// Returns the route string if a match is found, otherwise returns null.
  String? identifyTargetRoute(String message) {
    return matchTarget(message)?.route;
  }

  /// Returns a match with confidence and key (or null).
  /// This is more robust than plain substring matching:
  /// - supports multi-word phrases
  /// - uses scoring so the "best" destination wins
  /// - requires either a navigation verb ("open", "go to", ...) or decent confidence
  /// - detects search-with-query and category-browsing intents
  NavMatch? matchTarget(String message) {
    final clean = message.toLowerCase().trim();
    if (clean.isEmpty) return null;

    // Check for search-with-query intent first (e.g. "search for nike shoes")
    final searchMatch = _searchForPattern.firstMatch(clean);
    if (searchMatch != null) {
      final query = searchMatch.group(1)?.trim();
      if (query != null && query.isNotEmpty) {
        return NavMatch(
          route: '/search?q=${Uri.encodeComponent(query)}',
          confidence: 0.9,
          key: 'search_query',
        );
      }
    }

    // Check for category-browsing intent (e.g. "show me the tops category")
    final catMatch = _categoryPattern.firstMatch(clean);
    if (catMatch != null) {
      final catWord = catMatch.group(1)?.trim().toLowerCase();
      if (catWord != null && AppNavigationMap.categories.contains(catWord)) {
        return NavMatch(
          route: '/category/$catWord',
          confidence: 0.9,
          key: 'category',
        );
      }
    }

    final hasNavVerb = _navVerb.hasMatch(clean);

    // Tokenize for lightweight word overlap.
    final tokens = clean
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toSet();

    double bestScore = 0.0;
    String? bestKey;

    for (final entry in AppNavigationMap.keywords.entries) {
      final key = entry.key;
      final phrases = entry.value;

      double score = 0.0;

      for (final phrase in phrases) {
        final p = phrase.toLowerCase();
        if (p.isEmpty) continue;

        // Phrase match gets the biggest boost.
        if (clean.contains(p)) {
          score += 3.0;
          continue;
        }

        // Otherwise do token overlap (helps with "my saved" -> wishlist, etc.)
        final pTokens = p.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
        for (final pt in pTokens) {
          if (tokens.contains(pt)) score += 1.0;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestKey = key;
      }
    }

    if (bestKey == null) return null;
    final route = AppNavigationMap.routes[bestKey];
    if (route == null) return null;

    // Convert score into a rough confidence. (Score is unbounded; cap it.)
    final confidence = (bestScore / 6.0).clamp(0.0, 1.0);

    // If there's no nav-verb, require stronger evidence to avoid false positives
    // (e.g. "I love dark mode" shouldn't auto-navigate).
    if (!hasNavVerb && confidence < 0.75) return null;

    return NavMatch(route: route, confidence: confidence, key: bestKey);
  }

  /// Generates a friendly confirmation message based on the destination.
  String getConfirmationMessage(String route) {
    // Handle search-with-query routes
    if (route.startsWith('/search?q=')) {
      final query = Uri.decodeComponent(route.replaceFirst('/search?q=', ''));
      return "Searching for \"$query\" now!";
    }

    // Handle category routes
    if (route.startsWith('/category/')) {
      final cat = route.replaceFirst('/category/', '').replaceAll('-', ' ');
      return "Browsing the $cat collection for you!";
    }

    final pageName = route.replaceAll('/', '').replaceAll('-', ' ');
    if (pageName.isEmpty) return "Heading back to the home page.";
    return "Sure thing! Opening your $pageName now.";
  }
}