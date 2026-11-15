import 'dart:async';

import 'package:flutter/material.dart';

import '../../app.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/id.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/db/dao/session_dao.dart';
import '../../models/chat_message.dart';
import '../../models/entry.dart';
import '../../providers/app_providers.dart';
import '../../services/entry_service.dart';
import '../../services/provider/provider_config.dart';
import '../../services/provider/model_capabilities.dart';
import '../../services/provider/provider_router.dart';
import '../../services/github_service.dart';
import '../../services/search/web_search_service.dart';

import 'package:dartantic_ai/dartantic_ai.dart' as da;
import 'package:flutter/services.dart';

import '../settings/provider_management_page.dart';
import '../settings/provider_form_page.dart';

class StreamingBubbleNotifier extends ValueNotifier<String> {
  StreamingBubbleNotifier() : super('');
  final StringBuffer _buffer = StringBuffer();
  bool _scheduled = false;
  void append(String delta) {
    _buffer.write(delta);
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      value = _buffer.toString();
    });
  }

  void finalize() {
    value = _buffer.toString();
  }
}

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
  final Map<String, StreamingBubbleNotifier> _streaming =
      <String, StreamingBubbleNotifier>{};
  int _activeTurnId = 0;
  String? _sessionId;
  int _historyOffset = 0;
  bool _loadingOlder = false;
  bool _hasOlder = true;
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

  Future<void> _ensureSession() async {
    if (_sessionId != null) return;
    final db = ref.read(databaseProvider);
    final latest = db?.sessionDao.latestActive();
    final String id = latest?.id ?? db?.sessionDao.create() ?? newSessionId();
    final List<ChatMessage> history =
        db?.chatMessageDao.list(id, limit: 50) ?? const <ChatMessage>[];
    _historyOffset = history.length;
    _hasOlder = history.length == 50;
    if (!mounted) return;
    setState(() {
      _sessionId = id;
      _messages
        ..clear()
        ..addAll(history);
    });
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder || !_hasOlder || _sessionId == null) return;
    final db = ref.read(databaseProvider);
    if (db == null) return;
    _loadingOlder = true;
    final double oldExtent = _scroll.hasClients
        ? _scroll.position.maxScrollExtent
        : 0;
    final double oldPixels = _scroll.hasClients ? _scroll.position.pixels : 0;
    final List<ChatMessage> older = db.chatMessageDao.list(
      _sessionId!,
      limit: 50,
      offset: _historyOffset,
    );
    setState(() {
      _messages.insertAll(0, older);
      _historyOffset += older.length;
      _hasOlder = older.length == 50;
      _loadingOlder = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(
          oldPixels + (_scroll.position.maxScrollExtent - oldExtent),
        );
      }
    });
  }

  Future<void> startNewSession() => _newSession();

  Future<void> _newSession() async {
    final db = ref.read(databaseProvider);
    if (db != null && _sessionId != null) db.sessionDao.end(_sessionId!);
    final String newId = db?.sessionDao.create() ?? newSessionId();
    setState(() {
      _sessionId = newId;
      _messages.clear();
      _reasoning.clear();
      _historyOffset = 0;
      _hasOlder = false;
    });
  }

  Future<void> _openSession(String sessionId) async {
    final db = ref.read(databaseProvider);
    if (db == null) return;
    final List<ChatMessage> page = db.chatMessageDao.list(sessionId, limit: 50);
    setState(() {
      _sessionId = sessionId;
      _messages
        ..clear()
        ..addAll(page);
      _historyOffset = page.length;
      _hasOlder = page.length == 50;
      _reasoning.clear();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    for (final StreamingBubbleNotifier notifier in _streaming.values) {
      notifier.dispose();
    }
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
      if (_webSearch)
        da.Tool<Map<String, dynamic>>(
          name: 'web_search',
          description: 'Search the web using the configured search provider.',
          inputSchema: da.Schema.fromMap({
            'type': 'object',
            'properties': {
              'query': {'type': 'string'},
            },
            'required': ['query'],
          }),
          onCall: (Map<String, dynamic> args) async {
            final WebSearchConfig config = WebSearchConfig.load(
              ref.read(sharedPreferencesProvider),
            );
            if (config.provider != WebSearchProvider.searxng &&
                config.apiKey.isEmpty) {
              return 'Search API key is not configured';
            }
            final results = await WebSearchService(config)
                .search(args['query']?.toString() ?? '');
            return results;
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

  String _friendlyError(Object error) {
    final String text = error.toString().toLowerCase();
    if (text.contains('401') ||
        text.contains('403') ||
        text.contains('authenticationexception') ||
        text.contains('permissiondeniedexception')) {
      return 'API 密钥无效或未授权';
    }
    if (text.contains('timeout') || text.contains('timed out')) {
      return '网络连接超时，请检查网络';
    }
    if (text.contains('html') || text.contains('waf') || text.contains('5')) {
      return '请求被服务器拦截或中转站异常';
    }
    return '请求失败，请检查服务商设置后重试';
  }

  void _saveBranchChild(ChatMessage parent, ChatMessage child) {
    final int index = _messages.indexWhere(
      (ChatMessage item) => item.id == parent.id,
    );
    if (index < 0) return;
    final ChatMessage linked = ChatMessage(
      id: parent.id,
      sessionId: parent.sessionId,
      role: parent.role,
      content: parent.content,
      createdAt: parent.createdAt,
      providerId: parent.providerId,
      model: parent.model,
      parentId: parent.parentId,
      childrenIds: <String>[...parent.childrenIds, child.id],
    );
    _messages[index] = linked;
    ref.read(databaseProvider)?.chatMessageDao.upsert(linked);
  }

  Future<void> _editUserMessage(ChatMessage message) async {
    final TextEditingController edit = TextEditingController(
      text: message.content,
    );
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext dialog) => AlertDialog(
        title: const Text('编辑消息'),
        content: TextField(controller: edit, minLines: 1, maxLines: 6),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, edit.text.trim()),
            child: const Text('重新发送'),
          ),
        ],
      ),
    );
    edit.dispose();
    if (value == null || value.isEmpty || !mounted) return;
    final db = ref.read(databaseProvider);
    final String branchId = newMessageId();
    final ChatMessage branch = ChatMessage(
      id: branchId,
      sessionId: message.sessionId,
      role: ChatRole.user,
      content: value,
      createdAt: DateTime.now(),
      providerId: message.providerId,
      model: message.model,
      parentId: message.parentId,
    );
    db?.chatMessageDao.deactivateFrom(message.sessionId, message.id);
    if (message.parentId != null) {
      final ChatMessage? parent = _messages
          .where((ChatMessage item) => item.id == message.parentId)
          .firstOrNull;
      if (parent != null) {
        _saveBranchChild(parent, branch);
      } else {
        db?.chatMessageDao.addChild(message.parentId!, branch.id);
      }
    }
    db?.chatMessageDao.upsert(branch);
    final int index = _messages.indexWhere(
      (ChatMessage item) => item.id == message.id,
    );
    setState(() {
      if (index >= 0) _messages.removeRange(index, _messages.length);
      _messages.add(branch);
      _input.text = value;
    });
    await _send(overrideText: value, addUser: false, parentId: branchId);
  }

  Future<void> _regenerate(ChatMessage message) async {
    final int index = _messages.indexWhere(
      (ChatMessage item) => item.id == message.id,
    );
    if (index < 1) return;
    final ChatMessage parent = _messages[index - 1];
    final String prompt = parent.content;
    final db = ref.read(databaseProvider);
    final String siblingId = newMessageId();
    final ChatMessage sibling = ChatMessage(
      id: siblingId,
      sessionId: message.sessionId,
      role: ChatRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      providerId: message.providerId,
      model: message.model,
      parentId: parent.id,
    );
    final int parentIndex = _messages.indexWhere(
      (ChatMessage item) => item.id == parent.id,
    );
    if (parentIndex >= 0) {
      _saveBranchChild(_messages[parentIndex], sibling);
    } else {
      db?.chatMessageDao.addChild(parent.id, sibling.id);
    }
    db?.chatMessageDao.deactivateMessage(message.id);
    db?.chatMessageDao.deleteAfter(message.sessionId, message.id);
    setState(() {
      _messages.removeRange(index, _messages.length);
      _input.text = prompt;
    });
    await _send(
      overrideText: prompt,
      addUser: false,
      parentId: parent.id,
      assistantId: siblingId,
    );
  }

  Future<void> _send({
    String? overrideText,
    bool addUser = true,
    String? parentId,
    String? assistantId,
  }) async {
    final int turnId = ++_activeTurnId;
    final String text = overrideText ?? _input.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    final ProviderRouter? router = await ref.read(
      providerRouterProvider.future,
    );
    if (router == null) {
      if (!mounted) return;
      showPendingSnackBar(context, '请先配置服务商和访问密钥');
      return;
    }

    _input.clear();
    final String? userParentId =
        parentId ?? (_messages.isEmpty ? null : _messages.last.id);
    final ChatMessage? user = addUser
        ? ChatMessage(
            id: newMessageId(),
            sessionId: _sessionId ?? 'current',
            role: ChatRole.user,
            content: text,
            createdAt: DateTime.now(),
            providerId: router.config.id,
            model: _modelFor(router.config),
            parentId: userParentId,
          )
        : null;
    final List<ChatMessage> request = <ChatMessage>[..._messages, ?user];
    final String activeAssistantId = assistantId ?? newMessageId();
    final String? assistantParentId =
        user?.id ??
        parentId ??
        (_messages.isNotEmpty ? _messages.last.id : null);
    setState(() {
      if (user != null) {
        if (user.parentId != null) {
          final ChatMessage? parent = _messages
              .where((ChatMessage item) => item.id == user.parentId)
              .firstOrNull;
          if (parent != null) {
            _saveBranchChild(parent, user);
          } else {
            ref
                .read(databaseProvider)
                ?.chatMessageDao
                .addChild(user.parentId!, user.id);
          }
        }
        _messages.add(user);
        ref.read(databaseProvider)?.chatMessageDao.upsert(user);
      }
      ref
          .read(databaseProvider)
          ?.sessionDao
          .incrementMessageCount(_sessionId ?? 'current');
      _messages.add(
        ChatMessage(
          id: activeAssistantId,
          sessionId: _sessionId ?? 'current',
          role: ChatRole.assistant,
          content: '',
          createdAt: DateTime.now(),
          providerId: router.config.id,
          model: _modelFor(router.config),
          parentId: assistantParentId,
        ),
      );
      _sending = true;
    });
    _scrollToBottom();

    final StreamingBubbleNotifier live = StreamingBubbleNotifier();
    _streaming[activeAssistantId] = live;
    final StringBuffer buffer = StringBuffer();
    Timer? flushTimer;
    void flush() {
      flushTimer?.cancel();
      flushTimer = null;
      final int index = _messages.indexWhere(
        (ChatMessage m) => m.id == activeAssistantId,
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
          parentId: old.parentId,
          childrenIds: old.childrenIds,
        );
        ref.read(databaseProvider)?.chatMessageDao.upsert(_messages[index]);
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
        if (turnId != _activeTurnId) break;
        buffer.write(chunk.text);
        live.append(chunk.text);
        if (chunk.reasoning.isNotEmpty) {
          _reasoning[activeAssistantId] =
              '${_reasoning[activeAssistantId] ?? ''}${chunk.reasoning}';
        }
        scheduleFlush();
      }
      flushTimer?.cancel();
      live.finalize();
      flush();
    } catch (error) {
      flushTimer?.cancel();
      final int index = _messages.indexWhere(
        (ChatMessage m) => m.id == activeAssistantId,
      );
      if (mounted && index >= 0) {
        final old = _messages[index];
        setState(() {
          _messages[index] = ChatMessage(
            id: old.id,
            sessionId: old.sessionId,
            role: old.role,
            content: _friendlyError(error),
            createdAt: old.createdAt,
            providerId: old.providerId,
            model: old.model,
            parentId: old.parentId,
            childrenIds: old.childrenIds,
          );
          ref.read(databaseProvider)?.chatMessageDao.upsert(_messages[index]);
        });
      }
    } finally {
      _streaming.remove(activeAssistantId);
      live.dispose();
      if (mounted) setState(() => _sending = false);
    }
  }

  List<ChatMessage> _trimMessages(
    List<ChatMessage> messages,
    List<String> memory,
    String model,
  ) {
    final int limit =
        ModelCapabilitiesRegistry.forModel(model).maxContextTokens ?? 0;
    final int budgetChars = limit > 0
        ? (limit * 4 - memory.join('\n').length).clamp(0, limit * 4)
        : 0;
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
    if (_scroll.hasClients &&
        _scroll.position.maxScrollExtent - _scroll.position.pixels > 150) {
      return;
    }
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

  Future<void> _showHistory() async {
    final db = ref.read(databaseProvider);
    if (db == null) return;
    final List<ChatSessionRecord> sessions = db.sessionDao.list();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheet) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheet).height * 0.65,
          child: ListView(
            children: <Widget>[
              const ListTile(title: Text('历史会话')),
              for (final ChatSessionRecord session in sessions)
                ListTile(
                  title: Text(
                    '会话 ${session.id.substring(0, session.id.length < 8 ? session.id.length : 8)}',
                  ),
                  subtitle: Text(
                    '${session.startedAt} · ${session.messageCount} 条消息',
                  ),
                  onTap: () {
                    Navigator.pop(sheet);
                    _openSession(session.id);
                  },
                ),
              if (sessions.isEmpty) const ListTile(title: Text('暂无历史会话')),
            ],
          ),
        ),
      ),
    );
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
            const ListTile(title: Text('切换服务商（影响后续消息）')),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(sheetContext).pop('__add__'),
                  icon: const Icon(Icons.add),
                  label: const Text('添加新服务商'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    if (selected == '__add__') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const ProviderFormPage()));
      return;
    }
    ref.read(currentProviderIdProvider.notifier).select(selected);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('服务商已切换，仅影响后续消息')));
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          appShellScaffoldKey.currentState?.openDrawer();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('会话'),
          leading: IconButton(
            tooltip: '菜单',
            icon: const Icon(Icons.menu),
            onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
          ),
          actions: <Widget>[
            IconButton(
              tooltip: '历史会话',
              icon: const Icon(Icons.history),
              onPressed: _showHistory,
            ),
            IconButton(
              tooltip: '新建对话',
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: _newSession,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ActionChip(
                avatar: const Icon(Icons.hub_outlined, size: 16),
                label: Text(active?.name ?? '未配置服务商'),
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
                      title: active == null ? '还没有可用的服务商' : '会话尚未开始',
                      description: active == null
                          ? '先添加服务商和访问密钥。'
                          : '输入消息开始流式对话。AI 可调用本地搜索和创建条目工具。',
                      actionLabel: active == null ? '添加服务商' : null,
                      onAction: active == null ? _pickProvider : null,
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification notification) {
                        if (notification.metrics.pixels <= 80 && _hasOlder) {
                          _loadOlder();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        controller: _scroll,
                        addAutomaticKeepAlives: false,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: _messages.length,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) =>
                            _Bubble(
                              message: _messages[index],
                              reasoning: _reasoning[_messages[index].id],
                              onLongPress: () =>
                                  _messages[index].role == ChatRole.user
                                  ? _editUserMessage(_messages[index])
                                  : _regenerate(_messages[index]),
                            ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    ActionChip(
                      avatar: const Icon(Icons.memory_outlined, size: 16),
                      label: Text(activeModel.isEmpty ? '选择模型' : activeModel),
                      onPressed: active == null
                          ? null
                          : () async {
                              final String? value =
                                  await showModalBottomSheet<String>(
                                    context: context,
                                    builder: (BuildContext sheet) => SafeArea(
                                      child: ListView(
                                        shrinkWrap: true,
                                        children: <Widget>[
                                          const ListTile(title: Text('选择模型')),
                                          for (final String model
                                              in active.availableModels)
                                            ListTile(
                                              title: Text(model),
                                              trailing: model == activeModel
                                                  ? const Icon(Icons.check)
                                                  : null,
                                              onTap: () =>
                                                  Navigator.pop(sheet, model),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                              if (value != null && mounted) {
                                setState(() {
                                  _selectedModel = value;
                                  _thinkingEnabled =
                                      ModelCapabilitiesRegistry.forModel(
                                        value,
                                        manualOverride: active.modelParameters,
                                      ).supportsThinking;
                                });
                              }
                            },
                    ),
                    const SizedBox(width: 8),
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
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.reasoning, this.onLongPress});

  final ChatMessage message;
  final String? reasoning;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool user = message.role == ChatRole.user;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
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
                    child: Text(
                      message.content.isEmpty ? '…' : message.content,
                    ),
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
      ),
    );
  }
}
