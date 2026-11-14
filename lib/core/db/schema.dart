/// SQLite schema for Cup Memo (schema version 1).
///
/// This stage only creates the tables — no business logic reads or writes
/// them yet (the sole exception is the `providers` table, which backs the
/// provider-management screen).
class Schema {
  const Schema._();

  /// Current database version, mirrored into `PRAGMA user_version`.
  static const int version = 5;

  /// File name of the database inside the application support directory.
  static const String databaseFileName = 'cup_memo.db';

  /// Table statements executed in order when a fresh database is created.
  static const List<String> createStatements = <String>[
    _createEntries,
    _createEntriesFts,
    _createCurrentTasks,
    _createHistoryTasks,
    _createChatSessions,
    _createSearchCache,
    _createProviders,
  ];

  static const String _createEntries = '''
CREATE TABLE IF NOT EXISTS entries (
  id TEXT PRIMARY KEY,
  title TEXT,
  category TEXT,
  tags TEXT,
  md_path TEXT,
  content_hash TEXT,
  session_id TEXT,
  created_at TEXT,
  updated_at TEXT,
  task_status TEXT DEFAULT 'none',
  is_ai_context INTEGER DEFAULT 0
)
''';

  /// Full-text index over [entries].
  ///
  /// The default (unicode61) tokenizer is used on purpose: Chinese text is
  /// pre-tokenised into bigrams by `cjk_tokenizer.dart` before it is written
  /// here or queried, so FTS5 never has to understand CJK itself. The trigram
  /// tokenizer is explicitly *not* used.
  static const String _createEntriesFts = '''
CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(
  title,
  body,
  tags,
  category
)
''';

  static const String _createCurrentTasks = '''
CREATE TABLE IF NOT EXISTS current_tasks (
  id TEXT PRIMARY KEY,
  title TEXT,
  detail TEXT,
  created_at TEXT
)
''';

  static const String _createHistoryTasks = '''
CREATE TABLE IF NOT EXISTS history_tasks (
  id TEXT PRIMARY KEY,
  title TEXT,
  detail TEXT,
  completed_at TEXT
)
''';

  static const String _createChatSessions = '''
CREATE TABLE IF NOT EXISTS chat_sessions (
  id TEXT PRIMARY KEY,
  started_at TEXT,
  ended_at TEXT,
  archived INTEGER DEFAULT 0,
  bound_context_ids TEXT DEFAULT '[]',
  message_count INTEGER DEFAULT 0
)
''';

  static const String _createSearchCache = '''
CREATE TABLE IF NOT EXISTS search_cache (
  key TEXT PRIMARY KEY,
  payload TEXT,
  created_at TEXT
)
''';

  static const String _createProviders = '''
CREATE TABLE IF NOT EXISTS providers (
  id TEXT PRIMARY KEY,
  name TEXT,
  kind TEXT,
  base_url TEXT,
  api_key_ref TEXT,
  default_model TEXT,
  extra_headers TEXT,
  model_parameters TEXT DEFAULT '{}',
  is_default INTEGER DEFAULT 0
)
''';
}
