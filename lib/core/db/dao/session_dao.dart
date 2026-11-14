import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../../core/utils/id.dart';

class ChatSessionRecord {
  const ChatSessionRecord({required this.id, required this.startedAt, this.endedAt, this.archived = false, this.boundContextIds = const <String>[]});
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool archived;
  final List<String> boundContextIds;

  factory ChatSessionRecord.fromRow(Row row) => ChatSessionRecord(
        id: row['id'] as String,
        startedAt: DateTime.tryParse(row['started_at'] as String? ?? '') ?? DateTime.now(),
        endedAt: row['ended_at'] is String ? DateTime.tryParse(row['ended_at'] as String) : null,
        archived: ((row['archived'] as int?) ?? 0) != 0,
        boundContextIds: _decodeIds(row['bound_context_ids'] as String?),
      );

  static List<String> _decodeIds(String? value) {
    if (value == null || value.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(value);
      return decoded is List ? decoded.map((Object? e) => e.toString()).toList(growable: false) : const <String>[];
    } catch (_) {
      return const <String>[];
    }
  }
}

class SessionDao {
  SessionDao(this._db);
  final Database _db;

  List<ChatSessionRecord> list({bool includeArchived = false}) {
    final ResultSet rows = _db.select(
      'SELECT id, started_at, ended_at, archived, bound_context_ids FROM chat_sessions '
      '${includeArchived ? '' : 'WHERE archived = 0 '}ORDER BY started_at DESC',
    );
    return rows.map(ChatSessionRecord.fromRow).toList(growable: false);
  }

  String create({List<String> boundContextIds = const <String>[]}) {
    final String id = newSessionId();
    _db.execute(
      'INSERT INTO chat_sessions (id, started_at, ended_at, archived, bound_context_ids) VALUES (?, ?, NULL, 0, ?)',
      <Object?>[id, DateTime.now().toIso8601String(), jsonEncode(boundContextIds)],
    );
    return id;
  }

  void bindContext(String id, List<String> entryIds) {
    _db.execute('UPDATE chat_sessions SET bound_context_ids = ? WHERE id = ?', <Object?>[jsonEncode(entryIds), id]);
  }

  void end(String id) {
    _db.execute('UPDATE chat_sessions SET ended_at = ? WHERE id = ?', <Object?>[DateTime.now().toIso8601String(), id]);
  }

  void archive(String id) {
    _db.execute('UPDATE chat_sessions SET archived = 1 WHERE id = ?', <Object?>[id]);
  }

  void delete(String id) {
    _db.execute('DELETE FROM chat_sessions WHERE id = ?', <Object?>[id]);
  }
}
