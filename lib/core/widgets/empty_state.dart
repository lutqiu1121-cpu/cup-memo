import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shows the standard "this section is not implemented yet" snack bar.
void showPendingSnackBar(BuildContext context, String module) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('「$module」该板块待实现')),
    );
}

/// Shared empty-state card used by every placeholder page.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Accent colour, defaults to the current seed colour.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accentColor = accent ?? theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...<Widget>[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
