import 'package:flutter/foundation.dart';

/// A single hit returned by a `SearchProvider`.
@immutable
class SearchResult {
  const SearchResult({
    required this.entryId,
    required this.title,
    this.snippet = '',
    this.score = 0,
    this.source = '',
  });

  /// Id of the matching `entries` row.
  final String entryId;
  final String title;

  /// Highlighted excerpt around the match.
  final String snippet;

  /// Relevance, higher is better. `0` when the backend does not rank.
  final double score;

  /// Id of the `SearchProvider` that produced the hit.
  final String source;

  factory SearchResult.fromRow(Map<String, Object?> row) {
    return SearchResult(
      entryId: row['entry_id'] as String? ?? row['id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      snippet: row['snippet'] as String? ?? '',
      score: (row['score'] as num?)?.toDouble() ?? 0,
      source: row['source'] as String? ?? '',
    );
  }

  Map<String, Object?> toRow() {
    return <String, Object?>{
      'entry_id': entryId,
      'title': title,
      'snippet': snippet,
      'score': score,
      'source': source,
    };
  }

  @override
  String toString() =>
      'SearchResult(entryId: $entryId, title: $title, score: $score)';
}
