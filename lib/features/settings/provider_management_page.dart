import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/app_providers.dart';
import '../../services/provider/provider_config.dart';
import 'provider_form_page.dart';

/// 服务商管理：添加、编辑、设为默认或删除。
class ProviderManagementPage extends ConsumerWidget {
  const ProviderManagementPage({super.key});

  Future<void> _openForm(
    BuildContext context, {
    ProviderConfig? existing,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ProviderFormPage(existing: existing),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProviderConfig config,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('删除服务商'),
        content: Text('确定删除「${config.name}」吗？其保存在安全存储中的 访问密钥也会一并删除。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(providerListProvider.notifier).remove(config.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('已删除 ${config.name}')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProviderListState state = ref.watch(providerListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('服务商管理')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('添加'),
      ),
      body: Builder(
        builder: (BuildContext context) {
          if (!state.databaseReady) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                EmptyState(
                  icon: Icons.storage_outlined,
                  title: '数据库不可用',
                  description: state.error ?? '无法打开本地数据库，服务商配置无法读写。',
                  actionLabel: '重试',
                  onAction: () =>
                      ref.read(providerListProvider.notifier).reload(),
                ),
              ],
            );
          }
          if (state.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                EmptyState(
                  icon: Icons.hub_outlined,
                  title: '还没有服务商',
                  description:
                      '支持 OpenAI 兼容、DeepSeek 官方、Anthropic、Gemini 与本地 Ollama。\n'
                      '添加后可设为默认，并在会话页随时切换。',
                  actionLabel: '添加第一家服务商',
                  onAction: () => _openForm(context),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final ProviderConfig config = state.items[index];
              return _ProviderTile(
                config: config,
                onEdit: () => _openForm(context, existing: config),
                onSetDefault: () async {
                  await ref
                      .read(providerListProvider.notifier)
                      .setDefault(config.id);
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text('已将 ${config.name} 设为默认服务商')),
                    );
                },
                onDelete: () => _confirmDelete(context, ref, config),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.config,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  final ProviderConfig config;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.hub_outlined, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          config.name,
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (config.isDefault) ...<Widget>[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.30,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('默认', style: theme.textTheme.labelSmall),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${config.kind.label} · ${config.defaultModel.isEmpty ? '未设置模型' : config.defaultModel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    config.baseUrl.isEmpty ? '（未填写接口地址）' : config.baseUrl,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: '更多操作',
              onSelected: (String value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                  case 'default':
                    onSetDefault();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'edit', child: Text('编辑')),
                if (!config.isDefault)
                  const PopupMenuItem<String>(
                    value: 'default',
                    child: Text('设为默认'),
                  ),
                const PopupMenuItem<String>(value: 'delete', child: Text('删除')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
