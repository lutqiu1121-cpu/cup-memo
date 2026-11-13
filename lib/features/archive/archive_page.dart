import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Archive section.
///
/// Reached from **设置 → 归档**; it is not one of the five bottom tabs. The
/// archiving pipeline itself (`ArchiveService.archiveSession`) is a stub that
/// returns `null`, so this page only shows the placeholder state.
class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('归档')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          EmptyState(
            icon: Icons.inventory_2_outlined,
            title: '还没有归档内容',
            description: '会话归档（chat_sessions.archived）与 Markdown 导出的业务逻辑将在后续阶段实现，'
                '当前 ArchiveService.archiveSession 恒返回 null。',
            actionLabel: '尝试归档（待实现）',
            onAction: () => showPendingSnackBar(context, '归档'),
          ),
        ],
      ),
    );
  }
}
