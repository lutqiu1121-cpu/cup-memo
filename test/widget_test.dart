import 'package:cup_memo/app.dart';
import 'package:cup_memo/core/db/database.dart';
import 'package:cup_memo/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots with five tabs and switches between them',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final AppDatabase database = AppDatabase.inMemory();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(database),
        ],
        child: const CupMemoApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Five destinations exist in the bottom bar.
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final String label in <String>['备忘录', '搜索', '会话', '任务', '设置']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: '缺少底部导航「$label」',
      );
    }

    // The memo tab is the initial page.
    expect(find.text('还没有任何备忘'), findsOneWidget);

    // Switch to the settings tab and verify the theme controls are there.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('设置'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('预设色板'), findsOneWidget);
    expect(find.text('恢复默认米白'), findsOneWidget);

    // Switch to the chat tab: provider entry points must be visible.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('会话'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('未配置 Provider'), findsOneWidget);
  });

  testWidgets('chat shows the no-provider empty state',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppDatabase database = AppDatabase.inMemory();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(database),
        ],
        child: const CupMemoApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Chat is still a static layout: sending shows the placeholder snack bar.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('会话'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('还没有可用的 Provider'), findsOneWidget);
  });
}
