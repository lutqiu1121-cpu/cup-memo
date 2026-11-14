import 'dart:async';

import 'package:flutter/material.dart';

import '../../app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/entry.dart';
import '../../providers/app_providers.dart';
import '../../services/entry_service.dart';
import '../entries/entries_page.dart';

/// Tab 2 — full-text search across local entries.
///
/// Every keystroke is debounced by [debounceDuration]; the actual query goes
/// through `EntryService.search` → `EntryDao.search`, which runs the same
/// `cjk_tokenizer` bigram pipeline used when the index was written.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  static const Duration debounceDuration = Duration(milliseconds: 300);
  static const String historyPrefsKey = 'cup_memo.search.history';
  static const int historyLimit = 20;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  List<Entry> _results = const <Entry>[];
  List<String> _history = const <String>[];
  String _query = '';
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadHistory);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final List<String> stored =
        prefs.getStringList(SearchPage.historyPrefsKey) ?? const <String>[];
    if (mounted) {
      setState(() => _history = stored);
    }
  }

  Future<void> _rememberQuery(String query) async {
    final String value = query.trim();
    if (value.isEmpty) return;
    final List<String> next = <String>[
      value,
      ..._history.where((String item) => item != value),
    ].take(SearchPage.historyLimit).toList(growable: false);
    if (mounted) {
      setState(() => _history = next);
    }
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(SearchPage.historyPrefsKey, next);
  }

  Future<void> _clearHistory() async {
    setState(() => _history = const <String>[]);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(SearchPage.historyPrefsKey);
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = const <Entry>[];
        _error = null;
        _searching = false;
      });
      return;
    }
    _debounce = Timer(SearchPage.debounceDuration, () => _search(value));
  }

  Future<void> _search(String rawQuery) async {
    final String query = rawQuery.trim();
    if (query.isEmpty) return;
    final EntryService? service = ref.read(entryServiceProvider);
    if (service == null) {
      if (mounted) {
        setState(() {
          _searching = false;
          _error = '数据库不可用，暂时无法搜索。';
        });
      }
      return;
    }
    if (mounted) setState(() => _searching = true);
    try {
      final List<Entry> results = await service.search(query);
      if (!mounted || _query.trim() != query) return;
      setState(() {
        _results = results;
        _searching = false;
        _error = null;
      });
      if (results.isNotEmpty) await _rememberQuery(query);
    } catch (error) {
      if (mounted && _query.trim() == query) {
        setState(() {
          _searching = false;
          _error = '搜索失败：$error';
        });
      }
    }
  }

  Future<void> _useHistoryTerm(String term) async {
    _controller.value = TextEditingValue(
      text: term,
      selection: TextSelection.collapsed(offset: term.length),
    );
    setState(() => _query = term);
    await _search(term);
  }

  Future<void> _openEntry(Entry entry) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => EntryEditPage(entry: entry),
      ),
    );
    if (changed == true && _query.trim().isNotEmpty) {
      await _search(_query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String trimmed = _query.trim();

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => appShellScaffoldKey.currentState?.openDrawer()), title: const Text('搜索')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: (String value) {
                _debounce?.cancel();
                _search(value);
              },
              decoration: InputDecoration(
                hintText: '搜索标题、正文、标签或分类…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: trimmed.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清空',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                          _focusNode.requestFocus();
                        },
                      ),
              ),
            ),
          ),
          Expanded(child: _buildBody(theme, trimmed)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, String trimmed) {
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          EmptyState(
            icon: Icons.storage_outlined,
            title: '搜索暂不可用',
            description: _error!,
            actionLabel: '重试',
            onAction: () => _search(_query),
          ),
        ],
      );
    }

    if (trimmed.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: <Widget>[
          if (_history.isEmpty)
            const EmptyState(
              icon: Icons.manage_search,
              title: '输入关键词开始搜索',
              description: '标题、正文、标签与分类都进入本地 FTS5 索引，'
                  '中文会按相邻两字切分，做到字面模糊匹配。',
            )
          else ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '搜索历史',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: _clearHistory,
                  child: const Text('清空'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String term in _history)
                  ActionChip(
                    avatar: const Icon(Icons.history, size: 16),
                    label: Text(term),
                    onPressed: () => _useHistoryTerm(term),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const EmptyState(
              icon: Icons.manage_search,
              title: '输入关键词开始搜索',
              description: '结果会随输入实时更新；点击搜索历史可快速复用。',
            ),
          ],
        ],
      );
    }

    if (_searching && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          EmptyState(
            icon: Icons.search_off_outlined,
            title: '没有找到「$trimmed」',
            description: '试试更短的关键词，或换一个同义词。\n'
                '提示：中文按相邻两字建立索引，两个字以上更容易命中。',
            actionLabel: '清空并重新输入',
            onAction: () {
              _controller.clear();
              _onQueryChanged('');
              _focusNode.requestFocus();
            },
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _results.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '找到 ${_results.length} 条结果',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }
        final Entry entry = _results[index - 1];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openEntry(entry),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  HighlightedText(
                    text: entry.title,
                    query: trimmed,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      if (entry.category.isNotEmpty)
                        Chip(
                          label: HighlightedText(
                            text: entry.category,
                            query: trimmed,
                            style: theme.textTheme.labelSmall,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      for (final String tag in entry.tags)
                        Chip(
                          label: HighlightedText(
                            text: '#$tag',
                            query: trimmed,
                            style: theme.textTheme.labelSmall,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.mdPath.isEmpty ? '没有正文' : entry.mdPath.split('/').last,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Renders [text] with every occurrence of the query terms highlighted.
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.maxLines,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = style ?? DefaultTextStyle.of(context).style;
    final List<String> terms = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((String term) => term.isNotEmpty)
        .toList(growable: false);

    if (terms.isEmpty) {
      return Text(text, style: base, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }

    final TextStyle highlight = base.copyWith(
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
    );

    final String lower = text.toLowerCase();
    final List<TextSpan> spans = <TextSpan>[];
    var cursor = 0;

    while (cursor < text.length) {
      var bestStart = -1;
      var bestLength = 0;
      for (final String term in terms) {
        final int found = lower.indexOf(term.toLowerCase(), cursor);
        if (found >= 0 && (bestStart == -1 || found < bestStart)) {
          bestStart = found;
          bestLength = term.length;
        }
      }
      if (bestStart < 0) break;
      if (bestStart > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, bestStart), style: base));
      }
      spans.add(
        TextSpan(
          text: text.substring(bestStart, bestStart + bestLength),
          style: highlight,
        ),
      );
      cursor = bestStart + bestLength;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }

    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
