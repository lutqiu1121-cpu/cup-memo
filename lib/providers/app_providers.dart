import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/db/database.dart';
import '../services/archive_service.dart';
import '../services/provider/api_key_store.dart';
import '../services/provider/provider_config.dart';
import '../services/provider/provider_router.dart';
import '../services/search/search_registry.dart';

/// Injected in `main()` — the single [SharedPreferences] instance.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>((Ref ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider 必须在 main() 中通过 overrideWithValue 注入',
  );
});

/// The opened database, or `null` when the app runs in a degraded mode
/// (e.g. the native SQLite library failed to load).
///
/// Injected in `main()`; a `null` value is a legal state and the UI degrades
/// gracefully instead of crashing at launch.
final Provider<AppDatabase?> databaseProvider =
    Provider<AppDatabase?>((Ref ref) => null);

/// API keys live in the platform keystore, never in the database.
final Provider<ApiKeyStore> apiKeyStoreProvider = Provider<ApiKeyStore>(
  (Ref ref) => const ApiKeyStore(),
);

/// Session archiver (stub in this stage).
final Provider<ArchiveService> archiveServiceProvider =
    Provider<ArchiveService>((Ref ref) => const ArchiveService());

/// Registry of search backends (empty in this stage).
final Provider<SearchRegistry> searchRegistryProvider =
    Provider<SearchRegistry>((Ref ref) => SearchRegistry());

/// Immutable list state of the provider-management screen.
@immutable
class ProviderListState {
  const ProviderListState({
    this.items = const <ProviderConfig>[],
    this.databaseReady = true,
    this.error,
  });

  final List<ProviderConfig> items;

  /// `false` when there is no usable database connection.
  final bool databaseReady;

  /// Last error message, if any.
  final String? error;

  bool get isEmpty => items.isEmpty;

  ProviderConfig? get defaultProvider {
    for (final ProviderConfig item in items) {
      if (item.isDefault) {
        return item;
      }
    }
    return items.isEmpty ? null : items.first;
  }

  ProviderConfig? byId(String? id) {
    if (id == null) {
      return null;
    }
    for (final ProviderConfig item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  ProviderListState copyWith({
    List<ProviderConfig>? items,
    bool? databaseReady,
    String? error,
  }) {
    return ProviderListState(
      items: items ?? this.items,
      databaseReady: databaseReady ?? this.databaseReady,
      error: error,
    );
  }
}

/// CRUD for the `providers` table plus secure-storage key handling.
class ProviderListController extends Notifier<ProviderListState> {
  @override
  ProviderListState build() {
    final AppDatabase? db = ref.watch(databaseProvider);
    if (db == null) {
      return const ProviderListState(
        databaseReady: false,
        error: '数据库不可用，Provider 配置无法加载。',
      );
    }
    try {
      return ProviderListState(items: db.providerDao.list());
    } catch (error, stackTrace) {
      debugPrint('ProviderListController.build failed: $error\n$stackTrace');
      return ProviderListState(
        databaseReady: false,
        error: '读取 Provider 失败：$error',
      );
    }
  }

  AppDatabase? get _db => ref.read(databaseProvider);

  /// Reloads the list from SQLite.
  void reload() {
    final AppDatabase? db = _db;
    if (db == null) {
      state = const ProviderListState(
        databaseReady: false,
        error: '数据库不可用，Provider 配置无法加载。',
      );
      return;
    }
    state = ProviderListState(items: db.providerDao.list());
  }

  /// Inserts or updates [config].
  ///
  /// When [apiKey] is a non-empty string it replaces the secret in the secure
  /// storage; `null` keeps the existing secret untouched.
  Future<bool> save(ProviderConfig config, {String? apiKey}) async {
    final AppDatabase? db = _db;
    if (db == null) {
      state = state.copyWith(error: '数据库不可用，无法保存 Provider。');
      return false;
    }
    try {
      db.providerDao.upsert(config);
      if (config.isDefault) {
        db.providerDao.setDefault(config.id);
      }
      if (apiKey != null && apiKey.isNotEmpty) {
        await ref.read(apiKeyStoreProvider).write(config.apiKeyRef, apiKey);
      }
      reload();
      return true;
    } catch (error, stackTrace) {
      debugPrint('ProviderListController.save failed: $error\n$stackTrace');
      state = state.copyWith(error: '保存 Provider 失败：$error');
      return false;
    }
  }

  /// Marks [id] as the default provider.
  Future<void> setDefault(String id) async {
    final AppDatabase? db = _db;
    if (db == null) {
      return;
    }
    db.providerDao.setDefault(id);
    reload();
  }

  /// Deletes [id] together with its stored API key.
  Future<void> remove(String id) async {
    final AppDatabase? db = _db;
    if (db == null) {
      return;
    }
    final ProviderConfig? existing = db.providerDao.findById(id);
    db.providerDao.delete(id);
    if (existing != null) {
      await ref.read(apiKeyStoreProvider).delete(existing.apiKeyRef);
    }
    reload();
  }
}

/// The provider list shown by the settings UI.
final NotifierProvider<ProviderListController, ProviderListState>
    providerListProvider =
    NotifierProvider<ProviderListController, ProviderListState>(
  ProviderListController.new,
);

/// Id of the provider selected for the **current chat session**.
///
/// `null` means "follow the default provider". Switching it only changes the
/// provider used for subsequent messages — the message history is untouched.
class CurrentProviderController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? providerId) => state = providerId;
}

final NotifierProvider<CurrentProviderController, String?> currentProviderIdProvider =
    NotifierProvider<CurrentProviderController, String?>(
  CurrentProviderController.new,
);

/// The provider the chat page will use for the next message.
final Provider<ProviderConfig?> activeProviderProvider =
    Provider<ProviderConfig?>((Ref ref) {
  final ProviderListState list = ref.watch(providerListProvider);
  final ProviderConfig? selected =
      list.byId(ref.watch(currentProviderIdProvider));
  return selected ?? list.defaultProvider;
});

/// Router bound to the active provider (`null` when nothing is configured).
final Provider<ProviderRouter?> providerRouterProvider =
    Provider<ProviderRouter?>((Ref ref) {
  final ProviderConfig? active = ref.watch(activeProviderProvider);
  return active == null ? null : ProviderRouter(active);
});
