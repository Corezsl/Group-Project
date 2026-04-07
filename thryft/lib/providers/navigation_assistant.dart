import 'navigation_map.dart';

class NavAssistantService {
  /// Analyzes the user's message to find a matching route based on keywords.
  /// Returns the route string if a match is found, otherwise returns null.
  String? identifyTargetRoute(String message) {
    final cleanMessage = message.toLowerCase();

    // Iterate through the keyword map to find a match
    for (var entry in AppNavigationMap.keywords.entries) {
      final routeKey = entry.key;
      final associatedKeywords = entry.value;

      for (var keyword in associatedKeywords) {
        if (cleanMessage.contains(keyword)) {
          // Return the actual route path from the routes map
          return AppNavigationMap.routes[routeKey];
        }
      }
    }
    
    return null;
  }

  /// Generates a friendly confirmation message based on the destination.
  String getConfirmationMessage(String route) {
    final pageName = route.replaceAll('/', '').replaceAll('-', ' ');
    if (pageName.isEmpty) return "Heading back to the home page.";
    return "Sure thing! Opening your $pageName now.";
  }
}