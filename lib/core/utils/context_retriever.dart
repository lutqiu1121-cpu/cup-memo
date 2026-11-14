import '../../../models/entry.dart';
import '../db/dao/entry_dao.dart';

/// Deterministic context selection: ID/timestamp ordering is stable, then
/// local FTS chooses the two most relevant bound entries.
class ContextRetriever {
  const ContextRetriever();

  List<Entry> topBoundMatches(EntryDao dao, List<String> boundIds, String query) {
    if (boundIds.isEmpty || query.trim().isEmpty) return const <Entry>[];
    final allowed = boundIds.toSet();
    final results = dao.search(query).where((Entry e) => allowed.contains(e.id)).toList(growable: false);
    return results.take(2).toList(growable: false);
  }
}
