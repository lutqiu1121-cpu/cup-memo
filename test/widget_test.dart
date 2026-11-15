import 'package:cup_memo/app.dart';
import 'package:cup_memo/core/db/database.dart';
import 'package:cup_memo/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots into chat and navigates through the drawer',
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

    // The chat page is now the default home page.
    expect(find.text('还没有可用的服务商'), findsOneWidget);
    expect(find.byTooltip('菜单'), findsOneWidget);

    await tester.tap(find.byTooltip('菜单'));
    await tester.pumpAndSettle();
    expect(find.text('备忘录'), findsOneWidget);
    expect(find.text('搜索'), findsOneWidget);
    expect(find.text('任务'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);

    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    expect(find.text('预设色板'), findsOneWidget);
    expect(find.text('恢复默认米白'), findsOneWidget);

    await tester.tap(find.byTooltip('菜单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('备忘录').last);
    await tester.pumpAndSettle();
    expect(find.text('还没有任何备忘'), findsOneWidget);
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

    expect(find.text('还没有可用的服务商'), findsOneWidget);
    expect(find.byTooltip('新建对话'), findsOneWidget);
  });
}
