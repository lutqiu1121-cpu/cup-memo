import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/app_providers.dart';
import '../../services/provider/provider_config.dart';
import '../settings/provider_management_page.dart';

/// Tab 3 — chat session (static layout, no API call in this stage).
///
/// The app bar always shows the provider that *will* handle the next message.
/// Tapping it switches providers for subsequent messages only; anything already
/// in the transcript stays untouched.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    FocusScope.of(context).unfocus();
    showPendingSnackBar(context, '发送消息');
  }

  Future<void> _pickProvider() async {
    final ProviderListState list = ref.read(providerListProvider);
    if (list.isEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const ProviderManagementPage(),
        ),
      );
      return;
    }

    final String? currentId = ref.read(activeProviderProvider)?.id;
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  '切换 Provider（仅影响后续消息）',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              for (final ProviderConfig item in list.items)
                ListTile(
                  leading: Icon(
                    currentId == item.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.kind.label} · ${item.defaultModel.isEmpty ? '未设置模型' : item.defaultModel}',
                  ),
                  trailing: item.isDefault
                      ? const Icon(Icons.star, size: 18)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(item.id),
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('管理 Provider…'),
                onTap: () => Navigator.of(sheetContext).pop('__manage__'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }
    if (selected == '__manage__') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const ProviderManagementPage(),
        ),
      );
      return;
    }
    ref.read(currentProviderIdProvider.notifier).select(selected);
    final ProviderConfig? picked = ref.read(activeProviderProvider);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('已切换到 ${picked?.name ?? selected}，仅影响后续消息')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ProviderConfig? active = ref.watch(activeProviderProvider);
    final bool usingDefault = ref.watch(currentProviderIdProvider) == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('会话'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: const Icon(Icons.hub_outlined, size: 16),
              label: Text(
                active == null ? '未配置 Provider' : active.name,
                style: const TextStyle(fontSize: 12),
              ),
              tooltip: '点击切换 Provider',
              onPressed: _pickProvider,
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _ProviderBanner(
            active: active,
            usingDefault: usingDefault,
            onTap: _pickProvider,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: <Widget>[
                if (active == null)
                  EmptyState(
                    icon: Icons.key_outlined,
                    title: '还没有可用的 Provider',
                    description: '先在「设置 → Provider 管理」里添加一条配置，'
                        '然后就能在这里选择它。',
                    actionLabel: '去配置 Provider',
                    onAction: _pickProvider,
                  )
                else
                  EmptyState(
                    icon: Icons.forum_outlined,
                    title: '会话尚未开始',
                    description: '当前 Provider：${active.name}\n'
                        '消息发送、流式输出与历史写入将在后续阶段实现。',
                    actionLabel: '发送一条示例消息',
                    onAction: _send,
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
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: '记点什么…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    tooltip: '发送',
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
          if (active != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '静态布局 · ${active.kind.label} · '
                '${active.defaultModel.isEmpty ? '默认模型未设置' : active.defaultModel}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProviderBanner extends StatelessWidget {
  const _ProviderBanner({
    required this.active,
    required this.usingDefault,
    required this.onTap,
  });

  final ProviderConfig? active;
  final bool usingDefault;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.hub_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  active == null
                      ? '未配置 Provider，点击前往设置'
                      : '当前 Provider：${active!.name}'
                          '${usingDefault ? '（默认）' : ''}',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.swap_horiz, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
