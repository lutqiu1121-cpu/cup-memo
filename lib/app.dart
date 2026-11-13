import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/chat/chat_page.dart';
import 'features/entries/entries_page.dart';
import 'features/search/search_page.dart';
import 'features/settings/settings_page.dart';
import 'features/tasks/tasks_page.dart';

/// Overlay style matching the fixed off-white background.
const SystemUiOverlayStyle appOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: AppColors.background,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarDividerColor: AppColors.background,
);

class CupMemoApp extends ConsumerWidget {
  const CupMemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeState theme = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: 'Cup Memo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(theme.seedColor),
      builder: (BuildContext context, Widget? child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: appOverlayStyle,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeShell(),
    );
  }
}

/// Root shell with the five bottom navigation tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const List<Widget> _pages = <Widget>[
    EntriesPage(),
    SearchPage(),
    ChatPage(),
    TasksPage(),
    SettingsPage(),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '备忘录',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '搜索',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '会话',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: '任务',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
