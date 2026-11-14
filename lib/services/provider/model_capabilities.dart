import 'package:flutter/material.dart';

/// Model capabilities are inferred from the model metadata / model id. Unknown
/// models stay conservative: unsupported parameters are never sent.
@immutable
class ModelCapabilities {
  const ModelCapabilities({
    required this.model,
    this.maxContextTokens = 8192,
    this.supportsThinking = false,
    this.thinkingLevels = const <String>[],
    this.supportsThinkingBudget = false,
    this.providerFormat = 'openai',
  });

  final String model;
  final int maxContextTokens;
  final bool supportsThinking;
  final List<String> thinkingLevels;
  final bool supportsThinkingBudget;
  final String providerFormat;

  bool get supportsThinkingLevels => thinkingLevels.isNotEmpty;

  ModelCapabilities copyWith({
    int? maxContextTokens,
    bool? supportsThinking,
    List<String>? thinkingLevels,
    bool? supportsThinkingBudget,
    String? providerFormat,
  }) {
    return ModelCapabilities(
      model: model,
      maxContextTokens: maxContextTokens ?? this.maxContextTokens,
      supportsThinking: supportsThinking ?? this.supportsThinking,
      thinkingLevels: thinkingLevels ?? this.thinkingLevels,
      supportsThinkingBudget:
          supportsThinkingBudget ?? this.supportsThinkingBudget,
      providerFormat: providerFormat ?? this.providerFormat,
    );
  }
}

class ModelCapabilitiesRegistry {
  const ModelCapabilitiesRegistry._();

  static ModelCapabilities forModel(String model) {
    final String id = model.toLowerCase();
    if (id.contains('deepseek-reasoner') || id.contains('deepseek-r1')) {
      return ModelCapabilities(
        model: model,
        maxContextTokens: 65536,
        supportsThinking: true,
        thinkingLevels: const <String>['low', 'medium', 'high'],
      );
    }
    if (id.contains('o1') || id.contains('o3') || id.contains('reasoning')) {
      return ModelCapabilities(
        model: model,
        maxContextTokens: 128000,
        supportsThinking: true,
        thinkingLevels: const <String>['low', 'medium', 'high'],
      );
    }
    if (id.contains('claude-3-7') || id.contains('claude-sonnet-4')) {
      return ModelCapabilities(
        model: model,
        maxContextTokens: 200000,
        supportsThinking: true,
        supportsThinkingBudget: true,
        providerFormat: 'anthropic',
      );
    }
    if (id.contains('gemini-1.5') || id.contains('gemini-2')) {
      return ModelCapabilities(
        model: model,
        maxContextTokens: 1000000,
        supportsThinking: true,
        supportsThinkingBudget: true,
        providerFormat: 'gemini',
      );
    }
    if (id.contains('qwen3')) {
      return ModelCapabilities(
        model: model,
        maxContextTokens: 32768,
        supportsThinking: true,
        supportsThinkingBudget: true,
      );
    }
    return ModelCapabilities(model: model);
  }

  static ModelCapabilities fromModelMetadata(
    String model,
    Map<String, dynamic> metadata,
  ) {
    final ModelCapabilities base = forModel(model);
    final dynamic context = metadata['context_length'] ??
        metadata['max_context_tokens'] ??
        metadata['context_window'];
    final dynamic levels = metadata['thinking_levels'];
    return base.copyWith(
      maxContextTokens: context is num ? context.toInt() : null,
      supportsThinking: metadata['supports_thinking'] is bool
          ? metadata['supports_thinking'] as bool
          : null,
      thinkingLevels: levels is List
          ? levels.map((Object? value) => value.toString()).toList()
          : null,
      supportsThinkingBudget: metadata['supports_thinking_budget'] is bool
          ? metadata['supports_thinking_budget'] as bool
          : null,
      providerFormat: metadata['provider_format']?.toString(),
    );
  }
}
