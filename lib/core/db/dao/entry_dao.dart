import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../core/utils/cjk_tokenizer.dart';
import '../../../core/utils/id.dart';
import '../../../models/entry.dart';

enum EntryWriteOutcome { inserted, updated, duplicate }

class EntryWriteResult {
  const EntryWriteResult({required this.outcome, required this.entryId});

  final EntryWriteOutcome outcome;
  final String entryId;

  bool get changed => outcome != EntryWriteOutcome.duplicate;
}

/// Hand-written DAO for entries and their manually maintained FTS5 rows.
class EntryDao {
  EntryDao(this._db);

  final Database _db;

  List<Entry> list({String? category}) {
    final String where = category == null || category.isEmpty
        ? ''
        : ' WHERE category = ?';
    final ResultSet rows = _db.select(
      'SELECT id, title, category, tags, md_path, content_hash, session_id, '
      'created_at, updated_at, task_status FROM entries$where '
      'ORDER BY updated_at DESC',
      category == null || category.isEmpty ? const <Object?>[] : <Object?>[category],
    );
    return rows.map(Entry.fromRow).toList(growable: false);
  }

  List<String> categories() {
    final ResultSet rows = _db.select(
      "SELECT DISTINCT category FROM entries WHERE category IS NOT NULL "
      "AND category <> '' ORDER BY category COLLATE NOCASE",
    );
    return rows
        .map((Row row) => row['category'] as String? ?? '')
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Entry? findById(String id) {
    final ResultSet rows = _db.select(
      'SELECT id, title, category, tags, md_path, content_hash, session_id, '
      'created_at, updated_at, task_status FROM entries WHERE id = ?',
      <Object?>[id],
    );
    return rows.isEmpty ? null : Entry.fromRow(rows.first);
  }

  EntryWriteResult insert({
    required String title,
    required String body,
    String category = '',
    List<String> tags = const <String>[],
    String mdPath = '',
    String? sessionId,
    String? id,
    DateTime? now,
  }) {
    final DateTime timestamp = now ?? DateTime.now();
    final String entryId = id ?? newEntryId();
    final List<String> cleanTags = _cleanTags(tags);
    final String hash = contentHash(
      title: title,
      body: body,
      category: category,
      tags: cleanTags,
    );
    final ResultSet duplicate = _db.select(
      'SELECT id FROM entries WHERE content_hash = ? LIMIT 1',
      <Object?>[hash],
    );
    if (duplicate.isNotEmpty) {
      return EntryWriteResult(
        outcome: EntryWriteOutcome.duplicate,
        entryId: duplicate.first['id'] as String,
      );
    }

    _db.execute(
      'INSERT INTO entries '
      '(id, title, category, tags, md_path, content_hash, session_id, '
      'created_at, updated_at, task_status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        entryId,
        title.trim(),
        category.trim(),
        cleanTags.join(','),
        mdPath,
        hash,
        sessionId,
        timestamp.toIso8601String(),
        timestamp.toIso8601String(),
        'none',
      ],
    );
    _writeFts(
      rowId: _db.lastInsertRowId,
      title: title,
      body: body,
      tags: cleanTags,
      category: category,
    );
    return EntryWriteResult(
      outcome: EntryWriteOutcome.inserted,
      entryId: entryId,
    );
  }

  EntryWriteResult update({
    required String id,
    required String body,
    required String title,
    String category = '',
    List<String> tags = const <String>[],
    String? mdPath,
    DateTime? now,
  }) {
    final ResultSet current = _db.select(
      'SELECT rowid, content_hash FROM entries WHERE id = ?',
      <Object?>[id],
    );
    if (current.isEmpty) {
      return insert(
        id: id,
        title: title,
        body: body,
        category: category,
        tags: tags,
        mdPath: mdPath ?? '',
        now: now,
      );
    }
    final List<String> cleanTags = _cleanTags(tags);
    final String hash = contentHash(
      title: title,
      body: body,
      category: category,
      tags: cleanTags,
    );
    final ResultSet duplicate = _db.select(
      'SELECT id FROM entries WHERE content_hash = ? AND id <> ? LIMIT 1',
      <Object?>[hash, id],
    );
    if (duplicate.isNotEmpty) {
      return EntryWriteResult(
        outcome: EntryWriteOutcome.duplicate,
        entryId: duplicate.first['id'] as String,
      );
    }

    final String updatedAt = (now ?? DateTime.now()).toIso8601String();
    _db.execute(
      'UPDATE entries SET title = ?, category = ?, tags = ?, '
      'md_path = COALESCE(?, md_path), content_hash = ?, updated_at = ? '
      'WHERE id = ?',
      <Object?>[
        title.trim(),
        category.trim(),
        cleanTags.join(','),
        mdPath,
        hash,
        updatedAt,
        id,
      ],
    );
    final int rowId = current.first['rowid'] as int;
    _db.execute('DELETE FROM entries_fts WHERE rowid = ?', <Object?>[rowId]);
    _writeFts(
      rowId: rowId,
      title: title,
      body: body,
      tags: cleanTags,
      category: category,
    );
    return EntryWriteResult(outcome: EntryWriteOutcome.updated, entryId: id);
  }

  bool delete(String id) {
    final ResultSet rows = _db.select(
      'SELECT rowid FROM entries WHERE id = ?',
      <Object?>[id],
    );
    if (rows.isEmpty) return false;
    final int rowId = rows.first['rowid'] as int;
    _db.execute('DELETE FROM entries_fts WHERE rowid = ?', <Object?>[rowId]);
    _db.execute('DELETE FROM entries WHERE id = ?', <Object?>[id]);
    return true;
  }

  List<Entry> search(String query, {int limit = 50}) {
    final String tokenized = tokenizeForFts(query);
    if (tokenized.isEmpty) return const <Entry>[];
    final ResultSet rows = _db.select(
      'SELECT e.id, e.title, e.category, e.tags, e.md_path, e.content_hash, '
      'e.session_id, e.created_at, e.updated_at, e.task_status '
      'FROM entries e JOIN entries_fts f ON f.rowid = e.rowid '
      'WHERE entries_fts MATCH ? ORDER BY e.updated_at DESC LIMIT ?',
      <Object?>[tokenized, limit],
    );
    return rows.map(Entry.fromRow).toList(growable: false);
  }

  static String contentHash({
    required String title,
    required String body,
    required String category,
    required List<String> tags,
  }) {
    final String canonical = jsonEncode(<Object?>[
      title.trim(),
      body,
      category.trim(),
      _cleanTags(tags),
    ]);
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  void _writeFts({
    required int rowId,
    required String title,
    required String body,
    required List<String> tags,
    required String category,
  }) {
    _db.execute(
      'INSERT INTO entries_fts(rowid, title, body, tags, category) '
      'VALUES (?, ?, ?, ?, ?)',
      <Object?>[
        rowId,
        tokenizeForFts(title),
        tokenizeForFts(body),
        tokenizeForFts(tags.join(' ')),
        tokenizeForFts(category),
      ],
    );
  }

  static List<String> _cleanTags(List<String> tags) {
    return tags
        .map((String tag) => tag.trim())
        .where((String tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}
