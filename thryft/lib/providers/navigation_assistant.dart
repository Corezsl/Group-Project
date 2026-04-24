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
  NavMatch? matchTarget(String message) {
    final clean = message.toLowerCase().trim();
    if (clean.isEmpty) return null;

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
    final pageName = route.replaceAll('/', '').replaceAll('-', ' ');
    if (pageName.isEmpty) return "Heading back to the home page.";
    return "Sure thing! Opening your $pageName now.";
  }
}