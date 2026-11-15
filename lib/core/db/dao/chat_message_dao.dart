import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../../models/chat_message.dart';

class ChatMessageDao {
  ChatMessageDao(this._db);
  final Database _db;
  List<ChatMessage> list(String sessionId, {int limit = 50, int offset = 0}) {
    final Set<String> columns = _db
        .select('PRAGMA table_info(chat_messages)')
        .map((row) => row['name'] as String)
        .toSet();
    final String parent = columns.contains('parent_id')
        ? 'parent_id'
        : 'NULL AS parent_id';
    final String children = columns.contains('children_ids')
        ? 'children_ids'
        : "'[]' AS children_ids";
    final String provider = columns.contains('provider_id')
        ? 'provider_id'
        : 'NULL AS provider_id';
    final String model = columns.contains('model') ? 'model' : 'NULL AS model';
    final String active = columns.contains('active') ? 'AND active = 1' : '';
    final rows = _db.select(
      'SELECT id, session_id, $parent, $children, role, content, created_at, $provider, $model FROM chat_messages WHERE session_id = ? $active ORDER BY created_at DESC LIMIT ? OFFSET ?',
      [sessionId, limit, offset],
    );
    return rows
        .map((row) => ChatMessage.fromRow(Map<String, Object?>.from(row)))
        .toList(growable: false)
        .reversed
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

  void addChild(String parentId, String childId) {
    final ResultSet rows = _db.select(
      'SELECT children_ids FROM chat_messages WHERE id = ?',
      [parentId],
    );
    if (rows.isEmpty) return;
    final Object? raw = rows.first['children_ids'];
    List<String> children;
    try {
      final dynamic decoded = jsonDecode(raw?.toString() ?? '[]');
      children = decoded is List
          ? decoded.map((Object? value) => value.toString()).toList()
          : <String>[];
    } catch (_) {
      children = <String>[];
    }
    if (!children.contains(childId)) children.add(childId);
    _db.execute('UPDATE chat_messages SET children_ids = ? WHERE id = ?', [
      jsonEncode(children),
      parentId,
    ]);
  }

  void deleteAfter(String sessionId, String id) =>
      deactivateFrom(sessionId, id);

  void deactivateMessage(String id) {
    _db.execute('UPDATE chat_messages SET active = 0 WHERE id = ?', [id]);
  }

  void deactivateFrom(String sessionId, String id) {
    _db.execute(
      'UPDATE chat_messages SET active = 0 WHERE session_id = ? AND created_at >= (SELECT created_at FROM chat_messages WHERE id = ?)',
      [sessionId, id],
    );
  }
}
