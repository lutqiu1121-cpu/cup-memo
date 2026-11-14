import 'package:sqlite3/sqlite3.dart';

import '../../../core/utils/id.dart';
import '../../../models/task.dart';

/// Hand-written DAO for the two task tables.
///
/// A task lives in exactly one table: `current_tasks` while it is open, and
/// `history_tasks` once it is completed. Completing / restoring is therefore a
/// move between the two tables, not an UPDATE of a status column.
class TaskDao {
  TaskDao(this._db);

  final Database _db;

  static const String _currentColumns = 'id, title, detail, created_at';
  static const String _historyColumns = 'id, title, detail, completed_at';

  /// Open tasks, newest first.
  List<Task> listCurrent() {
    final ResultSet rows = _db.select(
      'SELECT $_currentColumns FROM current_tasks ORDER BY created_at DESC',
    );
    return rows.map(Task.fromCurrentRow).toList(growable: false);
  }

  /// Completed tasks, most recently completed first.
  List<Task> listHistory() {
    final ResultSet rows = _db.select(
      'SELECT $_historyColumns FROM history_tasks ORDER BY completed_at DESC',
    );
    return rows.map(Task.fromHistoryRow).toList(growable: false);
  }

  Task? findCurrent(String id) {
    final ResultSet rows = _db.select(
      'SELECT $_currentColumns FROM current_tasks WHERE id = ?',
      <Object?>[id],
    );
    return rows.isEmpty ? null : Task.fromCurrentRow(rows.first);
  }

  /// Creates an open task and returns its id.
  String addCurrentTask({
    required String title,
    String detail = '',
    DateTime? now,
  }) {
    final String id = newTaskId();
    _db.execute(
      'INSERT INTO current_tasks (id, title, detail, created_at) '
      'VALUES (?, ?, ?, ?)',
      <Object?>[
        id,
        title.trim(),
        detail.trim(),
        (now ?? DateTime.now()).toIso8601String(),
      ],
    );
    return id;
  }

  /// Moves [id] from `current_tasks` to `history_tasks`.
  ///
  /// Returns `false` when the task does not exist.
  bool completeTask(String id, {DateTime? now}) {
    final ResultSet rows = _db.select(
      'SELECT $_currentColumns FROM current_tasks WHERE id = ?',
      <Object?>[id],
    );
    if (rows.isEmpty) {
      return false;
    }
    final Row row = rows.first;
    _db.execute(
      'INSERT OR REPLACE INTO history_tasks (id, title, detail, completed_at) '
      'VALUES (?, ?, ?, ?)',
      <Object?>[
        row['id'],
        row['title'],
        row['detail'],
        (now ?? DateTime.now()).toIso8601String(),
      ],
    );
    _db.execute('DELETE FROM current_tasks WHERE id = ?', <Object?>[id]);
    return true;
  }

  /// Undo for [completeTask]: moves [id] back to `current_tasks`.
  bool restoreTask(String id, {DateTime? now}) {
    final ResultSet rows = _db.select(
      'SELECT $_historyColumns FROM history_tasks WHERE id = ?',
      <Object?>[id],
    );
    if (rows.isEmpty) {
      return false;
    }
    final Row row = rows.first;
    _db.execute(
      'INSERT OR REPLACE INTO current_tasks (id, title, detail, created_at) '
      'VALUES (?, ?, ?, ?)',
      <Object?>[
        row['id'],
        row['title'],
        row['detail'],
        (now ?? DateTime.now()).toIso8601String(),
      ],
    );
    _db.execute('DELETE FROM history_tasks WHERE id = ?', <Object?>[id]);
    return true;
  }

  bool deleteCurrent(String id) {
    _db.execute('DELETE FROM current_tasks WHERE id = ?', <Object?>[id]);
    return _db.updatedRows > 0;
  }

  bool deleteHistory(String id) {
    _db.execute('DELETE FROM history_tasks WHERE id = ?', <Object?>[id]);
    return _db.updatedRows > 0;
  }
}
