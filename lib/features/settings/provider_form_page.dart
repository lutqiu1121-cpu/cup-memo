import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/id.dart';
import '../../providers/app_providers.dart';
import '../../services/provider/provider_config.dart';
import '../../services/provider/provider_presets.dart';
import '../../services/provider/model_capabilities.dart';

/// Add / edit form for a [ProviderConfig].
///
/// The API key is written straight into `flutter_secure_storage`; the database
/// only receives the generated [ProviderConfig.apiKeyRef].
class ProviderFormPage extends ConsumerStatefulWidget {
  const ProviderFormPage({super.key, this.existing});

  /// `null` when adding a new provider.
  final ProviderConfig? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<ProviderFormPage> createState() => _ProviderFormPageState();
}

class _ProviderFormPageState extends ConsumerState<ProviderFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _baseUrl = TextEditingController();
  final TextEditingController _apiKey = TextEditingController();
  final TextEditingController _model = TextEditingController();
  final TextEditingController _headers = TextEditingController();

  ProviderPreset _preset = ProviderPresets.custom;
  ProviderKind _kind = ProviderKind.openaiCompatible;
  bool _isDefault = false;
  bool _saving = false;
  bool _loadingModels = false;
  List<String> _models = const <String>[];
  ModelCapabilities _capabilities = const ModelCapabilities(model: '');
  double _temperature = 0.7;
  int _maxTokens = 4096;
  bool _thinking = false;
  String _thinkingLevel = 'medium';
  double _thinkingBudget = 4096;

  @override
  void initState() {
    super.initState();
    final ProviderConfig? existing = widget.existing;
    if (existing != null) {
      _name.text = existing.name;
      _baseUrl.text = existing.baseUrl;
      _model.text = existing.defaultModel;
      _headers.text = ProviderConfig.headersToText(existing.extraHeaders);
      _kind = existing.kind;
      _isDefault = existing.isDefault;
      _temperature = (existing.modelParameters['temperature'] as num?)?.toDouble() ?? 0.7;
      _maxTokens = (existing.modelParameters['max_tokens'] as num?)?.toInt() ?? 4096;
      _thinking = existing.modelParameters['thinking_enabled'] == true;
      _thinkingLevel = existing.modelParameters['thinking_level']?.toString() ?? 'medium';
      _thinkingBudget = (existing.modelParameters['thinking_budget'] as num?)?.toDouble() ?? 4096;
      _preset = ProviderPresets.all.firstWhere(
        (ProviderPreset preset) => preset.kind == existing.kind &&
            preset.baseUrl == existing.baseUrl,
        orElse: () => ProviderPresets.custom,
      );
      _capabilities = ModelCapabilitiesRegistry.forModel(existing.defaultModel);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    _headers.dispose();
    super.dispose();
  }

  void _applyPreset(ProviderPreset? preset) {
    if (preset == null) {
      return;
    }
    setState(() {
      _preset = preset;
      _kind = preset.kind;
      if (preset.baseUrl.isNotEmpty) {
        _baseUrl.text = preset.baseUrl;
      }
      if (preset.defaultModel.isNotEmpty) {
        _model.text = preset.defaultModel;
      }
      if (_name.text.trim().isEmpty) {
        _name.text = preset.label;
      }
      if (preset.extraHeaders.isNotEmpty) {
        _headers.text = ProviderConfig.headersToText(preset.extraHeaders);
      }
    });
  }

  Future<void> _fetchModels() async {
    final String base = _baseUrl.text.trim().replaceFirst(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先填写 baseUrl')));
      return;
    }
    final String key = _apiKey.text.trim();
    if (key.isEmpty && _kind != ProviderKind.ollama) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先填写 API Key')));
      return;
    }

    setState(() => _loadingModels = true);
    try {
      final Map<String, String> headers = <String, String>{
        ...ProviderConfig.parseHeadersText(_headers.text),
      };
      String modelsUrl;
      if (_kind == ProviderKind.anthropic) {
        modelsUrl = base.endsWith('/v1') ? '$base/models' : '$base/v1/models';
        headers['x-api-key'] = key;
        headers['anthropic-version'] ??= '2023-06-01';
        headers.remove('Authorization');
      } else {
        modelsUrl = '$base/models';
        if (key.isNotEmpty) headers['Authorization'] = 'Bearer $key';
      }

      final response = await Dio().get<dynamic>(
        modelsUrl,
        options: Options(
          headers: headers.isEmpty ? null : headers,
          validateStatus: (int? status) => status != null && status >= 200 && status < 300,
        ),
      );
      final dynamic raw = response.data is Map ? (response.data as Map)['data'] : response.data;
      final List<String> models = raw is List
          ? raw.map((Object? value) {
              if (value is Map) return (value['id'] ?? value['name'])?.toString();
              return value?.toString();
            }).whereType<String>().where((String value) => value.isNotEmpty).toList()
          : const <String>[];
      if (!mounted) return;
      setState(() {
        _models = models;
        _loadingModels = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(models.isEmpty ? '接口未返回可用模型' : '已获取 ${models.length} 个模型')),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _loadingModels = false);
      final int? status = error.response?.statusCode;
      final String detail = error.response?.data?.toString() ?? error.message ?? error.type.name;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取模型失败${status == null ? '' : ' [$status]'}：$detail')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingModels = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('获取模型失败：$error')));
    }
  }

  void _refreshCapabilities(String model) {
    setState(() => _capabilities = ModelCapabilitiesRegistry.forModel(model));
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '请填写$label';
    }
    return null;
  }

  String? _validateBaseUrl(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) {
      return '请填写 baseUrl';
    }
    final Uri? uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme) {
      return 'baseUrl 需要包含协议，例如 https://api.example.com/v1';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);

    final ProviderConfig? existing = widget.existing;
    final ProviderConfig config = ProviderConfig(
      id: existing?.id ?? newProviderId(),
      name: _name.text.trim(),
      kind: _kind,
      baseUrl: _baseUrl.text.trim(),
      apiKeyRef: existing?.apiKeyRef ?? newProviderId(),
      defaultModel: _model.text.trim(),
      modelParameters: <String, dynamic>{
        'temperature': _temperature,
        'max_tokens': _maxTokens,
        'context_tokens': _capabilities.maxContextTokens,
        'thinking_enabled': _thinking,
        if (_thinking) 'thinking_level': _thinkingLevel,
        if (_thinking) 'thinking_budget': _thinkingBudget.toInt(),
      },
      extraHeaders: ProviderConfig.parseHeadersText(_headers.text),
      isDefault: _isDefault,
    );

    final bool ok = await ref.read(providerListProvider.notifier).save(
          config,
          apiKey: _apiKey.text.trim().isEmpty ? null : _apiKey.text.trim(),
        );

    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('保存失败，请检查数据库是否可用')),
        );
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? '已更新 ${config.name}' : '已添加 ${config.name}'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool ollama = _kind == ProviderKind.ollama;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '编辑 Provider' : '添加 Provider'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: <Widget>[
            DropdownButtonFormField<ProviderPreset>(
              initialValue: _preset,
              decoration: const InputDecoration(
                labelText: '预设',
                prefixIcon: Icon(Icons.auto_awesome_outlined),
              ),
              items: <DropdownMenuItem<ProviderPreset>>[
                for (final ProviderPreset preset in ProviderPresets.all)
                  DropdownMenuItem<ProviderPreset>(
                    value: preset,
                    child: Text(preset.label),
                  ),
              ],
              onChanged: _applyPreset,
            ),
            if (_preset.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Text(
                  _preset.note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: '名称'),
              validator: (String? value) => _validateRequired(value, '名称'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<ProviderKind>(
              initialValue: _kind,
              decoration: const InputDecoration(
                labelText: '类型（kind）',
                prefixIcon: Icon(Icons.tune),
              ),
              items: <DropdownMenuItem<ProviderKind>>[
                for (final ProviderKind kind in ProviderKind.values)
                  DropdownMenuItem<ProviderKind>(
                    value: kind,
                    child: Text('${kind.label}（${kind.wireName}）'),
                  ),
              ],
              onChanged: (ProviderKind? value) {
                if (value != null) {
                  setState(() => _kind = value);
                }
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _baseUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'baseUrl',
                hintText: 'https://api.example.com/v1',
              ),
              validator: _validateBaseUrl,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _apiKey,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: widget.isEditing ? '留空表示不修改' : 'sk-…',
                helperText: ollama
                    ? 'Ollama 本地部署通常不需要 API Key'
                    : '仅保存在 flutter_secure_storage，数据库只记录 apiKeyRef',
                prefixIcon: const Icon(Icons.key_outlined),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _model,
                    onChanged: _refreshCapabilities,
                    decoration: const InputDecoration(labelText: '默认模型', hintText: 'deepseek-chat', prefixIcon: Icon(Icons.memory_outlined)),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: OutlinedButton.icon(
                    onPressed: _loadingModels ? null : _fetchModels,
                    icon: _loadingModels ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download_outlined),
                    label: const Text('获取模型'),
                  ),
                ),
              ],
            ),
            if (_models.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _models.contains(_model.text) ? _model.text : null,
                decoration: const InputDecoration(labelText: '模型列表选择'),
                items: _models.map((String model) => DropdownMenuItem<String>(value: model, child: Text(model))).toList(),
                onChanged: (String? value) { if (value != null) { _model.text = value; _refreshCapabilities(value); } },
              ),
            ],
            const SizedBox(height: 14),
            Text('Temperature：${_temperature.toStringAsFixed(1)}'),
            Slider(value: _temperature, min: 0, max: 2, divisions: 20, onChanged: (double value) => setState(() => _temperature = value)),
            TextField(controller: TextEditingController(text: _maxTokens.toString()), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Tokens'), onSubmitted: (String value) { final parsed = int.tryParse(value); if (parsed != null) setState(() => _maxTokens = parsed.clamp(1, _capabilities.maxContextTokens)); }),
            Text('最大上下文：${_capabilities.maxContextTokens} tokens'),
            Slider(value: _capabilities.maxContextTokens.toDouble().clamp(1024, 1000000), min: 1024, max: 1000000, divisions: 100, onChanged: (double value) => setState(() => _capabilities = _capabilities.copyWith(maxContextTokens: value.toInt()))),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('开启深度思考'), subtitle: Text(_capabilities.supportsThinking ? '当前模型支持' : '当前模型不支持'), value: _thinking, onChanged: _capabilities.supportsThinking ? (bool value) => setState(() => _thinking = value) : null),
            if (_thinking && _capabilities.supportsThinkingLevels)
              DropdownButtonFormField<String>(initialValue: _capabilities.thinkingLevels.contains(_thinkingLevel) ? _thinkingLevel : _capabilities.thinkingLevels.first, decoration: const InputDecoration(labelText: '思考等级'), items: _capabilities.thinkingLevels.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(), onChanged: (String? value) { if (value != null) setState(() => _thinkingLevel = value); }),
            if (_thinking && _capabilities.supportsThinkingBudget) ...<Widget>[
              Text('思考预算：${_thinkingBudget.toInt()} tokens'),
              Slider(value: _thinkingBudget.clamp(256, _capabilities.maxContextTokens.toDouble()), min: 256, max: _capabilities.maxContextTokens.toDouble(), divisions: 20, onChanged: (double value) => setState(() => _thinkingBudget = value)),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _headers,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '自定义 headers（可选）',
                hintText: 'HTTP-Referer: https://example.com\nX-Title: Cup Memo',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('设为默认 Provider'),
              subtitle: const Text('新会话默认使用该 Provider'),
              value: _isDefault,
              onChanged: (bool value) => setState(() => _isDefault = value),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEditing ? '保存修改' : '添加 Provider'),
            ),
            const SizedBox(height: 10),
            Text(
              'API Key 保存在系统安全沙盒中，本地数据库仅记录引用。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
