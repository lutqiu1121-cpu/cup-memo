import 'package:cup_memo/core/db/dao/task_dao.dart';
import 'package:cup_memo/core/db/schema.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Database database;
  late TaskDao dao;

  setUp(() {
    database = sqlite3.openInMemory();
    for (final String statement in Schema.createStatements) {
      database.execute(statement);
    }
    dao = TaskDao(database);
  });

  tearDown(() => database.dispose());

  test('adds current tasks and lists them newest first', () {
    dao.addCurrentTask(title: '写搜索页', detail: '带防抖');
    dao.addCurrentTask(title: '写任务页');

    final tasks = dao.listCurrent();
    expect(tasks.length, 2);
    expect(tasks.map((t) => t.title), contains('写搜索页'));
    expect(dao.listHistory(), isEmpty);
  });

  test('completeTask moves the row into history_tasks', () {
    final id = dao.addCurrentTask(title: '完成我', detail: '细节');

    expect(dao.completeTask(id), isTrue);
    expect(dao.listCurrent().where((t) => t.id == id), isEmpty);
    expect(dao.listHistory().map((t) => t.id), contains(id));
    expect(dao.listHistory().first.completedAt, isNotNull);
  });

  test('restoreTask undoes a completion', () {
    final id = dao.addCurrentTask(title: '撤销我');
    expect(dao.completeTask(id), isTrue);

    expect(dao.restoreTask(id), isTrue);
    expect(dao.listCurrent().map((t) => t.id), contains(id));
    expect(dao.listHistory(), isEmpty);
  });

  test('completing an unknown id is a no-op', () {
    expect(dao.completeTask('does-not-exist'), isFalse);
    expect(dao.listHistory(), isEmpty);
  });

  test('delete removes rows from the right table', () {
    final a = dao.addCurrentTask(title: 'A');
    final b = dao.addCurrentTask(title: 'B');
    dao.completeTask(b);

    expect(dao.deleteCurrent(a), isTrue);
    expect(dao.deleteHistory(b), isTrue);
    expect(dao.listCurrent(), isEmpty);
    expect(dao.listHistory(), isEmpty);
  });
}
