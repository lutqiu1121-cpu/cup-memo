import 'package:dart_agent_core/dart_agent_core.dart';

import '../../models/chat_message.dart';
import 'provider_config.dart';

/// Result of one completed assistant response.
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

/// A provider client with both one-shot and streaming APIs.
abstract class ProviderClient {
  ProviderConfig get config;

  Future<ChatCompletion> sendMessage(
    List<ChatMessage> messages, {
    String? model,
    List<Tool>? tools,
    List<String> systemPrompts = const <String>[],
  });

  Stream<String> streamMessage(
    List<ChatMessage> messages, {
    String? model,
    List<Tool>? tools,
    List<String> systemPrompts = const <String>[],
  });
}

/// Real OpenAI-compatible client backed by dart_agent_core's OpenAIClient.
class AgentProviderClient implements ProviderClient {
  AgentProviderClient({
    required this.config,
    required this._apiKey,
  });

  @override
  final ProviderConfig config;
  final String _apiKey;

  OpenAIClient _client() {
    return OpenAIClient(
      apiKey: _apiKey,
      baseUrl: config.baseUrl,
    );
  }

  ModelConfig _model(String? model) {
    return ModelConfig(model: model ?? config.defaultModel);
  }

  List<LLMMessage> _messages(List<ChatMessage> messages) {
    return messages
        .map((ChatMessage message) {
          switch (message.role) {
            case ChatRole.user:
              return UserMessage.text(message.content);
            case ChatRole.system:
              return SystemMessage(message.content);
            case ChatRole.assistant:
              return ModelMessage(
                model: config.defaultModel,
                textOutput: message.content,
              );
          }
        })
        .toList(growable: false);
  }

  @override
  Future<ChatCompletion> sendMessage(
    List<ChatMessage> messages, {
    String? model,
    List<Tool>? tools,
    List<String> systemPrompts = const <String>[],
  }) async {
    final StatefulAgent agent = StatefulAgent(
      name: 'cup_memo_${config.id}',
      client: _client(),
      tools: tools,
      modelConfig: _model(model),
      systemPrompts: systemPrompts,
      state: AgentState.empty(),
    );
    final List<LLMMessage> responses = await agent.run(_messages(messages));
    final List<ModelMessage> modelResponses =
        responses.whereType<ModelMessage>().toList(growable: false);
    final ModelMessage? answer =
        modelResponses.isEmpty ? null : modelResponses.last;
    return ChatCompletion(
      content: answer?.textOutput ?? '',
      model: model ?? config.defaultModel,
      promptTokens: answer?.usage?.promptTokens ?? 0,
      completionTokens: answer?.usage?.completionTokens ?? 0,
    );
  }

  @override
  Stream<String> streamMessage(
    List<ChatMessage> messages, {
    String? model,
    List<Tool>? tools,
    List<String> systemPrompts = const <String>[],
  }) async* {
    final StatefulAgent agent = StatefulAgent(
      name: 'cup_memo_${config.id}',
      client: _client(),
      tools: tools,
      modelConfig: _model(model),
      systemPrompts: systemPrompts,
      state: AgentState.empty(),
    );
    final Stream<StreamingEvent> stream = agent.runStream(_messages(messages));
    await for (final StreamingEvent event in stream) {
      if (event.eventType == StreamingEventType.modelChunkMessage) {
        final ModelMessage chunk = event.data as ModelMessage;
        final String? text = chunk.textOutput;
        if (text != null && text.isNotEmpty) yield text;
      }
    }
  }
}

/// Keeps the old public name while now returning a real client.
class ProviderRouter {
  const ProviderRouter(this.config, {this.apiKey});

  final ProviderConfig config;
  final String? apiKey;

  ProviderClient createClient() {
    final String? key = apiKey;
    if ((key == null || key.isEmpty) && config.kind != ProviderKind.ollama) {
      throw StateError('Provider ${config.name} 没有可用的 API Key');
    }
    return AgentProviderClient(
      config: config,
      apiKey: key == null || key.isEmpty ? 'ollama' : key,
    );
  }

  Future<ChatCompletion> sendMessage(
    List<ChatMessage> messages, {
    String? model,
    List<Tool>? tools,
    List<String> systemPrompts = const <String>[],
  }) {
    return createClient().sendMessage(
      messages,
      model: model ?? config.defaultModel,
      tools: tools,
      systemPrompts: systemPrompts,
    );
  }

  Stream<String> streamMessage(
    List<ChatMessage> messages, {
    String? model,
    List<Tool>? tools,
    List<String> systemPrompts = const <String>[],
  }) {
    return createClient().streamMessage(
      messages,
      model: model ?? config.defaultModel,
      tools: tools,
      systemPrompts: systemPrompts,
    );
  }
}
