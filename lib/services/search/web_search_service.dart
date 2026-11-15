import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum WebSearchProvider { searxng, brave, tavily }

class WebSearchConfig {
  const WebSearchConfig({
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
  });

  final WebSearchProvider provider;
  final String baseUrl;
  final String apiKey;

  static const String providerKey = 'cup_memo.search.provider';
  static const String urlKey = 'cup_memo.search.url';
  static const String secureKeyRef = 'cup_memo.search.api_key';

  static Future<WebSearchConfig> load(
    SharedPreferences prefs, {
    FlutterSecureStorage? storage,
  }) async {
    final FlutterSecureStorage secureStorage =
        storage ?? const FlutterSecureStorage();
    return WebSearchConfig(
      provider: WebSearchProvider.values.firstWhere(
        (WebSearchProvider p) => p.name == prefs.getString(providerKey),
        orElse: () => WebSearchProvider.searxng,
      ),
      baseUrl: prefs.getString(urlKey) ?? '',
      apiKey: await secureStorage.read(key: secureKeyRef) ?? '',
    );
  }
}

class WebSearchService {
  WebSearchService(this.config, [http.Client? client])
    : _client = client ?? http.Client();
  final WebSearchConfig config;
  final http.Client _client;

  Future<List<Map<String, String>>> search(String query) async {
    final Uri uri;
    final Map<String, String> headers = <String, String>{};
    final Map<String, dynamic> body = <String, dynamic>{};
    switch (config.provider) {
      case WebSearchProvider.searxng:
        if (config.baseUrl.trim().isEmpty) {
          throw StateError('请先填写 SearXNG 接口地址');
        }
        uri = Uri.parse(config.baseUrl).replace(
          queryParameters: <String, String>{'q': query, 'format': 'json'},
        );
        break;
      case WebSearchProvider.brave:
        uri = Uri.parse(
          config.baseUrl.isEmpty
              ? 'https://api.search.brave.com/res/v1/web/search'
              : config.baseUrl,
        ).replace(queryParameters: <String, String>{'q': query});
        headers['X-Subscription-Token'] = config.apiKey;
        break;
      case WebSearchProvider.tavily:
        uri = Uri.parse(
          config.baseUrl.isEmpty
              ? 'https://api.tavily.com/search'
              : config.baseUrl,
        );
        body.addAll(<String, dynamic>{
          'api_key': config.apiKey,
          'query': query,
          'max_results': 5,
        });
        break;
    }
    final http.Response response = config.provider == WebSearchProvider.tavily
        ? await _client.post(
            uri,
            headers: <String, String>{'content-type': 'application/json'},
            body: jsonEncode(body),
          )
        : await _client.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('搜索服务暂不可用');
    }
    final dynamic json = jsonDecode(response.body);
    final dynamic records = config.provider == WebSearchProvider.searxng
        ? (json['results'] ?? const [])
        : config.provider == WebSearchProvider.brave
        ? (json['web']?['results'] ?? const [])
        : (json['results'] ?? const []);
    if (records is! List) return const <Map<String, String>>[];
    return records
        .take(5)
        .whereType<Map>()
        .map(
          (Map item) => <String, String>{
            'title': (item['title'] ?? '').toString(),
            'url': (item['url'] ?? '').toString(),
            'content': (item['content'] ?? item['description'] ?? '')
                .toString(),
          },
        )
        .toList(growable: false);
  }
}
