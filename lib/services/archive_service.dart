import 'package:flutter/foundation.dart';

/// Archives a chat session (Markdown export, cold storage, …).
///
/// Business logic is out of scope for this stage: [archiveSession] returns
/// `null` to signal "nothing archived yet".
class ArchiveService {
  const ArchiveService();

  /// Archives [sessionId] and returns the path of the produced artifact, or
  /// `null` when the session was not archived.
  ///
  /// STUB — always returns `null` in the framework build.
  Future<String?> archiveSession(String sessionId) async {
    debugPrint('ArchiveService.archiveSession($sessionId): TODO, not implemented');
    return null;
  }

  /// Whether [sessionId] already has an archive.
  ///
  /// STUB — always `false`.
  Future<bool> isArchived(String sessionId) async => false;
}
