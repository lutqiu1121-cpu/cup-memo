import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';

/// App metadata and open-source compliance information.
class AboutLicensesPage extends StatelessWidget {
  const AboutLicensesPage({super.key});

  static const String repositoryUrl = 'https://github.com/lutqiu1121-cpu/cup-memo';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('开源许可与关于')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.local_cafe_outlined, size: 32),
                  ),
                  const SizedBox(height: 14),
                  Text('Cup Memo', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    '版本 0.1.0 · Android',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('AGPL-3.0'),
              subtitle: const Text(
                'Cup Memo 自有代码采用 GNU Affero General Public License v3.0',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLicenses(context),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.library_books_outlined),
              title: const Text('完整许可证列表'),
              subtitle: const Text('Flutter 自动汇总的第三方许可证与版权声明'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLicenses(context),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.source_outlined),
              title: const Text('GitHub 仓库'),
              subtitle: const Text(repositoryUrl),
              onTap: () async {
                await Clipboard.setData(
                  const ClipboardData(text: repositoryUrl),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('仓库地址已复制')),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          EmptyState(
            icon: Icons.verified_outlined,
            title: '分发提示',
            description: '分发 APK 或提供网络服务时，请同时提供对应版本源码、AGPL-3.0 文本和 '
                'THIRD_PARTY_NOTICES.md。',
            actionLabel: '查看完整许可证',
            onAction: () => _showLicenses(context),
          ),
        ],
      ),
    );
  }

  static void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Cup Memo',
      applicationVersion: '0.1.0',
    );
  }
}
