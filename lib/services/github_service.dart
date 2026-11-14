import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/utils/privacy_filter.dart';

/// Small in-memory cache for GitHub file reads. The key includes repo/ref/path
/// so repeated Agent tool calls are served without another network request.
class GitHubService {
  GitHubService({FlutterSecureStorage? storage, Dio? dio})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ?? Dio();

  static const String tokenKey = 'cup_memo.github.personal_access_token';
  final FlutterSecureStorage _storage;
  final Dio _dio;
  final Map<String, String> _fileCache = <String, String>{};

  Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token.trim());
  }

  Future<String?> readToken() => _storage.read(key: tokenKey);

  Future<void> clearToken() => _storage.delete(key: tokenKey);

  Future<String> fetchFile({required String owner, required String repo, required String path, String ref = 'main'}) async {
    final String cacheKey = '$owner/$repo@$ref:$path';
    final String? cached = _fileCache[cacheKey];
    if (cached != null) return cached;
    final String? token = await readToken();
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.github.com/repos/$owner/$repo/contents/$path',
      queryParameters: <String, String>{'ref': ref},
      options: Options(headers: <String, String>{
        'Accept': 'application/vnd.github+json',
        if (token?.isNotEmpty ?? false) 'Authorization': 'Bearer $token',
      }),
    );
    final data = response.data ?? const <String, dynamic>{};
    final String content = utf8.decode(base64Decode((data['content'] as String? ?? '').replaceAll('\n', '')));
    _fileCache[cacheKey] = PrivacyFilter.redact(content);
    return _fileCache[cacheKey]!;
  }

  Future<void> commitFile({required String owner, required String repo, required String path, required String content, required String message, String branch = 'main'}) async {
    final String? token = await readToken();
    if (token == null || token.isEmpty) throw StateError('GitHub Token 未配置');
    final String url = 'https://api.github.com/repos/$owner/$repo/contents/$path';
    String? sha;
    try {
      final old = await _dio.get<Map<String, dynamic>>(url, queryParameters: <String, String>{'ref': branch}, options: Options(headers: <String, String>{'Authorization': 'Bearer $token'}));
      sha = old.data?['sha'] as String?;
    } catch (_) {}
    await _dio.put<void>(url, data: <String, dynamic>{
      'message': message,
      'content': base64Encode(utf8.encode(PrivacyFilter.redact(content))),
      'branch': branch,
      if (sha case final String value) 'sha': value,
    }, options: Options(headers: <String, String>{'Accept': 'application/vnd.github+json', 'Authorization': 'Bearer $token'}));
    _fileCache.remove('$owner/$repo@$branch:$path');
  }
}
