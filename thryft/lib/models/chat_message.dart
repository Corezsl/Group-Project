enum ChatRole { user, assistant, system }

class ChatMessage {
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.user(String content) => ChatMessage(
        role: ChatRole.user,
        content: content,
        createdAt: DateTime.now(),
      );

  factory ChatMessage.assistant(String content) => ChatMessage(
        role: ChatRole.assistant,
        content: content,
        createdAt: DateTime.now(),
      );

  factory ChatMessage.system(String content) => ChatMessage(
        role: ChatRole.system,
        content: content,
        createdAt: DateTime.now(),
      );
}

