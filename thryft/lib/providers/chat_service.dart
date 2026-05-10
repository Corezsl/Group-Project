import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final _client = Supabase.instance.client;

  /// Sends the user message to a backend AI agent
  Future<String> getAssistantResponse(String message) async {
    try {
      // Use an Edge Function to keep API keys secure and handle heavy AI logic
      final response = await _client.functions.invoke(
        'site-assistant',
        body: {'query': message},
      );
      
      return response.data['reply'] ?? "Sorry, I'm having trouble processing your request, please try slightly different phrasing";
    } catch (e) {
      return "Sorry, I'm having trouble processing your request, please try slightly different phrasing";
    }
  }
}