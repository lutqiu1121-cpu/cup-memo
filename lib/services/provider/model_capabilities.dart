import 'package:flutter/foundation.dart';

/// Runtime model capability resolution. Unknown models use only a conservative
/// default; provider metadata and explicit user overrides are authoritative.
enum CapabilitySource { manualOverride, providerMetadata, defaultFallback }

@immutable
class ModelCapabilities {
  const ModelCapabilities({
    required this.model,
    this.maxContextTokens = 8192,
    this.maxOutputTokens = 4096,
    this.supportsThinking = false,
    this.thinkingLevels = const <String>[],
    this.supportsThinkingBudget = false,
    this.providerFormat = 'openai',
    this.source = CapabilitySource.defaultFallback,
  });
  final String model;
  final int maxContextTokens;
  final int maxOutputTokens;
  final bool supportsThinking;
  final List<String> thinkingLevels;
  final bool supportsThinkingBudget;
  final String providerFormat;
  final CapabilitySource source;
  bool get supportsThinkingLevels => thinkingLevels.isNotEmpty;

  ModelCapabilities copyWith({
    int? maxContextTokens,
    int? maxOutputTokens,
    bool? supportsThinking,
    List<String>? thinkingLevels,
    bool? supportsThinkingBudget,
    String? providerFormat,
    CapabilitySource? source,
  }) {
    final int context = maxContextTokens ?? this.maxContextTokens;
    return ModelCapabilities(
      model: model,
      maxContextTokens: context,
      maxOutputTokens: (maxOutputTokens ?? this.maxOutputTokens)
          .clamp(1, context)
          .toInt(),
      supportsThinking: supportsThinking ?? this.supportsThinking,
      thinkingLevels: thinkingLevels ?? this.thinkingLevels,
      supportsThinkingBudget:
          supportsThinkingBudget ?? this.supportsThinkingBudget,
      providerFormat: providerFormat ?? this.providerFormat,
      source: source ?? this.source,
    );
  }
}

class ModelCapabilitiesRegistry {
  const ModelCapabilitiesRegistry._();

  static ModelCapabilities resolveModelCaps({
    required String model,
    Map<String, dynamic>? providerMetadata,
    Map<String, dynamic>? manualOverride,
  }) {
    ModelCapabilities resolved = ModelCapabilities(model: model);
    if (providerMetadata != null && providerMetadata.isNotEmpty) {
      resolved = _applyMetadata(
        resolved,
        providerMetadata,
        CapabilitySource.providerMetadata,
      );
    }
    if (manualOverride != null && manualOverride.isNotEmpty) {
      resolved = _applyMetadata(
        resolved,
        manualOverride,
        CapabilitySource.manualOverride,
      );
    }
    return resolved;
  }

  static ModelCapabilities forModel(
    String model, {
    Map<String, dynamic>? providerMetadata,
    Map<String, dynamic>? manualOverride,
  }) => resolveModelCaps(
    model: model,
    providerMetadata: providerMetadata,
    manualOverride: manualOverride,
  );
  static ModelCapabilities fromModelMetadata(
    String model,
    Map<String, dynamic> metadata,
  ) => resolveModelCaps(model: model, providerMetadata: metadata);

  static ModelCapabilities _applyMetadata(
    ModelCapabilities base,
    Map<String, dynamic> metadata,
    CapabilitySource source,
  ) {
    final dynamic context =
        metadata['context_override'] ??
        metadata['context_length'] ??
        metadata['max_context_tokens'] ??
        metadata['context_window'];
    final dynamic output =
        metadata['max_tokens'] ?? metadata['max_output_tokens'];
    final dynamic levels = metadata['thinking_levels'];
    return base.copyWith(
      maxContextTokens: context is num
          ? context.toInt().clamp(1, 10000000)
          : null,
      maxOutputTokens: output is num ? output.toInt() : null,
      supportsThinking: metadata['thinking_override'] is bool
          ? metadata['thinking_override'] as bool
          : (metadata['supports_thinking'] is bool
                ? metadata['supports_thinking'] as bool
                : null),
      thinkingLevels: levels is List
          ? levels
                .map((Object? value) => value.toString())
                .toList(growable: false)
          : null,
      supportsThinkingBudget: metadata['supports_thinking_budget'] is bool
          ? metadata['supports_thinking_budget'] as bool
          : null,
      providerFormat: metadata['provider_format']?.toString(),
      source: source,
    );
  }
}
