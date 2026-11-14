import 'package:flutter/material.dart';

import '../../app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/app_providers.dart';
import '../../services/provider/provider_config.dart';
import '../archive/archive_page.dart';
import 'provider_management_page.dart';
import 'about_licenses_page.dart';
import 'github_settings_page.dart';

/// Tab 5 — settings: theme (fully implemented) + provider management entry.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final TextEditingController _hexController = TextEditingController();

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Future<void> _applyCustomHex() async {
    final String input = _hexController.text.trim();
    if (input.isEmpty) {
      showPendingSnackBar(context, '自定义颜色');
      return;
    }
    final bool ok = await ref.read(themeControllerProvider.notifier).setColor(input);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok ? '已应用自定义颜色 ${AppColors.normaliseHex(input)}' : '颜色格式无效，请使用 #RRGGBB',
          ),
        ),
      );
    if (ok) {
      _hexController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _resetTheme() async {
    await ref.read(themeControllerProvider.notifier).resetToDefault();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('已恢复默认米白背景色')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ThemeState themeState = ref.watch(themeControllerProvider);
    final ProviderListState providers = ref.watch(providerListProvider);
    final ProviderConfig? defaultProvider = providers.defaultProvider;

    return Scaffold(
      appBar: AppBar(leading: IconButton(tooltip: '菜单', icon: const Icon(Icons.menu), onPressed: () => appShellScaffoldKey.currentState?.openDrawer()), title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: <Widget>[
          _SectionLabel(text: '主题外观'),
          const SizedBox(height: 8),
          _ThemePreview(seed: themeState.seedColor),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('预设色板', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '选中的颜色只作为 seed color，页面背景始终固定为米白 #FAF7F0。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final MapEntry<String, List<PresetTheme>> group
                          in AppColors.presetsByCategory.entries) ...<Widget>[
                        Text(
                          group.key,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            for (final PresetTheme preset in group.value)
                              _SwatchButton(
                                preset: preset,
                                selected: themeState.hex == preset.hex,
                                onTap: () => ref
                                    .read(themeControllerProvider.notifier)
                                    .setPreset(preset),
                              ),
                          ],
                        ),
                        if (group.key !=
                            AppColors.presetsByCategory.keys.last)
                          const SizedBox(height: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('自定义颜色', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _hexController,
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (_) => _applyCustomHex(),
                          decoration: const InputDecoration(
                            hintText: '#RRGGBB',
                            prefixIcon: Icon(Icons.palette_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _applyCustomHex,
                        child: const Text('应用'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '当前 seed：${themeState.hex}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _resetTheme,
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: const Text('恢复默认米白'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel(text: 'AI 与 Provider'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.hub_outlined),
              title: const Text('Provider 管理'),
              subtitle: Text(
                defaultProvider == null
                    ? '尚未配置 Provider'
                    : '默认：${defaultProvider.name} · ${defaultProvider.kind.label}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) =>
                      const ProviderManagementPage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.code),
              title: const Text('GitHub 集成'),
              subtitle: const Text('安全保存 Personal Access Token，供 Agent 文件工具使用'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const GitHubSettingsPage()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('归档'),
              subtitle: const Text('已归档的会话（待实现）'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const ArchivePage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel(text: '关于'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                const ListTile(
                  leading: Icon(Icons.local_cafe_outlined),
                  title: Text('Cup Memo'),
                  subtitle: Text('版本 0.1.0 · 框架版本（业务逻辑待实现）'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.verified_outlined),
                  title: const Text('开源许可与关于'),
                  subtitle: const Text('AGPL-3.0 · Cup Memo 0.1.0 · GitHub'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          const AboutLicensesPage(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.library_books_outlined),
                  title: const Text('Flutter 系统许可证'),
                  subtitle: const Text('查看 Flutter 自动汇总的第三方许可证'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Cup Memo',
                    applicationVersion: '0.1.0',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

/// Live preview card: fixed off-white page, white card, seed coloured accents.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.seed});

  final Color seed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '实时预览',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: seed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_cafe_outlined,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('卡片标题示例', style: theme.textTheme.titleSmall),
                      ),
                      Chip(
                        label: Text(
                          'seed',
                          style: theme.textTheme.labelSmall,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '背景固定米白 #FAF7F0，卡片白色、圆角 16、阴影柔和；'
                    '主色由所选 seed 生成。',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      FilledButton(
                        onPressed: () {},
                        child: const Text('主按钮'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('次按钮'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final PresetTheme preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: preset.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.textPrimary : const Color(0xFFE6E0D4),
                width: selected ? 2 : 1,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 20, color: AppColors.textPrimary)
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            preset.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ],
      ),
    );
  }
}
