import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'dao/entry_dao.dart';
import 'dao/provider_dao.dart';
import 'dao/task_dao.dart';
import 'schema.dart';

/// Thin hand-written wrapper around a [Database] connection.
///
/// There is no `build_runner` / drift code generation in this project: every
/// statement lives in plain SQL (see [Schema] and `ProviderDao`).
class AppDatabase {
  AppDatabase._(this._db, this.storageDirectory)
      : providerDao = ProviderDao(_db),
        entryDao = EntryDao(_db),
        taskDao = TaskDao(_db);

  final Database _db;

  /// Directory used for Markdown entry bodies and the database file.
  final Directory storageDirectory;

  /// Hand-written DAOs.
  final ProviderDao providerDao;
  final EntryDao entryDao;
  final TaskDao taskDao;

  /// Escape hatch for future DAOs / tests.
  Database get raw => _db;

  /// Opens (and creates / upgrades) the on-disk database.
  ///
  /// [overridePath] is used by tests; in the app the file is placed inside the
  /// application support directory.
  static Future<AppDatabase> open({String? overridePath}) async {
    final String path;
    if (overridePath != null) {
      path = overridePath;
    } else {
      final Directory dir = await getApplicationSupportDirectory();
      path = p.join(dir.path, Schema.databaseFileName);
    }
    await Directory(p.dirname(path)).create(recursive: true);

    final Database db = sqlite3.open(path);
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA foreign_keys = ON;');

    final int currentVersion = db.userVersion;
    if (currentVersion == 0) {
      createSchema(db);
      db.userVersion = Schema.version;
    } else if (currentVersion < Schema.version) {
      onUpgrade(db, currentVersion, Schema.version);
      db.userVersion = Schema.version;
    }
    return AppDatabase._(db, Directory(p.dirname(path)));
  }

  /// Creates every table / FTS index. Idempotent (`CREATE ... IF NOT EXISTS`).
  static void createSchema(Database db) {
    for (final String statement in Schema.createStatements) {
      db.execute(statement);
    }
  }

  /// In-memory database for widget tests: same schema, throw-away storage.
  @visibleForTesting
  factory AppDatabase.inMemory({Database? database}) {
    final Database db = database ?? sqlite3.openInMemory();
    createSchema(db);
    db.userVersion = Schema.version;
    return AppDatabase._(
      db,
      Directory.systemTemp.createTempSync('cup_memo_test_'),
    );
  }

  /// Migration hook.
  ///
  /// Intentionally empty for schema version 1 — there is nothing to migrate
  /// from yet. When [Schema.version] is bumped, add the step-wise `ALTER TABLE`
  /// / `CREATE TABLE` statements here (one `if (oldVersion < n)` block per
  /// version) and keep this comment in sync with [Schema.version].
  static void onUpgrade(Database db, int oldVersion, int newVersion) {
    // Intentionally left empty for schema version 1.
    //
    // TODO(db): when [Schema.version] becomes 2, add
    //   if (oldVersion < 2) { db.execute('ALTER TABLE ...'); }
    // and keep every step idempotent so an interrupted upgrade can be retried.
  }

  /// Closes the underlying connection. Safe to call once.
  void close() {
    _db.dispose();
  }
}
