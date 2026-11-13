import 'package:sqlite3/sqlite3.dart';

import '../../../services/provider/provider_config.dart';

/// Hand-written DAO for the `providers` table.
///
/// Only key *references* are persisted here: the real API key always lives in
/// `flutter_secure_storage` under `ProviderConfig.apiKeyRef`.
class ProviderDao {
  ProviderDao(this._db);

  final Database _db;

  /// All providers, default provider first, then alphabetically.
  List<ProviderConfig> list() {
    final ResultSet rows = _db.select(
      'SELECT id, name, kind, base_url, api_key_ref, default_model, '
      'extra_headers, is_default FROM providers '
      'ORDER BY is_default DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(ProviderConfig.fromRow).toList(growable: false);
  }

  ProviderConfig? findById(String id) {
    final ResultSet rows = _db.select(
      'SELECT id, name, kind, base_url, api_key_ref, default_model, '
      'extra_headers, is_default FROM providers WHERE id = ?',
      <Object?>[id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return ProviderConfig.fromRow(rows.first);
  }

  /// Inserts or replaces [config]'s row (never touches the API key itself).
  void upsert(ProviderConfig config) {
    _db.execute(
      'INSERT OR REPLACE INTO providers '
      '(id, name, kind, base_url, api_key_ref, default_model, extra_headers, is_default) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        config.id,
        config.name,
        config.kind.wireName,
        config.baseUrl,
        config.apiKeyRef,
        config.defaultModel,
        config.extraHeadersJson,
        config.isDefault ? 1 : 0,
      ],
    );
  }

  void delete(String id) {
    _db.execute('DELETE FROM providers WHERE id = ?', <Object?>[id]);
  }

  /// Marks [id] as the only default provider. Passing `null` clears the flag.
  void setDefault(String? id) {
    _db.execute('UPDATE providers SET is_default = 0');
    if (id != null) {
      _db.execute(
        'UPDATE providers SET is_default = 1 WHERE id = ?',
        <Object?>[id],
      );
    }
  }

  ProviderConfig? get defaultProvider {
    final ResultSet rows = _db.select(
      'SELECT id, name, kind, base_url, api_key_ref, default_model, '
      'extra_headers, is_default FROM providers WHERE is_default = 1 LIMIT 1',
    );
    if (rows.isEmpty) {
      return null;
    }
    return ProviderConfig.fromRow(rows.first);
  }

  int count() {
    final ResultSet rows = _db.select('SELECT COUNT(*) AS c FROM providers');
    return (rows.first['c'] as int?) ?? 0;
  }
}
