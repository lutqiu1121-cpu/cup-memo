import '../../models/search_result.dart';
import 'search_provider.dart';

/// Keeps track of the available [SearchProvider]s.
///
/// The registry owns the *ordering* (current provider + fallback chain) while
/// the actual querying lives in the providers themselves. No concrete provider
/// is registered in this stage, so [search] returns an empty list.
class SearchRegistry {
  SearchRegistry({List<SearchProvider> providers = const <SearchProvider>[]}) {
    for (final SearchProvider provider in providers) {
      register(provider);
    }
  }

  final Map<String, SearchProvider> _providers = <String, SearchProvider>{};
  final List<String> _fallbackOrder = <String>[];
  String? _currentId;

  /// All registered providers, registration order.
  List<SearchProvider> get providers =>
      _fallbackOrder.map((String id) => _providers[id]!).toList(growable: false);

  /// Ids of the registered providers.
  List<String> get providerIds => List<String>.unmodifiable(_fallbackOrder);

  /// The provider answering queries right now (may be `null`).
  SearchProvider? get current =>
      _currentId == null ? null : _providers[_currentId];

  /// Fallback chain: registered providers without the current one.
  List<SearchProvider> get fallbacks => _fallbackOrder
      .where((String id) => id != _currentId)
      .map((String id) => _providers[id]!)
      .toList(growable: false);

  /// Registers [provider] (idempotent on [SearchProvider.id]).
  void register(SearchProvider provider) {
    if (!_providers.containsKey(provider.id)) {
      _fallbackOrder.add(provider.id);
    }
    _providers[provider.id] = provider;
    _currentId ??= provider.id;
  }

  void unregister(String providerId) {
    _providers.remove(providerId);
    _fallbackOrder.remove(providerId);
    if (_currentId == providerId) {
      _currentId = _fallbackOrder.isEmpty ? null : _fallbackOrder.first;
    }
  }

  /// Selects [providerId] as the active provider. Returns `false` when the id
  /// is unknown.
  bool select(String providerId) {
    if (!_providers.containsKey(providerId)) {
      return false;
    }
    _currentId = providerId;
    return true;
  }

  /// Runs a query against the current provider, then the fallbacks.
  ///
  /// STUB: no provider is registered yet, so this always resolves to an empty
  /// list. The control flow for the fallback chain is intentionally left in
  /// place for the next stage.
  Future<List<SearchResult>> search(String query, {int limit = 20}) async {
    final String needle = query.trim();
    if (needle.isEmpty) {
      return const <SearchResult>[];
    }
    final List<SearchProvider> chain = <SearchProvider>[
      ?current,
      ...fallbacks,
    ];
    for (final SearchProvider provider in chain) {
      if (!provider.isAvailable) {
        continue;
      }
      final List<SearchResult> results = await provider.search(
        needle,
        limit: limit,
      );
      if (results.isNotEmpty) {
        return results;
      }
    }
    return const <SearchResult>[];
  }
}
