import 'dart:async';

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
import '../../services/github_service.dart';

import 'package:dartantic_ai/dartantic_ai.dart' as da;
import 'package:flutter/services.dart';

import '../settings/provider_management_page.dart';

/// Tab 3 — real streaming chat with tool-assisted local memory.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => ChatPageState();
}

class ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  final Map<String, String> _reasoning = <String, String>{};
  String? _sessionId;
  bool _sending = false;
  bool _webSearch = false;
  final bool _toolsEnabled = true;
  bool _thinkingEnabled = false;
  String? _selectedModel;

  String _modelFor(ProviderConfig? provider) =>
      _selectedModel ?? provider?.defaultModel ?? '';

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_ensureSession);
  }

  void _ensureSession() {
    if (_sessionId != null) return;
    final db = ref.read(databaseProvider);
    final empty = db?.sessionDao.findEmpty();
    setState(
      () => _sessionId = empty?.id ?? db?.sessionDao.create() ?? newSessionId(),
    );
  }

  Future<void> startNewSession() => _newSession();

  Future<void> _newSession() async {
    final db = ref.read(databaseProvider);
    if (db != null && _sessionId != null) db.sessionDao.end(_sessionId!);
    setState(() {
      _sessionId = db?.sessionDao.create() ?? newSessionId();
      _messages.clear();
      _reasoning.clear();
    });
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
      '【本地工具说明】你可以使用备忘录、任务工具，以及 fetch_github_file 和 commit_github_file 读取或写入 GitHub；只有用户明确要求时才写入。',
    ];
    if (_webSearch) {
      final List<Entry> hits = await service.search(query);
      final List<String> searchBlocks = <String>[];
      for (final Entry hit in hits.take(5)) {
        searchBlocks.add(
          '[本地搜索 ${hit.title}]：${(await service.readBody(hit)).trim()}',
        );
      }
      prompts.add(
        '【联网搜索开关已开启】当前无外部搜索 API，优先使用以下本地搜索上下文：\n${searchBlocks.join('\n')}',
      );
    }
    return prompts;
  }

  List<da.Tool> _tools() {
    return <da.Tool>[
      da.Tool<Map<String, dynamic>>(
        name: 'search_entries',
        description: 'Search local Cup Memo entries.',
        inputSchema: da.Schema.fromMap({
          'type': 'object',
          'properties': {
            'query': {'type': 'string'},
          },
          'required': ['query'],
        }),
        onCall: (Map<String, dynamic> args) async {
          final EntryService? service = ref.read(entryServiceProvider);
          if (service == null) return 'Database unavailable';
          final List<Entry> entries = await service.search(
            args['query']?.toString() ?? '',
          );
          return entries
              .take(10)
              .map(
                (Entry e) => {
                  'id': e.id,
                  'title': e.title,
                  'category': e.category,
                },
              )
              .toList();
        },
      ),
      da.Tool<Map<String, dynamic>>(
        name: 'create_entry',
        description: 'Create a local memo entry when explicitly requested.',
        inputSchema: da.Schema.fromMap({
          'type': 'object',
          'properties': {
            'title': {'type': 'string'},
            'body': {'type': 'string'},
            'category': {'type': 'string'},
          },
          'required': ['title', 'body'],
        }),
        onCall: (Map<String, dynamic> args) async {
          final EntryService? service = ref.read(entryServiceProvider);
          if (service == null) return 'Database unavailable';
          final result = await service.create(
            title: args['title']?.toString() ?? 'Untitled',
            body: args['body']?.toString() ?? '',
            category: args['category']?.toString() ?? 'AI',
            tags: const ['AI'],
            isAiContext: false,
          );
          return 'Entry ${result.entryId} created (${result.outcome.name})';
        },
      ),
      da.Tool<Map<String, dynamic>>(
        name: 'add_task',
        description: 'Add a current task.',
        inputSchema: da.Schema.fromMap({
          'type': 'object',
          'properties': {
            'title': {'type': 'string'},
            'detail': {'type': 'string'},
          },
          'required': ['title'],
        }),
        onCall: (Map<String, dynamic> args) =>
            ref
                .read(databaseProvider)
                ?.taskDao
                .addCurrentTask(
                  title: args['title']?.toString() ?? 'Untitled',
                  detail: args['detail']?.toString() ?? '',
                ) ??
            'Database unavailable',
      ),
      da.Tool<Map<String, dynamic>>(
        name: 'complete_task',
        description: 'Complete a task by id.',
        inputSchema: da.Schema.fromMap({
          'type': 'object',
          'properties': {
            'task_id': {'type': 'string'},
          },
          'required': ['task_id'],
        }),
        onCall: (Map<String, dynamic> args) =>
            ref
                .read(databaseProvider)
                ?.taskDao
                .completeTask(args['task_id']?.toString() ?? '') ??
            false,
      ),
      da.Tool<Map<String, dynamic>>(
        name: 'fetch_github_file',
        description:
            'Read a file from GitHub using the configured secure token.',
        inputSchema: da.Schema.fromMap({
          'type': 'object',
          'properties': {
            'owner': {'type': 'string'},
            'repo': {'type': 'string'},
            'path': {'type': 'string'},
            'ref': {'type': 'string'},
          },
          'required': ['owner', 'repo', 'path'],
        }),
        onCall: (Map<String, dynamic> args) => GitHubService().fetchFile(
          owner: args['owner'].toString(),
          repo: args['repo'].toString(),
          path: args['path'].toString(),
          ref: args['ref']?.toString() ?? 'main',
        ),
      ),
      da.Tool<Map<String, dynamic>>(
        name: 'commit_github_file',
        description:
            'Commit a file to GitHub using the configured secure token.',
        inputSchema: da.Schema.fromMap({
          'type': 'object',
          'properties': {
            'owner': {'type': 'string'},
            'repo': {'type': 'string'},
            'path': {'type': 'string'},
            'content': {'type': 'string'},
            'message': {'type': 'string'},
            'branch': {'type': 'string'},
          },
          'required': ['owner', 'repo', 'path', 'content', 'message'],
        }),
        onCall: (Map<String, dynamic> args) async {
          await GitHubService().commitFile(
            owner: args['owner'].toString(),
            repo: args['repo'].toString(),
            path: args['path'].toString(),
            content: args['content'].toString(),
            message: args['message'].toString(),
            branch: args['branch']?.toString() ?? 'main',
          );
          return 'GitHub commit completed';
        },
      ),
      da.Tool<Map<String, dynamic>>(
        name: 'list_tasks',
        description: 'List current and recently completed tasks.',
        onCall: (_) {
          final dao = ref.read(databaseProvider)?.taskDao;
          return dao == null
              ? 'Database unavailable'
              : {
                  'current': dao
                      .listCurrent()
                      .map((t) => {'id': t.id, 'title': t.title})
                      .toList(),
                  'history': dao
                      .listHistory()
                      .take(10)
                      .map((t) => {'id': t.id, 'title': t.title})
                      .toList(),
                };
        },
      ),
    ];
  }

  Future<void> _send() async {
    final String text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final ProviderRouter? router = await ref.read(
      providerRouterProvider.future,
    );
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
      model: _modelFor(router.config),
    );
    final List<ChatMessage> request = <ChatMessage>[..._messages, user];
    final String assistantId = newMessageId();
    setState(() {
      _messages.add(user);
      ref
          .read(databaseProvider)
          ?.sessionDao
          .incrementMessageCount(_sessionId ?? 'current');
      _messages.add(
        ChatMessage(
          id: assistantId,
          sessionId: _sessionId ?? 'current',
          role: ChatRole.assistant,
          content: '',
          createdAt: DateTime.now(),
          providerId: router.config.id,
          model: _modelFor(router.config),
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
      final int index = _messages.indexWhere(
        (ChatMessage m) => m.id == assistantId,
      );
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
      final List<ChatMessage> contextRequest = _trimMessages(
        request,
        memory,
        _modelFor(router.config),
      );
      debugPrint(
        'CupMemo Agent payload: model=${_modelFor(router.config)} messages=${contextRequest.length} systemPrompts=${memory.length} tools=${_toolsEnabled ? _tools().length : 0}',
      );
      await for (final AgentStreamChunk chunk in router.streamMessage(
        contextRequest,
        tools: _toolsEnabled ? _tools() : null,
        systemPrompts: memory,
      )) {
        buffer.write(chunk.text);
        if (chunk.reasoning.isNotEmpty) {
          _reasoning[assistantId] =
              '${_reasoning[assistantId] ?? ''}${chunk.reasoning}';
        }
        scheduleFlush();
      }
      flushTimer?.cancel();
      flush();
    } catch (error) {
      flushTimer?.cancel();
      final int index = _messages.indexWhere(
        (ChatMessage m) => m.id == assistantId,
      );
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

  List<ChatMessage> _trimMessages(
    List<ChatMessage> messages,
    List<String> memory,
    String model,
  ) {
    final int limit = ModelCapabilitiesRegistry.forModel(model)
        .maxContextTokens;
    final int budgetChars = (limit * 4 - memory.join('\n').length).clamp(
      2000,
      limit * 4,
    );
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
                trailing: item.isDefault
                    ? const Icon(Icons.star, size: 18)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(item.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    ref.read(currentProviderIdProvider.notifier).select(selected);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Provider 已切换，仅影响后续消息')));
  }

  @override
  Widget build(BuildContext context) {
    final ProviderConfig? active = ref.watch(activeProviderProvider);
    final String activeModel = _modelFor(active);
    final ModelCapabilities caps = ModelCapabilitiesRegistry.forModel(
      activeModel,
      manualOverride: active?.modelParameters,
    );
    if (!caps.supportsThinking && _thinkingEnabled) _thinkingEnabled = false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('会话'),
        leading: IconButton(
          tooltip: '菜单',
          icon: const Icon(Icons.menu),
          onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: '新建对话',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _newSession,
          ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              children: <Widget>[
                if (active != null && active.availableModels.isNotEmpty)
                  DropdownButton<String>(
                    value: active.availableModels.contains(activeModel)
                        ? activeModel
                        : null,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: active.availableModels
                        .map(
                          (String model) => DropdownMenuItem<String>(
                            value: model,
                            child: Text(model),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedModel = value;
                          _thinkingEnabled = ModelCapabilitiesRegistry.forModel(
                            value,
                            manualOverride: active.modelParameters,
                          ).supportsThinking;
                        });
                      }
                    },
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '模型：$activeModel',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                Row(
                  children: <Widget>[
                    FilterChip(
                      avatar: Icon(
                        _thinkingEnabled
                            ? Icons.psychology
                            : Icons.psychology_outlined,
                        size: 16,
                      ),
                      label: const Text('深度思考'),
                      selected: _thinkingEnabled,
                      onSelected: caps.supportsThinking
                          ? (bool value) =>
                                setState(() => _thinkingEnabled = value)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: Icon(
                        _webSearch ? Icons.public : Icons.public_off,
                        size: 16,
                      ),
                      label: const Text('联网搜索'),
                      selected: _webSearch,
                      onSelected: (bool value) =>
                          setState(() => _webSearch = value),
                    ),
                  ],
                ),
              ],
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
                  Text(
                    reasoning!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Text(message.content.isEmpty ? '…' : message.content),
                ),
                IconButton(
                  tooltip: '复制',
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: message.content)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
