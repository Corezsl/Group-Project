import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thryft/providers/assistant_chat_provider.dart';
import 'package:thryft/models/chat_message.dart';

class NavAssistantChatScreen extends StatefulWidget {
  const NavAssistantChatScreen({super.key});

  @override
  State<NavAssistantChatScreen> createState() => _NavAssistantChatScreenState();
}

class _NavAssistantChatScreenState extends State<NavAssistantChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AssistantChatProvider _chat;

  @override
  void initState() {
    super.initState();
    _chat = AssistantChatProvider()..addListener(_onChatChanged);
  }

  @override
  void dispose() {
    _chat.removeListener(_onChatChanged);
    _chat.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChatChanged() {
    // Keep the latest message visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
    if (mounted) setState(() {});
  }

  Future<void> _handleSendMessage() async {
    final text = _controller.text;
    _controller.clear();
    await _chat.send(text, router: GoRouter.of(context));
  }

  @override
  Widget build(BuildContext context) {
    final messages = _chat.messages;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assistant"),
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: _chat.isSending ? null : _chat.clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final m = messages[index];
                final isUser = m.role == ChatRole.user;
                final isSystem = m.role == ChatRole.system;
                final bg = isSystem
                    ? Colors.orange[50]
                    : (isUser ? Colors.blue[100] : Colors.grey[200]);
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.content),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ask a question or request a page (e.g. \"open my cart\")",
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _chat.isSending ? null : _handleSendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}