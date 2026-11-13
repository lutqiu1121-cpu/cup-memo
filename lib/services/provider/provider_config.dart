import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Wire kinds of a chat provider.
enum ProviderKind {
  openaiCompatible('openai_compatible', 'OpenAI 兼容'),
  deepseekNative('deepseek_native', 'DeepSeek 官方'),
  anthropic('anthropic', 'Anthropic'),
  gemini('gemini', 'Gemini'),
  ollama('ollama', 'Ollama');

  const ProviderKind(this.wireName, this.label);

  /// Value stored in `providers.kind`.
  final String wireName;

  /// Human readable label shown in the UI.
  final String label;

  static ProviderKind fromWire(String? value) {
    return ProviderKind.values.firstWhere(
      (ProviderKind kind) => kind.wireName == value,
      orElse: () => ProviderKind.openaiCompatible,
    );
  }
}

/// A chat provider configuration.
///
/// The API key itself is **never** stored here: [apiKeyRef] is an opaque
/// identifier used as the `flutter_secure_storage` key, and the `providers`
/// table only persists this reference.
@immutable
class ProviderConfig {
  const ProviderConfig({
    required this.id,
    required this.name,
    required this.kind,
    required this.baseUrl,
    required this.apiKeyRef,
    required this.defaultModel,
    this.extraHeaders = const <String, String>{},
    this.isDefault = false,
  });

  final String id;
  final String name;
  final ProviderKind kind;
  final String baseUrl;

  /// `flutter_secure_storage` key under which the API key is stored.
  final String apiKeyRef;
  final String defaultModel;

  /// Additional HTTP headers (e.g. OpenRouter's `HTTP-Referer`).
  final Map<String, String> extraHeaders;

  /// Whether this is the default provider.
  final bool isDefault;

  /// `extra_headers` column value (JSON object).
  String get extraHeadersJson => jsonEncode(extraHeaders);

  bool get requiresApiKey => kind != ProviderKind.ollama;

  /// Shows only the provider id when the key is missing, never a secret.
  String get apiKeyStorageKey => apiKeyRef;

  factory ProviderConfig.fromRow(Map<String, Object?> row) {
    return ProviderConfig(
      id: row['id'] as String? ?? '',
      name: row['name'] as String? ?? '',
      kind: ProviderKind.fromWire(row['kind'] as String?),
      baseUrl: row['base_url'] as String? ?? '',
      apiKeyRef: row['api_key_ref'] as String? ?? '',
      defaultModel: row['default_model'] as String? ?? '',
      extraHeaders: decodeHeaders(row['extra_headers'] as String?),
      isDefault: ((row['is_default'] as int?) ?? 0) != 0,
    );
  }

  Map<String, Object?> toRow() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'kind': kind.wireName,
      'base_url': baseUrl,
      'api_key_ref': apiKeyRef,
      'default_model': defaultModel,
      'extra_headers': extraHeadersJson,
      'is_default': isDefault ? 1 : 0,
    };
  }

  ProviderConfig copyWith({
    String? name,
    ProviderKind? kind,
    String? baseUrl,
    String? apiKeyRef,
    String? defaultModel,
    Map<String, String>? extraHeaders,
    bool? isDefault,
  }) {
    return ProviderConfig(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKeyRef: apiKeyRef ?? this.apiKeyRef,
      defaultModel: defaultModel ?? this.defaultModel,
      extraHeaders: extraHeaders ?? this.extraHeaders,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Encodes a header map as a JSON object string.
  static Map<String, String> decodeHeaders(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const <String, String>{};
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded.map(
          (String key, dynamic value) => MapEntry<String, String>(
            key,
            value?.toString() ?? '',
          ),
        );
      }
    } on FormatException {
      // Corrupted / hand-edited value: fall back to "no extra headers".
    }
    return const <String, String>{};
  }

  /// Parses a `Key: Value` per line text block into a header map.
  static Map<String, String> parseHeadersText(String text) {
    final Map<String, String> headers = <String, String>{};
    for (final String rawLine in text.split('\n')) {
      final String line = rawLine.trim();
      if (line.isEmpty || !line.contains(':')) {
        continue;
      }
      final int split = line.indexOf(':');
      final String key = line.substring(0, split).trim();
      final String value = line.substring(split + 1).trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        headers[key] = value;
      }
    }
    return headers;
  }

  /// Renders [extraHeaders] back into the `Key: Value` text block format.
  static String headersToText(Map<String, String> headers) {
    return headers.entries
        .map((MapEntry<String, String> entry) => '${entry.key}: ${entry.value}')
        .join('\n');
  }
}
