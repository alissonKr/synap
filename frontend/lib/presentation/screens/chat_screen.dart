import 'package:flutter/material.dart';

class Conversation {
  Conversation(this.title, {List<String>? messages})
      : messages = messages ?? <String>[];

  String title;
  final List<String> messages;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Conversation> _conversations = [];

  int _selectedConversationIndex = -1;

  Conversation? get _selectedConversation =>
      _selectedConversationIndex >= 0 &&
              _selectedConversationIndex < _conversations.length
          ? _conversations[_selectedConversationIndex]
          : null;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addConversation() {
    setState(() {
      final newTitle = 'Novo chat ${_conversations.length + 1}';
      _conversations.add(Conversation(newTitle));
      _selectedConversationIndex = _conversations.length - 1;
    });
  }

  void _selectConversation(int index) {
    setState(() {
      _selectedConversationIndex = index;
    });
  }

  void _renameConversation(int index) async {
    final controller = TextEditingController(
      text: _conversations[index].title,
    );

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename conversation'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Conversation title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(context).pop(text);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      setState(() {
        _conversations[index].title = newTitle;
      });
    }
  }

  void _deleteConversation(int index) {
    setState(() {
      _conversations.removeAt(index);
      if (_conversations.isEmpty) {
        _selectedConversationIndex = -1;
      } else if (_selectedConversationIndex >= _conversations.length) {
        _selectedConversationIndex = _conversations.length - 1;
      }
    });
  }

  void _clearConversations() {
    setState(() {
      _conversations.clear();
      _selectedConversationIndex = -1;
    });
  }

  void _sendMessage() {
    final conversation = _selectedConversation;
    final text = _messageController.text.trim();
    if (conversation == null || text.isEmpty) return;

    setState(() {
      conversation.messages.add(text);
    });

    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addConversation,
                  icon: const Icon(Icons.add),
                  label: const Text('Novo chat'),
                ),
              ),
            ),
            Expanded(
              child: _conversations.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma conversa ainda',
                        style: TextStyle(color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = _conversations[index];
                        final isSelected = index == _selectedConversationIndex;
                        return ListTile(
                          selected: isSelected,
                          title: Text(conversation.title),
                          onTap: () => _selectConversation(index),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Rename',
                                onPressed: () => _renameConversation(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Delete',
                                onPressed: () => _deleteConversation(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _conversations.isEmpty ? null : _clearConversations,
                  child: const Text('Clear conversations'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesArea() {
    final conversation = _selectedConversation;
    final messages = conversation?.messages ?? <String>[];

    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'Como posso ajudar',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(message),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    final hasConversation = _selectedConversation != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconButton(
              onPressed: hasConversation ? () {} : null,
              icon: const Icon(Icons.add),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: hasConversation,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: hasConversation ? _sendMessage : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synap'),
      ),
      drawer: _buildDrawer(),
      backgroundColor: const Color(0xFFE0F7F4),
      body: Column(
        children: [
          Expanded(child: _buildMessagesArea()),
          _buildInputArea(),
        ],
      ),
    );
  }
}
