import 'dart:io';

import '../core/db/dao/entry_dao.dart';
import '../core/db/database.dart';
import '../core/utils/atomic_file.dart';
import '../core/utils/id.dart';
import '../models/entry.dart';

/// Coordinates EntryDao rows with Markdown body files.
class EntryService {
  EntryService(this.database);

  final AppDatabase database;

  Directory get _entriesDirectory =>
      Directory('${database.storageDirectory.path}/entries');

  Future<List<Entry>> list({String? category}) async {
    return database.entryDao.list(category: category);
  }

  Future<List<String>> categories() async => database.entryDao.categories();

  Future<List<Entry>> search(String query) async => database.entryDao.search(query);

  Future<String> readBody(Entry entry) async {
    if (entry.mdPath.isEmpty) return '';
    return (await readStringIfExists(entry.mdPath)) ?? '';
  }

  Future<EntryWriteResult> create({
    required String title,
    required String body,
    required String category,
    required List<String> tags,
    String? sessionId,
  }) async {
    final String id = newEntryId();
    final String path = '${_entriesDirectory.path}/$id.md';
    final EntryWriteResult result = database.entryDao.insert(
      id: id,
      title: title,
      body: body,
      category: category,
      tags: tags,
      mdPath: path,
      sessionId: sessionId,
    );
    if (result.outcome == EntryWriteOutcome.inserted) {
      try {
        await writeStringAtomic(path, body);
      } catch (_) {
        database.entryDao.delete(id);
        rethrow;
      }
    }
    return result;
  }

  Future<EntryWriteResult> update({
    required Entry entry,
    required String title,
    required String body,
    required String category,
    required List<String> tags,
  }) async {
    final String path = entry.mdPath.isEmpty
        ? '${_entriesDirectory.path}/${entry.id}.md'
        : entry.mdPath;
    final EntryWriteResult result = database.entryDao.update(
      id: entry.id,
      title: title,
      body: body,
      category: category,
      tags: tags,
      mdPath: path,
    );
    if (result.outcome != EntryWriteOutcome.duplicate) {
      await writeStringAtomic(path, body);
    }
    return result;
  }

  Future<bool> delete(Entry entry) async {
    final bool deleted = database.entryDao.delete(entry.id);
    if (deleted && entry.mdPath.isNotEmpty) {
      final File file = File(entry.mdPath);
      if (await file.exists()) await file.delete();
    }
    return deleted;
  }
}
