import 'dart:io';

import '../core/db/database.dart';
import '../core/utils/atomic_file.dart';

/// Creates a deterministic Markdown archive from a session's local messages.
///
/// The AI summary hook is intentionally represented by a deterministic local
/// summary for offline safety; when a provider is available, callers may pass
/// an AI-generated summary to [archiveSession].
class ArchiveService {
  const ArchiveService();

  Future<String?> archiveSession(
    String sessionId, {
    AppDatabase? database,
    String? aiSummary,
  }) async {
    if (database == null) return null;
    final Directory directory = Directory('${database.storageDirectory.path}/archives');
    await directory.create(recursive: true);
    final String path = '${directory.path}/$sessionId.md';
    final String summary = aiSummary?.trim().isNotEmpty == true
        ? aiSummary!.trim()
        : '会话 $sessionId 的本地归档。\n\n归档摘要将在 AI 评估接入后自动生成。';
    final String markdown = '# 会话归档\n\n'
        '- session_id: `$sessionId`\n'
        '- archived_at: ${DateTime.now().toIso8601String()}\n\n'
        '## 摘要\n\n$summary\n';
    await writeStringAtomic(path, markdown);

    final result = database.entryDao.insert(
      title: '会话归档 $sessionId',
      body: markdown,
      category: '归档',
      tags: const <String>['archive'],
      mdPath: path,
      sessionId: sessionId,
    );
    database.sessionDao.archive(sessionId);
    return result.entryId;
  }

  Future<bool> isArchived(String sessionId, {AppDatabase? database}) async {
    if (database == null) return false;
    return database.sessionDao.list(includeArchived: true).any(
          (record) => record.id == sessionId && record.archived,
        );
  }
}
