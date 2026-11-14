import 'dart:async';

import 'package:dart_agent_core/dart_agent_core.dart';
import 'package:flutter/material.dart';

import '../../app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/id.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/chat_message.dart';
import '../../models/entry.dart';
import '../../providers/app_providers.dart';
import '../../services/entry_service.dart';
import '../../services/provider/provider_config.dart';
import '../../services/provider/model_capabilities.dart';
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
  final Map<String, String> _reasoning = <String, String>{};
  String? _sessionId;
  bool _sending = false;
  bool _webSearch = false;
  bool _toolsEnabled = true;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_ensureSession);
  }

  void _ensureSession() {
    if (_sessionId != null) return;
    final db = ref.read(databaseProvider);
    final empty = db?.sessionDao.findEmpty();
    setState(() => _sessionId = empty?.id ?? db?.sessionDao.create() ?? newSessionId());
  }

  Future<void> _newSession() async {
    final db = ref.read(databaseProvider);
    if (db != null && _sessionId != null) db.sessionDao.end(_sessionId!);
    setState(() {
      _sessionId = db?.sessionDao.create() ?? newSessionId();
      _messages.clear();
      _reasoning.clear();
    });
  }

  Future<void> _showHistory() async {
    final db = ref.read(databaseProvider);
    if (db == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据库不可用，无法读取历史会话')));
      return;
    }
    var records = db.sessionDao.list();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .65,
            child: records.isEmpty
                ? const Center(child: Text('暂无历史会话'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final record = records[index];
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: Text('会话 ${record.id.substring(0, 8)}'),
                        subtitle: Text(_formatSessionDate(record.startedAt)),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { db.sessionDao.delete(record.id); records = db.sessionDao.list(); setSheetState(() {}); }),
                        onTap: () { setState(() { _sessionId = record.id; _messages.clear(); _reasoning.clear(); }); Navigator.of(sheetContext).pop(); },
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<List<String>> _memoryPrompts(String query) async {
    final EntryService? service = ref.read(entryServiceProvider);
    if (service == null) return const <String>[];
    final List<Entry> entries = await service.aiContextEntries();
    if (entries.isEmpty) return const <String>[];
    final List<String> blocks = <String>[];
    for (final Entry entry in entries) {
      final String body = await service.readBody(entry);
      blocks.add('[${entry.title}]: ${body.trim()}');
    }
    final List<String> prompts = <String>[
      '【以下是用户设定的项目背景，请优先参考，但不要擅自修改】\n${blocks.join('\n')}',
    ];
    if (_webSearch) {
      final List<Entry> hits = await service.search(query);
      final List<String> searchBlocks = <String>[];
      for (final Entry hit in hits.take(5)) {
        searchBlocks.add('[本地搜索 ${hit.title}]：${(await service.readBody(hit)).trim()}');
      }
      prompts.add('【联网搜索开关已开启】当前无外部搜索 API，优先使用以下本地搜索上下文：\n${searchBlocks.join('\n')}');
    }
    return prompts;
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
      Tool(
        name: 'add_task',
        description: 'Add a current task for the user.',
        parameterMode: ToolParameterMode.object,
        parameters: <String, dynamic>{'type': 'object', 'properties': <String, dynamic>{'title': <String, dynamic>{'type': 'string'}, 'detail': <String, dynamic>{'type': 'string'}}, 'required': <String>['title']},
        executable: (Map<String, dynamic> args) {
          final dao = ref.read(databaseProvider)?.taskDao;
          if (dao == null) return 'Database unavailable';
          return dao.addCurrentTask(title: args['title']?.toString() ?? 'Untitled', detail: args['detail']?.toString() ?? '');
        },
      ),
      Tool(
        name: 'complete_task',
        description: 'Complete a current task by id.',
        parameterMode: ToolParameterMode.object,
        parameters: <String, dynamic>{'type': 'object', 'properties': <String, dynamic>{'task_id': <String, dynamic>{'type': 'string'}}, 'required': <String>['task_id']},
        executable: (Map<String, dynamic> args) => ref.read(databaseProvider)?.taskDao.completeTask(args['task_id']?.toString() ?? '') ?? false,
      ),
      Tool(
        name: 'list_tasks',
        description: 'List current and recently completed tasks.',
        parameterMode: ToolParameterMode.object,
        parameters: <String, dynamic>{'type': 'object', 'properties': <String, dynamic>{}},
        executable: (Map<String, dynamic> args) {
          final dao = ref.read(databaseProvider)?.taskDao;
          if (dao == null) return 'Database unavailable';
          return <String, dynamic>{'current': dao.listCurrent().map((t) => <String, String>{'id': t.id, 'title': t.title}).toList(), 'history': dao.listHistory().take(10).map((t) => <String, String>{'id': t.id, 'title': t.title}).toList()};
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
      sessionId: _sessionId ?? 'current',
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
      ref.read(databaseProvider)?.sessionDao.incrementMessageCount(_sessionId ?? 'current');
      _messages.add(
        ChatMessage(
          id: assistantId,
          sessionId: _sessionId ?? 'current',
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
      final List<String> memory = await _memoryPrompts(text);
      final List<ChatMessage> contextRequest = _trimMessages(request, memory, router.config.defaultModel);
      debugPrint('CupMemo Agent payload: model=${router.config.defaultModel} messages=${contextRequest.length} systemPrompts=${memory.length} tools=${_toolsEnabled ? _tools().length : 0}');
      await for (final AgentStreamChunk chunk in router.streamMessage(
        contextRequest,
        tools: _toolsEnabled ? _tools() : null,
        systemPrompts: memory,
      )) {
        buffer.write(chunk.text);
        if (chunk.reasoning.isNotEmpty) {
          _reasoning[assistantId] = '${_reasoning[assistantId] ?? ''}${chunk.reasoning}';
        }
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

  List<ChatMessage> _trimMessages(List<ChatMessage> messages, List<String> memory, String model) {
    final int limit = ModelCapabilitiesRegistry.forModel(model).maxContextTokens;
    final int budgetChars = (limit * 4 - memory.join('\n').length).clamp(2000, limit * 4);
    var used = 0;
    final List<ChatMessage> result = <ChatMessage>[];
    for (final ChatMessage message in messages.reversed) {
      final int cost = message.content.length;
      if (used + cost > budgetChars && result.isNotEmpty) break;
      result.add(message);
      used += cost;
    }
    return result.reversed.toList(growable: false);
  }

  int _estimatedContextTokens() {
    return _messages.fold<int>(0, (int total, ChatMessage message) => total + (message.content.length / 4).ceil());
  }

  Widget _statsBar(ProviderConfig? active) {
    final int limit = ModelCapabilitiesRegistry.forModel(active?.defaultModel ?? '').maxContextTokens;
    final int used = _estimatedContextTokens();
    final int remaining = ((1 - used / limit) * 100).round().clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(children: <Widget>[
        Text('本轮 Token ${_input.text.length ~/ 4} · 上下文已用 $used · 剩余 $remaining%', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const Spacer(),
        Icon(_webSearch ? Icons.public : Icons.public_off, size: 15, color: _webSearch ? Theme.of(context).colorScheme.primary : AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(_webSearch ? '联网开' : '联网关', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
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

  static String _formatSessionDate(DateTime value) => '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ProviderConfig? active = ref.watch(activeProviderProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('会话'),
        leading: IconButton(tooltip: '菜单', icon: const Icon(Icons.menu), onPressed: () => appShellScaffoldKey.currentState?.openDrawer()),
        actions: <Widget>[
          IconButton(tooltip: '历史会话', icon: const Icon(Icons.history), onPressed: _showHistory),
          IconButton(tooltip: '新建对话', icon: const Icon(Icons.add_comment_outlined), onPressed: _newSession),
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
                      reasoning: _reasoning[_messages[index].id],
                    ),
                  ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 0), child: Row(children: <Widget>[
            FilterChip(label: const Text('工具调用'), selected: _toolsEnabled, onSelected: (bool value) => setState(() => _toolsEnabled = value)),
            const SizedBox(width: 8),
            FilterChip(label: const Text('联网搜索'), selected: _webSearch, onSelected: (bool value) => setState(() => _webSearch = value)),
          ])),
          _statsBar(active),
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
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: '记点什么…'),
                    ),
                  ),
                  IconButton(
                    tooltip: '联网搜索',
                    onPressed: () => setState(() => _webSearch = !_webSearch),
                    icon: Icon(_webSearch ? Icons.public : Icons.public_off),
                  ),
                  const SizedBox(width: 4),
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
  const _Bubble({required this.message, this.reasoning});

  final ChatMessage message;
  final String? reasoning;

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
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (reasoning != null && reasoning!.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('思考过程', style: TextStyle(fontSize: 12)),
                children: <Widget>[
                  Text(reasoning!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            Text(message.content.isEmpty ? '…' : message.content),
          ],
        ),
      ),
    );
  }
}
