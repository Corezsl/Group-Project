import 'package:flutter/material.dart';
import 'package:thryft/providers/navigation_assistant.dart';

class NavAssistantChatScreen extends StatefulWidget {
  const NavAssistantChatScreen({super.key});

  @override
  State<NavAssistantChatScreen> createState() => _NavAssistantChatScreenState();
}

class _NavAssistantChatScreenState extends State<NavAssistantChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'content': 'Hello! How can I help you find your way around the app today?'}
  ];
  
  final NavAssistantService _navService = NavAssistantService();

  void _handleSendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
    });
    _controller.clear();

    // Analyze the message for navigation intent
    final targetRoute = _navService.identifyTargetRoute(text);

    if (targetRoute != null) {
      final confirmation = _navService.getConfirmationMessage(targetRoute);
      
      setState(() {
        _messages.add({'role': 'assistant', 'content': confirmation});
      });

      // Execute navigation after a short delay so the user can read the confirmation
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pushNamed(context, targetRoute);
        }
      });
    } else {
      setState(() {
        _messages.add({
          'role': 'assistant', 
          'content': "I'm sorry, I didn't quite catch that. Try asking for your 'cart', 'profile', or 'settings'."
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Navigation Assistant")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUser = _messages[index]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_messages[index]['content']!),
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
                    decoration: const InputDecoration(hintText: "Where would you like to go?"),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _handleSendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}