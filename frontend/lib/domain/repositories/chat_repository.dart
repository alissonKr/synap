import 'package:frontend/domain/entities/conversation_entity.dart';
import 'package:frontend/domain/entities/message_entity.dart';

abstract class ChatRepository {
  Stream<List<ConversationEntity>> watchConversations();

  Stream<List<MessageEntity>> watchMessages(String conversationId);

  Future<String> createConversation({String? title});

  Future<void> renameConversation(String conversationId, String title);

  Future<void> deleteConversation(String conversationId);

  Future<void> clearConversations();

  Future<void> addUserMessage(
    String conversationId,
    String content, {
    bool hasImage = false,
    String? imagePath,
  });

  Future<void> addAssistantMessage(String conversationId, String content);
}
