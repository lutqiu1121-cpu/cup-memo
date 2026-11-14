import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart' as da;
import 'package:http/http.dart' as http;
import 'package:openai_dart/openai_dart.dart' as openai;

import '../../models/chat_message.dart' as memo;
import 'provider_config.dart';

class AgentStreamChunk {
  const AgentStreamChunk({this.text = '', this.reasoning = ''});
  final String text;
  final String reasoning;
}

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

/// Converts unsafe HTML/WAF responses into a JSON 502 response. Dartantic's
/// SSE parser otherwise ignores a successful text/html response silently.
class WafGuardClient extends http.BaseClient {
  WafGuardClient(this._inner);
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final http.StreamedResponse response = await _inner.send(request);
    final String contentType = (response.headers['content-type'] ?? '')
        .toLowerCase();
    final bool badStatus =
        response.statusCode < 200 || response.statusCode >= 300;
    final bool allowed =
        contentType.contains('json') || contentType.contains('event-stream');
    if (badStatus || contentType.contains('text/html') || !allowed) {
      await response.stream.drain<void>();
      final String body = jsonEncode(<String, dynamic>{
        'error': <String, dynamic>{
          'message': '请求被防火墙拦截',
          'type': 'waf_blocked',
        },
      });
      return http.StreamedResponse(
        Stream<List<int>>.value(utf8.encode(body)),
        502,
        headers: const <String, String>{'content-type': 'application/json'},
        request: response.request,
        reasonPhrase: 'WAF Guard',
      );
    }
    return response;
  }

  @override
  void close() => _inner.close();
}

class GuardedOpenAIProvider extends da.OpenAIProvider {
  GuardedOpenAIProvider({
    required this._client,
    super.apiKey,
    super.baseUrl,
    super.apiKeyName,
    super.headers,
    super.name,
    super.displayName,
  });
  final http.Client _client;

  @override
  da.ChatModel<da.OpenAIChatOptions> createChatModel({
    String? name,
    List<da.Tool>? tools,
    double? temperature,
    bool enableThinking = false,
    da.OpenAIChatOptions? options,
  }) {
    if (enableThinking) {
      throw UnsupportedError('OpenAI Chat Completions 不支持 thinking');
    }
    validateApiKeyPresence();
    return da.OpenAIChatModel(
      name: name ?? defaultModelNames[da.ModelKind.chat]!,
      tools: tools,
      temperature: temperature,
      apiKey: apiKey,
      baseUrl: baseUrl ?? da.OpenAIProvider.defaultBaseUrl,
      headers: headers,
      client: _client,
    );
  }
}

abstract class ProviderClient {
  ProviderConfig get config;
  Future<ChatCompletion> sendMessage(
    List<memo.ChatMessage> messages, {
    String? model,
    List<da.Tool>? tools,
    List<String> systemPrompts = const <String>[],
  });
  Stream<AgentStreamChunk> streamMessage(
    List<memo.ChatMessage> messages, {
    String? model,
    List<da.Tool>? tools,
    List<String> systemPrompts = const <String>[],
  });
}

class AgentProviderClient implements ProviderClient {
  AgentProviderClient({required this.config, required this.apiKey});
  @override
  final ProviderConfig config;
  final String? apiKey;

  da.Agent _agent({String? model, List<da.Tool>? tools}) {
    final bool ollama = config.kind == ProviderKind.ollama;
    final da.OpenAIProvider provider = GuardedOpenAIProvider(
      client: WafGuardClient(http.Client()),
      apiKey: ollama ? null : apiKey,
      apiKeyName: ollama ? null : 'OPENAI_API_KEY',
      baseUrl: Uri.parse(config.baseUrl),
      headers: config.extraHeaders,
      name: 'cup_memo_${config.id}',
    );
    return da.Agent.forProvider(provider, chatModelName: model, tools: tools);
  }

  List<da.ChatMessage> _history(
    List<memo.ChatMessage> messages,
    List<String> prompts,
  ) {
    final List<da.ChatMessage> result = <da.ChatMessage>[
      ...prompts.map(da.ChatMessage.system),
    ];
    for (final memo.ChatMessage message in messages.take(messages.length - 1)) {
      if (message.role == memo.ChatRole.user) {
        result.add(da.ChatMessage.user(message.content));
      }
      if (message.role == memo.ChatRole.assistant) {
        result.add(da.ChatMessage.model(message.content));
      }
    }
    return result;
  }

  String _prompt(List<memo.ChatMessage> messages) =>
      messages.isEmpty ? '' : messages.last.content;

  @override
  Future<ChatCompletion> sendMessage(
    List<memo.ChatMessage> messages, {
    String? model,
    List<da.Tool>? tools,
    List<String> systemPrompts = const <String>[],
  }) async {
    final da.ChatResult<String> result = await _agent(
      model: model,
      tools: tools,
    ).send(_prompt(messages), history: _history(messages, systemPrompts));
    return ChatCompletion(
      content: result.output,
      model: model ?? config.defaultModel,
    );
  }

  @override
  Stream<AgentStreamChunk> streamMessage(
    List<memo.ChatMessage> messages, {
    String? model,
    List<da.Tool>? tools,
    List<String> systemPrompts = const <String>[],
  }) async* {
    final da.Agent agent = _agent(model: model, tools: tools);
    int toolRounds = 0;
    try {
      await for (final da.ChatResult<String> chunk in agent.sendStream(
        _prompt(messages),
        history: _history(messages, systemPrompts),
      )) {
        toolRounds += chunk.messages
            .expand((da.ChatMessage message) => message.parts.toolResults)
            .length;
        if (toolRounds > 8) {
          throw StateError('Agent tool loop exceeded 8 rounds');
        }
        final String text = chunk.output;
        final String thinking = chunk.thinking ?? '';
        if (text.contains('<!DOCTYPE html>') ||
            text.contains('<script') ||
            text.toLowerCase().contains('waf-ce.chaitin.cn')) {
          throw StateError('请求被防火墙拦截');
        }
        if (text.isNotEmpty || thinking.isNotEmpty) {
          yield AgentStreamChunk(text: text, reasoning: thinking);
        }
      }
    } on openai.ApiException {
      throw StateError('网络请求失败，请稍后重试');
    } on openai.OpenAIException {
      throw StateError('网络连接失败，请检查 Provider 配置');
    } on da.OpenAIRefusalException {
      throw StateError('模型拒绝了请求');
    }
  }
}

class ProviderRouter {
  const ProviderRouter(this.config, {this.apiKey});
  final ProviderConfig config;
  final String? apiKey;

  ProviderClient createClient() {
    if ((apiKey == null || apiKey!.isEmpty) &&
        config.kind != ProviderKind.ollama) {
      throw StateError('Provider ${config.name} 没有可用的 API Key');
    }
    return AgentProviderClient(config: config, apiKey: apiKey);
  }

  Future<ChatCompletion> sendMessage(
    List<memo.ChatMessage> messages, {
    String? model,
    List<da.Tool>? tools,
    List<String> systemPrompts = const <String>[],
  }) => createClient().sendMessage(
    messages,
    model: model ?? config.defaultModel,
    tools: tools,
    systemPrompts: systemPrompts,
  );
  Stream<AgentStreamChunk> streamMessage(
    List<memo.ChatMessage> messages, {
    String? model,
    List<da.Tool>? tools,
    List<String> systemPrompts = const <String>[],
  }) => createClient().streamMessage(
    messages,
    model: model ?? config.defaultModel,
    tools: tools,
    systemPrompts: systemPrompts,
  );
}
