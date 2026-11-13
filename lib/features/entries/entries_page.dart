import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Tab 1 — memo entries (list + Markdown editor land in a later stage).
class EntriesPage extends StatelessWidget {
  const EntriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('备忘录'),
        actions: <Widget>[
          IconButton(
            tooltip: '新建备忘（待实现）',
            onPressed: () => showPendingSnackBar(context, '新建备忘'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          EmptyState(
            icon: Icons.menu_book_outlined,
            title: '还没有任何备忘',
            description: '条目列表、Markdown 编辑、标签与归档都会在后续阶段实现。\n'
                '当前版本只提供可编译的框架与页面骨架。',
            actionLabel: '新建备忘',
            onAction: () => showPendingSnackBar(context, '新建备忘'),
          ),
          const SizedBox(height: 16),
          const _UpcomingCard(),
        ],
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('本板块待实现的能力', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              '· entries 表 CRUD 与 Markdown 落盘（atomic_file）\n'
              '· entries_fts 写入与 cjk_tokenizer bigram 预处理\n'
              '· 标签 / 分类筛选与任务状态联动',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}
