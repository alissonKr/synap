import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum MessageRole { user, assistant }

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.role,
    this.hasImage = false,
    this.imagePath,
  });

  final String text;
  final MessageRole role;
  final bool hasImage;
  final String? imagePath;
}

class Conversation {
  Conversation(this.title, {List<ChatMessage>? messages})
      : messages = messages ?? <ChatMessage>[];

  String title;
  final List<ChatMessage> messages;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Conversation> _conversations = [];
  final ImagePicker _imagePicker = ImagePicker();

  static const Color _backgroundColor = Colors.black;
  static const Color _surfaceColor = Color(0xFF121212);
  static const Color _userBubbleColor = Color(0xFF1E1E1E);
  static const Color _assistantBubbleColor = Color(0xFF2A2A2A);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Colors.white70;

  int _selectedConversationIndex = -1;
  bool _isDraftActive = true;
  XFile? _pendingImage;
  final List<String> _welcomeMessages = const [
    'No que você está pensando hoje?',
    'No que você está trabalhando?',
    'Como posso ajudar?',
    'Tudo pronto? Então vamos lá!',
    'O que tem na agenda de hoje?',
  ];
  String _currentWelcomeMessage = 'Como posso ajudar';

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

  void _startDraft() {
    setState(() {
      _selectedConversationIndex = -1;
      _isDraftActive = true;
      _currentWelcomeMessage =
          _welcomeMessages[Random().nextInt(_welcomeMessages.length)];
      _messageController.clear();
      _pendingImage = null;
    });
  }

  void _toggleDrawer() {
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState == null) return;

    if (scaffoldState.isDrawerOpen) {
      Navigator.of(context).pop();
    } else {
      scaffoldState.openDrawer();
    }
  }

  void _selectConversation(int index) {
    setState(() {
      _selectedConversationIndex = index;
      _isDraftActive = false;
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
          backgroundColor: _surfaceColor,
          title: const Text(
            'Rename conversation',
            style: TextStyle(color: _textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: _textPrimary),
            cursorColor: _textPrimary,
            decoration: InputDecoration(
              hintText: 'Conversation title',
              hintStyle: const TextStyle(color: _textSecondary),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white24),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white54),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(context).pop(text);
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(color: _textPrimary),
              ),
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
      _isDraftActive = false;
    });
  }

  void _clearConversations() {
    setState(() {
      _conversations.clear();
      _selectedConversationIndex = -1;
      _isDraftActive = false;
      _pendingImage = null;
    });
  }

  void _sendMessage() {
    final conversation = _selectedConversation;
    final text = _messageController.text.trim();
    final pendingImagePath = _pendingImage?.path;
    final hasImage = pendingImagePath != null;

    if (text.isEmpty && !hasImage) return;

    if (conversation == null) {
      final title = _deriveTitle(text.isNotEmpty ? text : 'Imagem');
      final newConversation = Conversation(
        title,
        messages: [
          ChatMessage(
            text: text,
            role: MessageRole.user,
            hasImage: hasImage,
            imagePath: pendingImagePath,
          ),
        ],
      );
      setState(() {
        _conversations.add(newConversation);
        _selectedConversationIndex = _conversations.length - 1;
        _isDraftActive = false;
        _messageController.clear();
        _pendingImage = null;
      });
    } else {
      setState(() {
        conversation.messages.add(
          ChatMessage(
            text: text,
            role: MessageRole.user,
            hasImage: hasImage,
            imagePath: pendingImagePath,
          ),
        );
        _pendingImage = null;
      });
      _messageController.clear();
    }

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

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _pendingImage = image;
        if (_selectedConversation == null) {
          _isDraftActive = true;
        }
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surfaceColor,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: _textPrimary),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: _textPrimary),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: _textPrimary),
                title: const Text(
                  'Galeria',
                  style: TextStyle(color: _textPrimary),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }


  String _deriveTitle(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return 'Novo chat';
    if (trimmed.length > 50) {
      return '${trimmed.substring(0, 50)}...';
    }
    return trimmed;
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _surfaceColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startDraft,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _userBubbleColor,
                    foregroundColor: _textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                        style: TextStyle(color: _textSecondary),
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
                          selectedTileColor: Colors.white10,
                          title: Text(
                            conversation.title,
                            style: const TextStyle(color: _textPrimary),
                          ),
                          onTap: () => _selectConversation(index),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: _textSecondary,
                                tooltip: 'Rename',
                                onPressed: () => _renameConversation(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: _textSecondary,
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textPrimary,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
    final messages = conversation?.messages ?? <ChatMessage>[];

    if (messages.isEmpty) {
      return Center(
        child: Text(
          _currentWelcomeMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            color: _textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = message.role == MessageRole.user;
        final hasText = message.text.isNotEmpty;
        final hasImage = message.hasImage && message.imagePath != null;
        final alignment = isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start;
        final bubbleColor = isUser ? _userBubbleColor : _assistantBubbleColor;
        final maxWidth = MediaQuery.of(context).size.width * 0.75;
        final imageMaxWidth = MediaQuery.of(context).size.width * 0.7;
        final constrainedImageWidth = min(maxWidth, imageMaxWidth);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            // user messages align right
            mainAxisAlignment: alignment,
            children: [
              Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (hasImage)
                        Padding(
                          padding:
                              EdgeInsets.only(bottom: hasText ? 8 : 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(message.imagePath!),
                              width: constrainedImageWidth,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      if (hasText)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              message.text,
                              style: const TextStyle(color: _textPrimary),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    final hasConversationOrDraft = _selectedConversation != null || _isDraftActive;

    return SafeArea(
      child: Container(
        color: _backgroundColor,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_pendingImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_pendingImage!.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -10,
                          right: -10,
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            iconSize: 20,
                            onPressed: () {
                              setState(() {
                                _pendingImage = null;
                              });
                            },
                            icon: Container(
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: _textPrimary,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  onPressed:
                      hasConversationOrDraft ? _showImageSourceSheet : null,
                  icon: const Icon(Icons.add),
                  color: _textSecondary,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: hasConversationOrDraft,
                    style: const TextStyle(color: _textPrimary),
                    cursorColor: _textPrimary,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      hintStyle: const TextStyle(color: _textSecondary),
                      filled: true,
                      fillColor: _surfaceColor,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.white54),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: hasConversationOrDraft ? _sendMessage : null,
                  icon: const Icon(Icons.send),
                  color: _textPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0.5,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: InkWell(
            onTap: _toggleDrawer,
            customBorder: const CircleBorder(),
            child: const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/logos/synap.redondo.png'),
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        title: const Text(
          'Synap',
          style: TextStyle(color: _textPrimary),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      drawer: _buildDrawer(),
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          Expanded(child: _buildMessagesArea()),
          _buildInputArea(),
        ],
      ),
    );
  }
}
