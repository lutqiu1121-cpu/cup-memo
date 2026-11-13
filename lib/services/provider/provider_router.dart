import '../../models/chat_message.dart';
import 'provider_config.dart';

/// Result of one completion round-trip.
class ChatCompletion {
  const ChatCompletion({
    required this.content,
    this.model = '',
    this.promptTokens = 0,
    this.completionTokens = 0,
  });

  final String content;
  final String model;
  final int promptTokens;
  final int completionTokens;
}

/// Minimal chat client contract shared by every provider kind.
///
/// The concrete clients (`openai_compatible`, `deepseek_native`, `anthropic`,
/// `gemini`, `ollama`) are implemented in a later stage; this stage only ships
/// [StubProviderClient] so that the UI and the router can be wired end to end.
abstract class ProviderClient {
  ProviderConfig get config;

  /// Sends [messages] and returns the assistant reply.
  ///
  /// Throws [UnimplementedError] in this stage.
  Future<ChatCompletion> sendMessage(
    List<ChatMessage> messages, {
    String? model,
  });
}

/// Placeholder client — every call fails loudly instead of pretending to work.
class StubProviderClient implements ProviderClient {
  const StubProviderClient(this.config);

  @override
  final ProviderConfig config;

  @override
  Future<ChatCompletion> sendMessage(
    List<ChatMessage> messages, {
    String? model,
  }) {
    throw UnimplementedError(
      'ProviderRouter: 尚未实现 ${config.kind.label} 客户端的真实 API 调用 '
      '(${config.name} → ${config.baseUrl})。本阶段仅提供路由骨架。',
    );
  }
}

/// Routes a chat request to the client that matches [config].
///
/// The router is the only place that knows the mapping
/// `ProviderKind -> client implementation`, so switching providers during a
/// session never leaks into the message history.
class ProviderRouter {
  const ProviderRouter(this.config);

  final ProviderConfig config;

  /// Returns the client for [config]'s [ProviderConfig.kind].
  ProviderClient createClient() {
    // All five kinds map to the same stub for now; the switch documents the
    // contract the real implementations will follow.
    switch (config.kind) {
      case ProviderKind.openaiCompatible:
      case ProviderKind.deepseekNative:
      case ProviderKind.anthropic:
      case ProviderKind.gemini:
      case ProviderKind.ollama:
        return StubProviderClient(config);
    }
  }

  /// Convenience wrapper around [createClient] + `sendMessage`.
  Future<ChatCompletion> sendMessage(
    List<ChatMessage> messages, {
    String? model,
  }) {
    return createClient().sendMessage(
      messages,
      model: model ?? config.defaultModel,
    );
  }
}
