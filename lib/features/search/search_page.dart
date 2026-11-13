import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Tab 2 — search (FTS5 / provider fan-out land in a later stage).
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    FocusScope.of(context).unfocus();
    showPendingSnackBar(context, '搜索');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('搜索')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: const InputDecoration(
              hintText: '搜索备忘标题或正文…',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _search,
              icon: const Icon(Icons.manage_search),
              label: const Text('搜索'),
            ),
          ),
          const SizedBox(height: 16),
          EmptyState(
            icon: Icons.search_off_outlined,
            title: '搜索尚未接入',
            description: 'FTS5 查询、bigram 预处理与 SearchRegistry 的 fallback '
                '链路都在后续阶段实现，这里先给出静态布局。',
            actionLabel: '尝试搜索',
            onAction: _search,
          ),
        ],
      ),
    );
  }
}
