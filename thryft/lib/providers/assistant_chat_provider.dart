import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/chat_message.dart';
import 'package:thryft/providers/chat_service.dart';
import 'package:thryft/providers/navigation_assistant.dart';

class AssistantChatProvider extends ChangeNotifier {
  final ChatService _chatService;
  final NavAssistantService _navService;
  final SupabaseClient _supabase;

  AssistantChatProvider({
    ChatService? chatService,
    NavAssistantService? navService,
    SupabaseClient? supabase,
  })  : _chatService = chatService ?? ChatService(),
        _navService = navService ?? NavAssistantService(),
        _supabase = supabase ?? Supabase.instance.client;

  final List<ChatMessage> _messages = [
    ChatMessage.assistant(
      'Hi! I can help you navigate, search for items, or answer questions. '
      'Try "take me to my cart", "search for nike shoes", or "how do I sell an item?"',
    ),
  ];

  bool _isSending = false;
  String? _error;
  DateTime? _lastSendAt;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  String? get error => _error;

  /// Standard fallback message when the assistant can't process a request.
  static const String _fallbackMessage =
      "Sorry, I'm having trouble processing your request, please try slightly different phrasing";

  /// Quick-help responses for common questions — handled locally without
  /// calling the AI backend, so they're instant and always available.
  /// Keys are canonical; typos and abbreviations are handled by fuzzy matching.
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
    'help':
        'I can help you navigate the app, search for items, or answer questions. '
        'Try saying "take me to my cart", "search for nike shoes", or "how do I sell an item?"',
    'cancel order':
        'To cancel an order, go to My Orders and select the order you wish to cancel. '
        'If the seller hasn\'t shipped yet, you can request a cancellation directly.',
    'track order':
        'You can track your orders from the My Orders page. Say "take me to my orders" '
        'and I\'ll navigate you there.',
    'shipping cost':
        'Shipping costs are calculated at checkout based on the seller\'s location and '
        'your delivery address. You\'ll see the total before confirming payment.',
    'payment methods':
        'Thryft accepts major credit/debit cards and secure payment processing. '
        'All transactions are protected by our buyer protection policy.',
    'delete account':
        'To delete your account, go to Profile Settings. You\'ll find the option at '
        'the bottom of the page. This action is permanent and cannot be undone.',
    'change password':
        'You can change your password in Profile Settings under the Security section.',
    'forgot password':
        'On the login screen, tap "Forgot password" and follow the instructions sent '
        'to your email to reset it.',
    'edit listing':
        'Go to My Listings, tap the item you want to edit, then select "Edit listing" '
        'to update details, price, or photos.',
    'report seller':
        'If you have an issue with a seller, please contact our support team via the '
        'Contact page and include your order details.',
    'shipping time':
        'Most sellers ship within 2-3 business days. Delivery time depends on your '
        'location and the shipping method chosen.',
    'refund':
        'Refunds are processed within 5-7 business days after the return is received. '
        'Contact the seller first to initiate a return.',
    'seller fees':
        'Listing items on Thryft is free. We charge a small commission only when your '
        'item sells. Check our terms for the current rate.',
    'size guide':
        'Each listing includes the seller\'s stated size. We recommend checking the '
        'brand\'s specific size chart and reading the condition description carefully.',
    'condition meanings':
        'New with tags = unworn with original tags. New without tags = unworn, no tags. '
        'Excellent = minimal signs of wear. Good = visible but minor wear. Fair = noticeable wear.',
  };

  bool _isAccountProtectedRoute(String route) {
    // Anything that exposes user/account data should require auth.
    // Keep this list aligned with `router.dart`.
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

  // ── Lightweight spelling correction ───────────────────────────

  /// Computes Levenshtein distance between two strings.
  static int _levenshtein(String a, String b) {
    final n = a.length;
    final m = b.length;
    if (n == 0) return m;
    if (m == 0) return n;

    final prev = List<int>.filled(m + 1, 0);
    final curr = List<int>.filled(m + 1, 0);

    for (var j = 0; j <= m; j++) prev[j] = j;

    for (var i = 1; i <= n; i++) {
      curr[0] = i;
      for (var j = 1; j <= m; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = min(
          min(curr[j - 1] + 1, prev[j] + 1),
          prev[j - 1] + cost,
        );
      }
      for (var j = 0; j <= m; j++) prev[j] = curr[j];
    }
    return curr[m];
  }

  /// Returns a similarity score between 0.0 and 1.0.
  static double _similarity(String a, String b) {
    final dist = _levenshtein(a, b);
    final maxLen = max(a.length, b.length);
    if (maxLen == 0) return 1.0;
    return 1.0 - dist / maxLen;
  }

  /// Checks if the message matches any quick-help pattern.
  /// Supports both exact substring matching and fuzzy typo tolerance.
  /// Returns the response string, or null if no match.
  String? _matchQuickHelp(String message) {
    final clean = message.toLowerCase().trim();

    // 1. Exact / substring match (fast path)
    final sortedKeys = _quickHelp.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sortedKeys) {
      if (clean.contains(key)) {
        return _quickHelp[key];
      }
    }

    // 2. Fuzzy match: tolerate up to 1 typo per 4 chars (similarity ≥ 0.75)
    final words = clean.split(RegExp(r'\s+'));
    for (final key in sortedKeys) {
      final keyWords = key.split(RegExp(r'\s+'));
      // All key words must have a close match somewhere in the input
      bool allMatched = true;
      for (final kw in keyWords) {
        if (kw.length <= 2) continue; // skip tiny words
        final found = words.any((w) => _similarity(kw, w) >= 0.75);
        if (!found) {
          allMatched = false;
          break;
        }
      }
      if (allMatched) return _quickHelp[key];
    }

    return null;
  }

  Future<void> send(String text, {GoRouter? router}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

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
      // 1. Check quick-help first (instant, no backend call).
      final quickReply = _matchQuickHelp(trimmed);
      if (quickReply != null) {
        _messages.add(ChatMessage.assistant(quickReply));
        return;
      }

      // 2. Check social intents (greeting, farewell, thanks).
      final socialReply = _navService.detectSocialIntent(trimmed);
      if (socialReply != null) {
        _messages.add(ChatMessage.assistant(socialReply));
        return;
      }

      // 3. Check navigation intent.
      final match = _navService.matchTarget(trimmed);
      if (match != null) {
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

        // Let the user read the confirmation, then navigate.
        if (router != null) {
          unawaited(
            Future<void>.delayed(const Duration(milliseconds: 700), () {
              router.push(match.route);
            }),
          );
        }
        return;
      }

      // 4. Fall back to AI backend.
      final reply = await _chatService.getAssistantResponse(trimmed);
      _messages.add(ChatMessage.assistant(reply));
    } catch (e) {
      _error = e.toString();
      _messages.add(ChatMessage.assistant(_fallbackMessage));
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

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

