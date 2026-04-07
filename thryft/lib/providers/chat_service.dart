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
      
      return response.data['reply'] ?? "I'm sorry, I couldn't find an answer to that.";
    } catch (e) {
      return "I'm having trouble connecting to the assistant right now.";
    }
  }
}