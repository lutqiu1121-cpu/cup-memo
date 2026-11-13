import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Tab 4 — tasks (current + history).
class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务'),
        actions: <Widget>[
          IconButton(
            tooltip: '新建任务（待实现）',
            onPressed: () => showPendingSnackBar(context, '新建任务'),
            icon: const Icon(Icons.add_task),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          EmptyState(
            icon: Icons.checklist_outlined,
            title: '当前没有进行中的任务',
            description: 'current_tasks 与 history_tasks 两张表已经建好，'
                '任务的创建、完成与归档将在后续阶段实现。',
            actionLabel: '新建任务',
            onAction: () => showPendingSnackBar(context, '新建任务'),
          ),
          const SizedBox(height: 16),
          const EmptyState(
            icon: Icons.history,
            title: '历史任务为空',
            description: '完成后的任务会出现在这里（history_tasks）。',
          ),
        ],
      ),
    );
  }
}
