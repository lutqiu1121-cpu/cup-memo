import '../../models/search_result.dart';

/// Contract every search backend must fulfil (FTS5, vector, remote, …).
///
/// Implementations land in a later stage; this stage only ships the interface
/// plus [SearchRegistry] so the UI can be wired up.
abstract interface class SearchProvider {
  /// Stable id used to register the provider (e.g. `fts5`).
  String get id;

  /// Human readable name shown in the search screen.
  String get displayName;

  /// Whether the backend is ready to answer queries.
  bool get isAvailable;

  /// Runs [query] and returns at most [limit] hits.
  Future<List<SearchResult>> search(String query, {int limit = 20});
}
