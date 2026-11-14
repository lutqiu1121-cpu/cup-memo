import 'package:meta/meta.dart';

/// A memory entry.
///
/// Mirrors the `entries` table: [#id] is a UUID, [#mdPath] points at the
/// Markdown file on disk, [#contentHash] is used for de-duplication and
/// [#sessionId] links the entry to the chat session that produced it.
@immutable
class Entry {
  const Entry({
    required this.id,
    required this.title,
    this.category = '',
    this.tags = const <String>[],
    this.mdPath = '',
    this.contentHash = '',
    this.sessionId,
    required this.createdAt,
    required this.updatedAt,
    this.taskStatus = 'none',
    this.isAiContext = false,
  });

  final String id;
  final String title;
  final String category;
  final List<String> tags;
  final String mdPath;
  final String contentHash;
  final String? sessionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// One of `none`, `open`, `done`.
  final String taskStatus;
  final bool isAiContext;

  /// Comma separated tag list, as stored in the `tags` column.
  String get tagsAsText => tags.join(',');

  Map<String, Object?> toRow() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'category': category,
      'tags': tagsAsText,
      'md_path': mdPath,
      'content_hash': contentHash,
      'session_id': sessionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'task_status': taskStatus,
      'is_ai_context': isAiContext ? 1 : 0,
    };
  }

  factory Entry.fromRow(Map<String, Object?> row) {
    return Entry(
      id: row['id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      category: row['category'] as String? ?? '',
      tags: _splitTags(row['tags'] as String?),
      mdPath: row['md_path'] as String? ?? '',
      contentHash: row['content_hash'] as String? ?? '',
      sessionId: row['session_id'] as String?,
      createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(row['updated_at']) ?? DateTime.now(),
      taskStatus: row['task_status'] as String? ?? 'none',
      isAiContext: ((row['is_ai_context'] as int?) ?? 0) != 0,
    );
  }

  Entry copyWith({
    String? title,
    String? category,
    List<String>? tags,
    String? mdPath,
    String? contentHash,
    String? sessionId,
    DateTime? updatedAt,
    String? taskStatus,
    bool? isAiContext,
  }) {
    return Entry(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      mdPath: mdPath ?? this.mdPath,
      contentHash: contentHash ?? this.contentHash,
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      taskStatus: taskStatus ?? this.taskStatus,
      isAiContext: isAiContext ?? this.isAiContext,
    );
  }

  static List<String> _splitTags(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <String>[];
    }
    return raw
        .split(',')
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
