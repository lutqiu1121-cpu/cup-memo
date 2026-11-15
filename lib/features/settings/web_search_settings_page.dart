import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/search/web_search_service.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../providers/app_providers.dart';

class WebSearchSettingsPage extends ConsumerStatefulWidget {
  const WebSearchSettingsPage({super.key});
  @override
  ConsumerState<WebSearchSettingsPage> createState() =>
      _WebSearchSettingsPageState();
}

class _WebSearchSettingsPageState extends ConsumerState<WebSearchSettingsPage> {
  late WebSearchProvider _provider;
  late final TextEditingController _url;
  late final TextEditingController _key;
  @override
  void initState() {
    super.initState();
    _provider = WebSearchProvider.searxng;
    _url = TextEditingController();
    _key = TextEditingController();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    final WebSearchConfig config = await WebSearchConfig.load(
      ref.read(sharedPreferencesProvider),
    );
    if (!mounted) return;
    setState(() {
      _provider = config.provider;
      _url.text = config.baseUrl;
      _key.text = config.apiKey;
    });
  }

  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(WebSearchConfig.providerKey, _provider.name);
    await prefs.setString(WebSearchConfig.urlKey, _url.text.trim());
    final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    await secureStorage.write(
      key: WebSearchConfig.secureKeyRef,
      value: _key.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('联网搜索设置已保存')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('联网搜索配置')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        DropdownButtonFormField<WebSearchProvider>(
          initialValue: _provider,
          decoration: const InputDecoration(labelText: '搜索服务'),
          items: WebSearchProvider.values
              .map(
                (WebSearchProvider value) => DropdownMenuItem(
                  value: value,
                  child: Text(value.name.toUpperCase()),
                ),
              )
              .toList(),
          onChanged: (WebSearchProvider? value) {
            if (value != null) setState(() => _provider = value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _url,
          decoration: const InputDecoration(
            labelText: '接口地址 (Base URL)',
            hintText: 'SearXNG 实例地址；留空使用默认地址',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _key,
          obscureText: true,
          decoration: const InputDecoration(labelText: '访问密钥 (API Key)'),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: _save, child: const Text('保存搜索设置')),
      ],
    ),
  );
}
