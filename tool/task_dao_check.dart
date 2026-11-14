// Local sanity check for TaskDao (mirrors test/task_dao_test.dart).
// ignore_for_file: avoid_print
import 'package:cup_memo/core/db/dao/task_dao.dart';
import 'package:cup_memo/core/db/schema.dart';
import 'package:sqlite3/sqlite3.dart';

void check(bool ok, String msg) {
  if (!ok) throw StateError('FAILED: $msg');
  print('ok   $msg');
}

void main() {
  final db = sqlite3.openInMemory();
  for (final s in Schema.createStatements) {
    db.execute(s);
  }
  final dao = TaskDao(db);

  final a = dao.addCurrentTask(title: '写搜索页', detail: '带防抖');
  final b = dao.addCurrentTask(title: '写任务页');
  check(dao.listCurrent().length == 2, 'addCurrentTask 写入 current_tasks');
  check(dao.listHistory().isEmpty, '初始 history 为空');

  check(dao.completeTask(b), 'completeTask 成功');
  check(dao.listCurrent().length == 1, '完成后 current 少一条');
  check(dao.listHistory().length == 1, '完成后 history 多一条');
  check(dao.listHistory().first.completedAt != null, 'completed_at 已写入');

  check(dao.restoreTask(b), 'restoreTask 撤销成功');
  check(dao.listCurrent().length == 2, '撤销后 current 恢复 2 条');
  check(dao.listHistory().isEmpty, '撤销后 history 清空');

  check(!dao.completeTask('nope'), '对未知 id complete 返回 false');

  check(dao.deleteCurrent(a), 'deleteCurrent 成功');
  dao.completeTask(b);
  check(dao.deleteHistory(b), 'deleteHistory 成功');
  check(dao.listCurrent().isEmpty && dao.listHistory().isEmpty, '删除后两表皆空');
  db.dispose();
}
