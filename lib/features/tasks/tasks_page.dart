import 'package:flutter/material.dart';

import '../../app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/dao/task_dao.dart';
import '../../core/db/database.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/task.dart';
import '../../providers/app_providers.dart';

/// Tab 4 — tasks split into "current" and "completed history".
///
/// A task is never mutated in place: completing it moves the row from
/// `current_tasks` to `history_tasks`, and the undo action moves it back.
class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  List<Task> _current = const <Task>[];
  List<Task> _history = const <Task>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_reload);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TaskDao? get _dao {
    final AppDatabase? db = ref.read(databaseProvider);
    return db?.taskDao;
  }

  Future<void> _reload() async {
    final TaskDao? dao = _dao;
    if (dao == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '数据库不可用，暂时无法加载任务。';
        });
      }
      return;
    }
    try {
      final List<Task> current = dao.listCurrent();
      final List<Task> history = dao.listHistory();
      if (!mounted) return;
      setState(() {
        _current = current;
        _history = history;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '加载任务失败：$error';
        });
      }
    }
  }

  Future<void> _addTask() async {
    final TextEditingController title = TextEditingController();
    final TextEditingController detail = TextEditingController();
    final bool? created = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('新建任务'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: title,
              autofocus: true,
              decoration: const InputDecoration(labelText: '标题'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detail,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '详情（可选）',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    final String taskTitle = title.text.trim();
    final String taskDetail = detail.text.trim();
    title.dispose();
    detail.dispose();
    if (created != true || taskTitle.isEmpty) return;

    final TaskDao? dao = _dao;
    if (dao == null) return;
    dao.addCurrentTask(title: taskTitle, detail: taskDetail);
    await _reload();
    if (!mounted) return;
    _tabController.animateTo(0);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('已添加任务「$taskTitle」')));
  }

  Future<void> _complete(Task task) async {
    final TaskDao? dao = _dao;
    if (dao == null) return;
    final bool done = dao.completeTask(task.id);
    if (!done) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('已完成「${task.title}」'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () async {
              dao.restoreTask(task.id);
              await _reload();
            },
          ),
        ),
      );
  }

  Future<void> _delete(Task task, {required bool fromHistory}) async {
    final TaskDao? dao = _dao;
    if (dao == null) return;
    if (fromHistory) {
      dao.deleteHistory(task.id);
    } else {
      dao.deleteCurrent(task.id);
    }
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('已删除「${task.title}」')));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: '菜单', icon: const Icon(Icons.menu), onPressed: () => appShellScaffoldKey.currentState?.openDrawer()),
        title: const Text('任务'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          indicatorColor: theme.colorScheme.primary,
          tabs: <Widget>[
            Tab(text: '当前任务（${_current.length}）'),
            Tab(text: '历史已完成（${_history.length}）'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: '新建任务',
            onPressed: _addTask,
            icon: const Icon(Icons.add_task),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildCurrent(theme),
                _buildHistory(theme),
              ],
            ),
    );
  }

  Widget _buildCurrent(ThemeData theme) {
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          EmptyState(
            icon: Icons.storage_outlined,
            title: '任务暂不可用',
            description: _error!,
            actionLabel: '重试',
            onAction: _reload,
          ),
        ],
      );
    }
    if (_current.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          EmptyState(
            icon: Icons.checklist_outlined,
            title: '当前没有进行中的任务',
            description: '新建任务后，点右侧的勾选即可完成并移入历史。',
            actionLabel: '新建任务',
            onAction: _addTask,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _current.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final Task task = _current[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            title: Text(task.title),
            subtitle: task.detail.isEmpty
                ? Text(
                    '创建于 ${_formatDate(task.createdAt)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 4),
                      Text(task.detail),
                      const SizedBox(height: 4),
                      Text(
                        '创建于 ${_formatDate(task.createdAt)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  tooltip: '完成',
                  icon: const Icon(Icons.check_circle_outline),
                  color: theme.colorScheme.primary,
                  onPressed: () => _complete(task),
                ),
                IconButton(
                  tooltip: '删除',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(task, fromHistory: false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistory(ThemeData theme) {
    if (_history.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const <Widget>[
          EmptyState(
            icon: Icons.history,
            title: '历史任务为空',
            description: '完成的任务会出现在这里，可删除，也可在完成时点「撤销」退回当前任务。',
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final Task task = _history[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            leading: const Icon(Icons.check_circle, color: Color(0xFF9CBFA8)),
            title: Text(
              task.title,
              style: const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: AppColors.textSecondary,
              ),
            ),
            subtitle: Text(
              '完成于 ${_formatDate(task.completedAt ?? task.createdAt)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            trailing: IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(task, fromHistory: true),
            ),
          ),
        );
      },
    );
  }

  static String _formatDate(DateTime value) {
    final DateTime local = value.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
