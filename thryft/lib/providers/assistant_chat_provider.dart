import 'dart:async';

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
      'Hi! Ask me anything, or say things like "take me to my cart".',
    ),
  ];

  bool _isSending = false;
  String? _error;
  DateTime? _lastSendAt;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  String? get error => _error;

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
    };
    return protected.contains(route);
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

  void clear() {
    _messages
      ..clear()
      ..add(ChatMessage.assistant('Hi! Ask me anything, or say things like "take me to my cart".'));
    _error = null;
    _isSending = false;
    notifyListeners();
  }
}

