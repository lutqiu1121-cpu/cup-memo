import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../../models/chat_message.dart';

class ChatMessageDao {
  ChatMessageDao(this._db);
  final Database _db;
  List<ChatMessage> list(String sessionId, {int limit = 50, int offset = 0}) {
    final rows = _db.select(
      'SELECT id, session_id, parent_id, children_ids, role, content, created_at, provider_id, model FROM chat_messages WHERE session_id = ? AND active = 1 ORDER BY created_at ASC LIMIT ? OFFSET ?',
      [sessionId, limit, offset],
    );
    return rows
        .map((row) => ChatMessage.fromRow(Map<String, Object?>.from(row)))
        .toList(growable: false);
  }

  void upsert(ChatMessage message) {
    _db.execute(
      'INSERT OR REPLACE INTO chat_messages (id, session_id, parent_id, children_ids, role, content, created_at, provider_id, model, active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)',
      [
        message.id,
        message.sessionId,
        message.parentId,
        jsonEncode(message.childrenIds),
        message.role.wireName,
        message.content,
        message.createdAt.toIso8601String(),
        message.providerId,
        message.model,
      ],
    );
  }

  void deleteAfter(String sessionId, String id) {
    _db.execute(
      'UPDATE chat_messages SET active = 0 WHERE session_id = ? AND created_at > (SELECT created_at FROM chat_messages WHERE id = ?)',
      [sessionId, id],
    );
  }
}
