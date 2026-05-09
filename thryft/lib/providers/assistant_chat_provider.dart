import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/chat_message.dart';
import 'package:thryft/providers/chat_service.dart';
import 'package:thryft/providers/navigation_assistant.dart';

/// State management for the in-app AI chat assistant.
/// Consumed by the assistant chat UI via Provider / ChangeNotifier.
///
/// Messages flow through a three-step pipeline in [send]:
///   1. Quick-help — instant keyword-matched answers (no backend call).
///   2. Navigation — recognised route intents are resolved by [NavAssistantService].
///   3. AI fallback — anything else is forwarded to [ChatService] (remote API).
class AssistantChatProvider extends ChangeNotifier {
  // Service that calls the AI backend for free-form responses.
  final ChatService _chatService;
  // Service that maps user phrases like "take me to cart" to app routes.
  final NavAssistantService _navService;
  // Used to check auth state before navigating to protected routes.
  final SupabaseClient _supabase;

  /// All three dependencies are injectable for testing; production
  /// code relies on the defaults (singleton instances).
  AssistantChatProvider({
    ChatService? chatService,
    NavAssistantService? navService,
    SupabaseClient? supabase,
  })  : _chatService = chatService ?? ChatService(),
        _navService = navService ?? NavAssistantService(),
        _supabase = supabase ?? Supabase.instance.client;

  // Chat history shown in the UI. Seeded with a welcome message.
  final List<ChatMessage> _messages = [
    ChatMessage.assistant(
      'Hi! I can help you navigate, search for items, or answer questions. '
      'Try "take me to my cart", "search for nike shoes", or "how do I sell an item?"',
    ),
  ];

  bool _isSending = false;   // True while waiting for a response (shows spinner).
  String? _error;             // Holds the last error message, if any.
  DateTime? _lastSendAt;      // Timestamp of the last send — used for debouncing.

  // Public read-only getters used by the UI.
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  String? get error => _error;

  /// Quick-help responses for common questions — handled locally without 
  /// calling the AI backend
  static const Map<String, String> _quickHelp = {
    'how do i sell':
        'To sell an item, go to the Create Listing page. You can say "take me to sell" '
        'and I\'ll navigate you there. Fill in the title, price, photos, and optional '
        'details like brand, size, and description, then submit!',
    'how do i return':
        'You can read our full return policy by saying "show me the returns page". '
        'In short: contact the seller or our support team within 14 days of delivery.',
    'how do i create an account':
        'Tap the Account icon in the navigation bar, then follow the sign-up flow. '
        'You\'ll need an email and password to get started.',
    'how do i make an offer':
        'On any product detail page, tap "Make an offer" and enter your proposed price. '
        'The seller will be notified and can accept or decline.',
    'how do i add to cart':
        'On a product page, tap "Add to cart". You can review all your items by saying '
        '"open my cart".',
    'how do i wishlist':
        'Tap the heart icon on any product card or detail page. View all your saved '
        'items by saying "show my wishlist".',
    'is it safe':
        'Thryft uses secure payment processing and buyer protection. Check our terms '
        'of service for full details — say "show me the terms".',
    'how do i contact':
        'You can reach our team via the Contact page. Say "take me to contact" and '
        'I\'ll open it for you.',
    'what is thryft':
        'Thryft is a sustainable fashion marketplace where you can buy and sell '
        'pre-loved clothing. Say "about us" to learn more!',
  };

  /// Returns true if [route] requires the user to be logged in.
  /// Keep this list aligned with the route guards in `router.dart`.
  bool _isAccountProtectedRoute(String route) {
    const protected = <String>{
      '/account',
      '/profile-settings',
      '/my-orders',
      '/my-offers',
      '/my-listings',
      '/sold-items',
      '/notifications',
      '/wishlist',
      '/cart',
      '/create-listing',
    };
    return protected.contains(route);
  }

  /// Checks if the message matches any quick-help pattern.
  /// Returns the response string, or null if no match.
  String? _matchQuickHelp(String message) {
    final clean = message.toLowerCase().trim();
    // Sort keys longest-first so "how do i return" beats "how do i"
    final sortedKeys = _quickHelp.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sortedKeys) {
      if (clean.contains(key)) {
        return _quickHelp[key];
      }
    }
    return null;
  }

  /// Main entry point called when the user taps Send.
  /// Runs through the three-step pipeline: quick-help → navigation → AI.
  /// [router] is needed to actually push a route when a nav intent is found.
  Future<void> send(String text, {GoRouter? router}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    // Debounce: ignore messages sent within 600 ms of the last one.
    final now = DateTime.now();
    if (_lastSendAt != null && now.difference(_lastSendAt!) < const Duration(milliseconds: 600)) {
      return;
    }
    _lastSendAt = now;

    _error = null;
    _isSending = true;
    _messages.add(ChatMessage.user(trimmed));
    notifyListeners();

    try {
      // Step 1 — Quick-help: instant keyword-matched answers.
      final quickReply = _matchQuickHelp(trimmed);
      if (quickReply != null) {
        _messages.add(ChatMessage.assistant(quickReply));
        return;
      }

      // Step 2 — Navigation: check if the user wants to go somewhere.
      final match = _navService.matchTarget(trimmed);
      if (match != null) {
        // Block navigation to auth-protected pages if user isn't signed in.
        final isAuthed = _supabase.auth.currentUser != null;
        if (_isAccountProtectedRoute(match.route) && !isAuthed) {
          _messages.add(
            ChatMessage.assistant(
              "You'll need to be logged in to access that page. Please sign in first.",
            ),
          );
          notifyListeners();
          return;
        }

        _messages.add(ChatMessage.assistant(_navService.getConfirmationMessage(match.route)));
        notifyListeners();

        // Short delay so the user sees the confirmation before the page changes.
        if (router != null) {
          unawaited(
            Future<void>.delayed(const Duration(milliseconds: 700), () {
              router.push(match.route);
            }),
          );
        }
        return;
      }

      // Step 3 — AI fallback: send the message to the remote backend.
      final reply = await _chatService.getAssistantResponse(trimmed);
      _messages.add(ChatMessage.assistant(reply));
    } catch (e) {
      _error = e.toString();
      _messages.add(ChatMessage.assistant("Sorry — I couldn't respond right now."));
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Resets the chat to its initial state (welcome message only).
  void clear() {
    _messages
      ..clear()
      ..add(ChatMessage.assistant(
        'Hi! I can help you navigate, search for items, or answer questions. '
        'Try "take me to my cart", "search for nike shoes", or "how do I sell an item?"',
      ));
    _error = null;
    _isSending = false;
    notifyListeners();
  }
}


