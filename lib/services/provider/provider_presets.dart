import 'provider_config.dart';

/// A built-in provider preset shown in the "Provider 管理 → 添加" form.
class ProviderPreset {
  const ProviderPreset({
    required this.id,
    required this.label,
    required this.kind,
    required this.baseUrl,
    required this.defaultModel,
    this.extraHeaders = const <String, String>{},
    this.note = '',
  });

  final String id;
  final String label;
  final ProviderKind kind;
  final String baseUrl;
  final String defaultModel;
  final Map<String, String> extraHeaders;
  final String note;
}

/// Built-in presets. Users may still edit every field after picking one.
class ProviderPresets {
  const ProviderPresets._();

  static const ProviderPreset deepSeek = ProviderPreset(
    id: 'deepseek_official',
    label: 'DeepSeek 官方',
    kind: ProviderKind.deepseekNative,
    baseUrl: 'https://api.deepseek.com',
    defaultModel: 'deepseek-chat',
    note: 'DeepSeek 原生接口，模型：deepseek-chat / deepseek-reasoner',
  );

  static const ProviderPreset openRouter = ProviderPreset(
    id: 'openrouter',
    label: 'OpenRouter',
    kind: ProviderKind.openaiCompatible,
    baseUrl: 'https://openrouter.ai/api/v1',
    defaultModel: 'deepseek/deepseek-chat',
    note: '聚合网关，建议填写 HTTP-Referer / X-Title 自定义 headers',
  );

  static const ProviderPreset siliconFlow = ProviderPreset(
    id: 'siliconflow',
    label: 'SiliconFlow 硅基流动',
    kind: ProviderKind.openaiCompatible,
    baseUrl: 'https://api.siliconflow.cn/v1',
    defaultModel: 'deepseek-ai/DeepSeek-V3',
    note: '国内 OpenAI 兼容网关',
  );

  static const ProviderPreset anthropic = ProviderPreset(
    id: 'anthropic_official',
    label: 'Anthropic Messages',
    kind: ProviderKind.anthropic,
    baseUrl: 'https://api.anthropic.com',
    defaultModel: 'claude-3-7-sonnet-latest',
    note: 'Anthropic Messages API，模型列表使用 /v1/models、x-api-key 与 anthropic-version',
  );

  static const ProviderPreset ollama = ProviderPreset(
    id: 'ollama_local',
    label: 'Ollama 本地',
    kind: ProviderKind.ollama,
    baseUrl: 'http://127.0.0.1:11434/v1',
    defaultModel: 'qwen2.5:7b',
    note: '本机推理，无需 API Key',
  );

  static const ProviderPreset custom = ProviderPreset(
    id: 'custom_openai_compatible',
    label: '自定义 OpenAI 兼容',
    kind: ProviderKind.openaiCompatible,
    baseUrl: '',
    defaultModel: '',
    note: '自填 baseUrl 与模型名',
  );

  /// All presets, in display order.
  static const List<ProviderPreset> all = <ProviderPreset>[
    deepSeek,
    openRouter,
    siliconFlow,
    anthropic,
    ollama,
    custom,
  ];

  static ProviderPreset byId(String id) {
    return all.firstWhere(
      (ProviderPreset preset) => preset.id == id,
      orElse: () => custom,
    );
  }
}
