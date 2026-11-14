import 'package:cup_memo/core/db/dao/entry_dao.dart';
import 'package:cup_memo/core/db/schema.dart';
import 'package:cup_memo/models/entry.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Database database;
  late EntryDao dao;

  setUp(() {
    database = sqlite3.openInMemory();
    for (final String statement in Schema.createStatements) {
      database.execute(statement);
    }
    dao = EntryDao(database);
  });

  tearDown(() => database.dispose());

  test('indexes Chinese bigrams and searches both 备忘 and 索引', () {
    final result = dao.insert(
      title: '备忘录索引设计',
      body: '为备忘录设计全文索引',
      category: '设计',
      tags: <String>['本地搜索'],
    );

    expect(result.outcome, EntryWriteOutcome.inserted);
    expect(dao.search('索引').map((Entry entry) => entry.title),
        contains('备忘录索引设计'));
    expect(dao.search('备忘').map((Entry entry) => entry.title),
        contains('备忘录索引设计'));
  });

  test('updates and deletes the matching FTS row', () {
    final result = dao.insert(
      title: '备忘录索引设计',
      body: '正文',
    );
    expect(dao.search('索引'), isNotEmpty);

    final updated = dao.update(
      id: result.entryId,
      title: '新的设计',
      body: '新的正文',
    );
    expect(updated.outcome, EntryWriteOutcome.updated);
    expect(dao.search('索引'), isEmpty);
    expect(dao.search('设计'), isNotEmpty);

    expect(dao.delete(result.entryId), isTrue);
    expect(dao.search('设计'), isEmpty);
  });

  test('deduplicates by content_hash', () {
    final first = dao.insert(title: '同一条', body: '相同内容');
    final second = dao.insert(title: '同一条', body: '相同内容');
    expect(first.outcome, EntryWriteOutcome.inserted);
    expect(second.outcome, EntryWriteOutcome.duplicate);
    expect(second.entryId, first.entryId);
  });
}
