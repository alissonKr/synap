enum MessageRole { user, assistant, system }

class MessageEntity {
  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    required this.hasImage,
    this.imagePath,
  });

  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final bool hasImage;
  final String? imagePath;
}
