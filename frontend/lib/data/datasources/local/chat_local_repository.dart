import 'dart:math';

import 'package:drift/drift.dart';

import 'app_database.dart';

class ChatLocalRepository {
  ChatLocalRepository(this._db);

  final AppDatabase _db;

  Future<String> createConversation({String? title}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final conversationId = _generateId();

    final companion = ConversationsCompanion(
      id: Value(conversationId),
      title: Value(title),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    await _db.into(_db.conversations).insert(companion);

    return conversationId;
  }

  Stream<List<Conversation>> watchConversations() {
    final query = _db.select(_db.conversations)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]);

    return query.watch();
  }

  Stream<List<Message>> watchMessages(String conversationId) {
    final query = _db.select(_db.messages)
      ..where((tbl) => tbl.conversationId.equals(conversationId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);

    return query.watch();
  }

  Future<void> addUserMessage(
    String conversationId,
    String content, {
    bool hasImage = false,
    String? imagePath,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final messageId = _generateId();

    final companion = MessagesCompanion(
      id: Value(messageId),
      conversationId: Value(conversationId),
      role: const Value('user'),
      content: Value(content),
      createdAt: Value(now),
      hasImage: Value(hasImage),
      imagePath: Value(imagePath),
    );

    await _db.into(_db.messages).insert(companion);
    await _touchConversation(conversationId, now);
  }

  Future<void> addAssistantMessage(String conversationId, String content) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final messageId = _generateId();

    final companion = MessagesCompanion(
      id: Value(messageId),
      conversationId: Value(conversationId),
      role: const Value('assistant'),
      content: Value(content),
      createdAt: Value(now),
    );

    await _db.into(_db.messages).insert(companion);
    await _touchConversation(conversationId, now);
  }

  Future<void> _touchConversation(String conversationId, int updatedAt) async {
    await (_db.update(_db.conversations)..where((tbl) => tbl.id.equals(conversationId))).write(
      ConversationsCompanion(updatedAt: Value(updatedAt)),
    );
  }

  String _generateId() {
    final random = Random.secure();

    String segment(int length) {
      return List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
    }

    return '${segment(8)}-${segment(4)}-${segment(4)}-${segment(4)}-${segment(12)}';
  }
}
