// Local sanity check for EntryDao (mirrors test/entry_dao_test.dart).
// Run with: dart run tool/entry_dao_check.dart
// ignore_for_file: avoid_print
import 'package:cup_memo/core/db/dao/entry_dao.dart';
import 'package:cup_memo/core/db/schema.dart';
import 'package:sqlite3/sqlite3.dart';

void check(bool condition, String message) {
  if (!condition) {
    throw StateError('FAILED: $message');
  }
  print('ok   $message');
}

void main() {
  final Database db = sqlite3.openInMemory();
  for (final String statement in Schema.createStatements) {
    db.execute(statement);
  }
  final EntryDao dao = EntryDao(db);

  final EntryWriteResult created = dao.insert(
    title: '备忘录索引设计',
    body: '为备忘录设计全文索引',
    category: '设计',
    tags: <String>['本地搜索'],
  );
  check(created.outcome == EntryWriteOutcome.inserted, 'insert 成功');
  check(dao.search('索引').map((e) => e.title).contains('备忘录索引设计'),
      '用「索引」能搜到');
  check(dao.search('备忘').map((e) => e.title).contains('备忘录索引设计'),
      '用「备忘」能搜到');
  check(dao.search('设计').isNotEmpty, '用「设计」能搜到');

  final EntryWriteResult updated = dao.update(
    id: created.entryId,
    title: '新的设计',
    body: '新的正文',
  );
  check(updated.outcome == EntryWriteOutcome.updated, 'update 成功');
  check(dao.search('索引').isEmpty, '更新后旧词「索引」失效');
  check(dao.search('设计').isNotEmpty, '更新后新词「设计」命中');

  final EntryWriteResult dup = dao.insert(
    title: '新的设计',
    body: '新的正文',
  );
  check(dup.outcome == EntryWriteOutcome.duplicate, 'content_hash 去重生效');
  check(dup.entryId == created.entryId, '去重返回已存在的条目 id');

  check(dao.delete(created.entryId), 'delete 成功');
  check(dao.search('设计').isEmpty, '删除后 FTS 行同步清理');
  check(dao.list().isEmpty, '删除后列表为空');

  postCheck(dao);
  db.dispose();
}

void postCheck(EntryDao dao) {
  final EntryWriteResult a = dao.insert(title: '分类测试', body: 'x', category: '灵感');
  dao.insert(title: '另一条', body: 'y', category: '设计');
  check(dao.categories().length == 2, 'categories 返回 2 个分类');
  check(dao.list(category: '灵感').length == 1, '按分类筛选生效');
  dao.delete(a.entryId);
}
