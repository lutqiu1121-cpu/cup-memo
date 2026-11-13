import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/id.dart';
import '../../providers/app_providers.dart';
import '../../services/provider/provider_config.dart';
import '../../services/provider/provider_presets.dart';

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
      _preset = ProviderPresets.all.firstWhere(
        (ProviderPreset preset) => preset.kind == existing.kind,
        orElse: () => ProviderPresets.custom,
      );
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
            TextFormField(
              controller: _model,
              decoration: const InputDecoration(
                labelText: '默认模型',
                hintText: 'deepseek-chat',
                prefixIcon: Icon(Icons.memory_outlined),
              ),
            ),
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
              '本阶段不发起任何真实 API 请求；保存后只写入本地配置。',
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
