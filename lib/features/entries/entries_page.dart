import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/dao/entry_dao.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/entry.dart';
import '../../providers/app_providers.dart';
import '../../services/entry_service.dart';

/// Tab 1 — local memo entries and FTS-backed index.
class EntriesPage extends ConsumerStatefulWidget {
  const EntriesPage({super.key});

  @override
  ConsumerState<EntriesPage> createState() => _EntriesPageState();
}

class _EntriesPageState extends ConsumerState<EntriesPage> {
  String? _category;
  List<Entry> _entries = const <Entry>[];
  List<String> _categories = const <String>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_reload);
  }

  Future<void> _reload() async {
    final EntryService? service = ref.read(entryServiceProvider);
    if (service == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '数据库不可用，暂时无法加载备忘录。';
        });
      }
      return;
    }
    try {
      final List<Entry> entries = await service.list(category: _category);
      final List<String> categories = await service.categories();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _categories = categories;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '加载失败：$error';
        });
      }
    }
  }

  Future<void> _openEditor([Entry? entry]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => EntryEditPage(entry: entry),
      ),
    );
    if (changed == true) await _reload();
  }

  Future<void> _delete(Entry entry) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除备忘'),
        content: Text('确定删除「${entry.title}」吗？正文文件也会删除。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final EntryService? service = ref.read(entryServiceProvider);
    if (service != null) await service.delete(entry);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备忘已删除')),
      );
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('备忘录'),
        actions: <Widget>[
          IconButton(
            tooltip: '新建备忘',
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.edit_note),
        label: const Text('新建'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: <Widget>[
            if (_categories.isNotEmpty) ...<Widget>[
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    ChoiceChip(
                      label: const Text('全部'),
                      selected: _category == null,
                      onSelected: (_) {
                        setState(() => _category = null);
                        _reload();
                      },
                    ),
                    const SizedBox(width: 8),
                    for (final String category in _categories) ...<Widget>[
                      ChoiceChip(
                        label: Text(category),
                        selected: _category == category,
                        onSelected: (_) {
                          setState(() => _category = category);
                          _reload();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              EmptyState(
                icon: Icons.storage_outlined,
                title: '备忘录暂不可用',
                description: _error!,
                actionLabel: '重试',
                onAction: _reload,
              )
            else if (_entries.isEmpty)
              EmptyState(
                icon: Icons.menu_book_outlined,
                title: '还没有任何备忘',
                description: '把想法写下来，标题、正文、分类和标签都会进入本地索引。',
                actionLabel: '新建备忘',
                onAction: () => _openEditor(),
              )
            else
              for (final Entry entry in _entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _EntryCard(
                    entry: entry,
                    onTap: () => _openEditor(entry),
                    onDelete: () => _delete(entry),
                    theme: theme,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
    required this.theme,
  });

  final Entry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(entry.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        if (entry.category.isNotEmpty)
                          Chip(
                            label: Text(entry.category),
                            visualDensity: VisualDensity.compact,
                          ),
                        for (final String tag in entry.tags)
                          Chip(
                            label: Text('#$tag'),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(entry.updatedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (String value) {
                  if (value == 'edit') onTap();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: 'edit', child: Text('编辑')),
                  PopupMenuItem<String>(value: 'delete', child: Text('删除')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final DateTime local = value.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class EntryEditPage extends ConsumerStatefulWidget {
  const EntryEditPage({super.key, this.entry});

  final Entry? entry;

  @override
  ConsumerState<EntryEditPage> createState() => _EntryEditPageState();
}

class _EntryEditPageState extends ConsumerState<EntryEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _category;
  late final TextEditingController _tags;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.entry?.title ?? '');
    _body = TextEditingController();
    _category = TextEditingController(text: widget.entry?.category ?? '');
    _tags = TextEditingController(text: widget.entry?.tags.join(', ') ?? '');
    if (widget.entry != null) Future<void>.microtask(_loadBody);
  }

  Future<void> _loadBody() async {
    final EntryService? service = ref.read(entryServiceProvider);
    if (service == null || widget.entry == null) return;
    final String body = await service.readBody(widget.entry!);
    if (mounted) _body.text = body;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _category.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final EntryService? service = ref.read(entryServiceProvider);
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('数据库不可用，无法保存')),
      );
      return;
    }
    setState(() => _saving = true);
    final List<String> tags = _tags.text
        .split(RegExp(r'[,，]'))
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
    final EntryWriteResult result;
    if (widget.entry == null) {
      result = await service.create(
        title: _title.text.trim(),
        body: _body.text,
        category: _category.text.trim(),
        tags: tags,
      );
    } else {
      result = await service.update(
        entry: widget.entry!,
        title: _title.text.trim(),
        body: _body.text,
        category: _category.text.trim(),
        tags: tags,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.outcome == EntryWriteOutcome.duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内容重复，未创建新的备忘')),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? '新建备忘' : '编辑备忘'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: <Widget>[
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: '标题',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (String? value) =>
                  value == null || value.trim().isEmpty ? '请填写标题' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _body,
              minLines: 9,
              maxLines: 18,
              decoration: const InputDecoration(
                labelText: '正文',
                alignLabelWithHint: true,
                hintText: '写下你的想法…',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(
                labelText: '分类',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: '标签',
                hintText: '例如：设计, 研究',
                prefixIcon: Icon(Icons.sell_outlined),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? '保存中…' : '保存备忘'),
            ),
          ],
        ),
      ),
    );
  }
}
