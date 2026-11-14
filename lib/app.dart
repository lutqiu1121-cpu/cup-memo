import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/chat/chat_page.dart';
import 'features/entries/entries_page.dart';
import 'features/search/search_page.dart';
import 'features/settings/settings_page.dart';
import 'features/tasks/tasks_page.dart';

final GlobalKey<ScaffoldState> appShellScaffoldKey = GlobalKey<ScaffoldState>();
const SystemUiOverlayStyle appOverlayStyle = SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark, statusBarBrightness: Brightness.light, systemNavigationBarColor: AppColors.background, systemNavigationBarIconBrightness: Brightness.dark, systemNavigationBarDividerColor: AppColors.background);

class CupMemoApp extends ConsumerWidget {
  const CupMemoApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeState theme = ref.watch(themeControllerProvider);
    return MaterialApp(
      title: 'Cup Memo', debugShowCheckedModeBanner: false,
      theme: AppTheme.build(theme.seedColor, brightness: theme.brightness, backgroundColor: theme.backgroundHex == null ? null : AppColors.tryParseHex(theme.backgroundHex!)),
      darkTheme: AppTheme.build(theme.seedColor, brightness: Brightness.dark, backgroundColor: theme.backgroundHex == null ? const Color(0xFF121212) : AppColors.tryParseHex(theme.backgroundHex!)),
      themeMode: theme.systemMode ? ThemeMode.system : (theme.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light),
      builder: (BuildContext context, Widget? child) => AnnotatedRegion<SystemUiOverlayStyle>(value: appOverlayStyle, child: GlassAdaptiveScope(minQuality: GlassQuality.minimal, maxQuality: theme.glassEnabled ? GlassQuality.standard : GlassQuality.minimal, child: child ?? const SizedBox.shrink())),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 2;
  final GlobalKey<ChatPageState> _chatKey = GlobalKey<ChatPageState>();
  List<Widget> get _pages => <Widget>[const EntriesPage(), const SearchPage(), ChatPage(key: _chatKey), const TasksPage(), const SettingsPage()];
  static const List<String> _labels = <String>['备忘录', '搜索', '会话', '任务', '设置'];
  static const List<IconData> _icons = <IconData>[Icons.menu_book_outlined, Icons.search, Icons.chat_bubble_outline, Icons.checklist_outlined, Icons.settings_outlined];

  void _select(int index) { Navigator.of(context).pop(); setState(() => _index = index); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appShellScaffoldKey,
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Consumer(builder: (BuildContext context, WidgetRef ref, Widget? _) {
          final bool glass = ref.watch(themeControllerProvider).glassEnabled;
          final Widget content = SafeArea(child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 20),
            children: <Widget>[
              const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text('Cup Memo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FilledButton.icon(
                  onPressed: () { Navigator.pop(context); setState(() => _index = 2); _chatKey.currentState?.startNewSession(); },
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Align(alignment: Alignment.centerLeft, child: Text('新建对话')),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                ),
              ),
              const Divider(),
              for (var i = 0; i < _labels.length; i++)
                ListTile(selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14), selectedColor: Theme.of(context).colorScheme.primary, leading: Icon(_icons[i]), title: Text(_labels[i]), selected: _index == i, onTap: () => _select(i)),
            ],
          ));
          return glass ? GlassContainer.card(padding: EdgeInsets.zero, child: content) : content;
        }),
      ),
      body: IndexedStack(index: _index, children: _pages),
    );
  }
}
