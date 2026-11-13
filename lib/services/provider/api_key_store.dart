import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores API keys in `flutter_secure_storage` (Android Keystore backed).
///
/// The database only ever holds the opaque [ProviderConfig.apiKeyRef]; the
/// secret itself never leaves the platform keystore.
class ApiKeyStore {
  const ApiKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _prefix = 'cup_memo.provider.api_key.';

  String _keyFor(String apiKeyRef) => '$_prefix$apiKeyRef';

  /// Reads the key for [apiKeyRef], or `null` when none was saved.
  Future<String?> read(String apiKeyRef) {
    if (apiKeyRef.isEmpty) {
      return Future<String?>.value();
    }
    return _storage.read(key: _keyFor(apiKeyRef));
  }

  /// Saves [apiKey] for [apiKeyRef]. An empty key deletes the entry.
  Future<void> write(String apiKeyRef, String apiKey) {
    if (apiKeyRef.isEmpty) {
      return Future<void>.value();
    }
    if (apiKey.trim().isEmpty) {
      return _storage.delete(key: _keyFor(apiKeyRef));
    }
    return _storage.write(key: _keyFor(apiKeyRef), value: apiKey.trim());
  }

  Future<void> delete(String apiKeyRef) {
    if (apiKeyRef.isEmpty) {
      return Future<void>.value();
    }
    return _storage.delete(key: _keyFor(apiKeyRef));
  }

  /// Whether a key has been stored for [apiKeyRef].
  Future<bool> hasKey(String apiKeyRef) async {
    final String? value = await read(apiKeyRef);
    return value != null && value.isNotEmpty;
  }
}
