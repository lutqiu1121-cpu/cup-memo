import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/db/database.dart';
import 'core/theme/app_colors.dart';
import 'providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw behind the system bars so the off-white background reaches the status
  // bar, and keep dark icons on it.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.background,
    ),
  );

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  AppDatabase? database;
  try {
    database = await AppDatabase.open();
    database.raw.execute(
      "DELETE FROM chat_messages WHERE content LIKE '%<script>%' OR content LIKE '%waf%'",
    );
  } catch (error, stackTrace) {
    // Degraded mode: the app still boots (5 tabs + settings), only the
    // provider screens report the missing database.
    debugPrint('Cup Memo: opening the database failed: $error\n$stackTrace');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(database),
      ],
      child: const CupMemoApp(),
    ),
  );
}
