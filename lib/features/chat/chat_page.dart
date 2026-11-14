import 'dart:async';

import 'package:dart_agent_core/dart_agent_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/id.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/chat_message.dart';
import '../../models/entry.dart';
import '../../providers/app_providers.dart';
import '../../services/entry_service.dart';
import '../../services/provider/provider_config.dart';
import '../../services/provider/provider_router.dart';
import '../settings/provider_management_page.dart';

/// Tab 3 — real streaming chat with tool-assisted local memory.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<List<String>> _memoryPrompts() async {
    final EntryService? service = ref.read(entryServiceProvider);
    if (service == null) return const <String>[];
    final List<Entry> entries = await service.aiContextEntries();
    if (entries.isEmpty) return const <String>[];
    final List<String> blocks = <String>[];
    for (final Entry entry in entries) {
      final String body = await service.readBody(entry);
      blocks.add('[${entry.title}]: ${body.trim()}');
    }
    return <String>[
      '【以下是用户设定的项目背景，请优先参考，但不要擅自修改】\n${blocks.join('\n')}',
    ];
  }

  List<Tool> _tools() {
    return <Tool>[
      Tool(
        name: 'search_entries',
        description: 'Search local Cup Memo entries using the CJK-aware FTS5 index.',
        parameterMode: ToolParameterMode.object,
        parameters: <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'query': <String, dynamic>{'type': 'string'},
          },
          'required': <String>['query'],
        },
        executable: (Map<String, dynamic> args) async {
          final EntryService? service = ref.read(entryServiceProvider);
          if (service == null) return <String>['Database unavailable'];
          final String query = args['query']?.toString() ?? '';
          final List<Entry> entries = await service.search(query);
          return entries
              .take(10)
              .map((Entry entry) => <String, String>{
                    'id': entry.id,
                    'title': entry.title,
                    'category': entry.category,
                  })
              .toList(growable: false);
        },
      ),
      Tool(
        name: 'create_entry',
        description: 'Create a local Cup Memo entry when the user explicitly asks to remember something.',
        parameterMode: ToolParameterMode.object,
        parameters: <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'title': <String, dynamic>{'type': 'string'},
            'body': <String, dynamic>{'type': 'string'},
            'category': <String, dynamic>{'type': 'string'},
          },
          'required': <String>['title', 'body'],
        },
        executable: (Map<String, dynamic> args) async {
          final EntryService? service = ref.read(entryServiceProvider);
          if (service == null) return 'Database unavailable';
          final result = await service.create(
            title: args['title']?.toString() ?? 'Untitled',
            body: args['body']?.toString() ?? '',
            category: args['category']?.toString() ?? 'AI',
            tags: const <String>['AI'],
            isAiContext: false,
          );
          return 'Entry ${result.entryId} created (${result.outcome.name})';
        },
      ),
    ];
  }

  Future<void> _send() async {
    final String text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final ProviderRouter? router = await ref.read(providerRouterProvider.future);
    if (router == null) {
      if (!mounted) return;
      showPendingSnackBar(context, '请先配置 Provider 和 API Key');
      return;
    }

    _input.clear();
    final ChatMessage user = ChatMessage(
      id: newMessageId(),
      sessionId: 'current',
      role: ChatRole.user,
      content: text,
      createdAt: DateTime.now(),
      providerId: router.config.id,
      model: router.config.defaultModel,
    );
    final List<ChatMessage> request = <ChatMessage>[..._messages, user];
    final String assistantId = newMessageId();
    setState(() {
      _messages.add(user);
      _messages.add(
        ChatMessage(
          id: assistantId,
          sessionId: 'current',
          role: ChatRole.assistant,
          content: '',
          createdAt: DateTime.now(),
          providerId: router.config.id,
          model: router.config.defaultModel,
        ),
      );
      _sending = true;
    });
    _scrollToBottom();

    final StringBuffer buffer = StringBuffer();
    Timer? flushTimer;
    void flush() {
      flushTimer?.cancel();
      flushTimer = null;
      final int index = _messages.indexWhere((ChatMessage m) => m.id == assistantId);
      if (!mounted || index < 0) return;
      final ChatMessage old = _messages[index];
      setState(() {
        _messages[index] = ChatMessage(
          id: old.id,
          sessionId: old.sessionId,
          role: old.role,
          content: buffer.toString(),
          createdAt: old.createdAt,
          providerId: old.providerId,
          model: old.model,
        );
      });
      _scrollToBottom();
    }

    void scheduleFlush() {
      flushTimer ??= Timer(const Duration(milliseconds: 80), flush);
    }

    try {
      final List<String> memory = await _memoryPrompts();
      await for (final String chunk in router.streamMessage(
        request,
        tools: _tools(),
        systemPrompts: memory,
      )) {
        buffer.write(chunk);
        scheduleFlush();
      }
      flushTimer?.cancel();
      flush();
    } catch (error) {
      flushTimer?.cancel();
      final int index = _messages.indexWhere((ChatMessage m) => m.id == assistantId);
      if (mounted && index >= 0) {
        final old = _messages[index];
        setState(() {
          _messages[index] = ChatMessage(
            id: old.id,
            sessionId: old.sessionId,
            role: old.role,
            content: '请求失败：$error',
            createdAt: old.createdAt,
            providerId: old.providerId,
            model: old.model,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickProvider() async {
    final ProviderListState list = ref.read(providerListProvider);
    if (list.isEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ProviderManagementPage()),
      );
      return;
    }
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const ListTile(title: Text('切换 Provider（影响后续消息）')),
            for (final ProviderConfig item in list.items)
              ListTile(
                leading: const Icon(Icons.hub_outlined),
                title: Text(item.name),
                subtitle: Text(item.kind.label),
                trailing: item.isDefault ? const Icon(Icons.star, size: 18) : null,
                onTap: () => Navigator.of(sheetContext).pop(item.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    ref.read(currentProviderIdProvider.notifier).select(selected);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Provider 已切换，仅影响后续消息')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProviderConfig? active = ref.watch(activeProviderProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('会话'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: const Icon(Icons.hub_outlined, size: 16),
              label: Text(active?.name ?? '未配置 Provider'),
              onPressed: _pickProvider,
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _messages.isEmpty
                ? EmptyState(
                    icon: Icons.forum_outlined,
                    title: active == null ? '还没有可用的 Provider' : '会话尚未开始',
                    description: active == null
                        ? '先在设置中添加 Provider 与 API Key。'
                        : '输入消息开始流式对话。AI 可调用本地搜索和创建条目工具。',
                    actionLabel: active == null ? '去配置 Provider' : null,
                    onAction: active == null ? _pickProvider : null,
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: _messages.length,
                    itemBuilder: (BuildContext context, int index) => _Bubble(
                      message: _messages[index],
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: '记点什么…'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    tooltip: '发送',
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool user = message.role == ChatRole.user;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: user
              ? theme.colorScheme.primary.withValues(alpha: 0.22)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.content.isEmpty ? '…' : message.content),
      ),
    );
  }
}
