// Represents a single message in the in-app assistant chat.
// Used by AssistantChatProvider to build up the conversation
// and by NavAssistantChatScreen to render each bubble.

// who the message is from — drives bubble styling on the screen
enum ChatRole { user, assistant, system }

class ChatMessage {
  final ChatRole role;
  final String content;
  // timestamp the message was created (we just use DateTime.now() since chats arent persisted)
  final DateTime createdAt;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  // shortcut for messages typed by the user
  factory ChatMessage.user(String content) => ChatMessage(
        role: ChatRole.user,
        content: content,
        createdAt: DateTime.now(),
      );

  // shortcut for replies coming back from the assistant
  factory ChatMessage.assistant(String content) => ChatMessage(
        role: ChatRole.assistant,
        content: content,
        createdAt: DateTime.now(),
      );
}
