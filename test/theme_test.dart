import 'package:cup_memo/core/theme/app_colors.dart';
import 'package:cup_memo/core/theme/app_theme.dart';
import 'package:cup_memo/core/theme/theme_controller.dart';
import 'package:cup_memo/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hex parsing accepts the documented formats', () {
    expect(AppColors.tryParseHex('#A8E6CF'), const Color(0xFFA8E6CF));
    expect(AppColors.tryParseHex('A8E6CF'), const Color(0xFFA8E6CF));
    expect(AppColors.tryParseHex('  #a8e6cf  '), const Color(0xFFA8E6CF));
    expect(AppColors.tryParseHex('#80A8E6CF'), const Color(0x80A8E6CF));
    expect(AppColors.tryParseHex('#FFF'), isNull);
    expect(AppColors.tryParseHex('not-a-colour'), isNull);
    expect(AppColors.normaliseHex('a8e6cf'), '#A8E6CF');
  });

  test('theme forces the off-white scaffold background and 16px cards', () {
    final ThemeData theme = AppTheme.build(AppColors.mint);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.cardTheme.color, AppColors.card);
    expect(theme.appBarTheme.backgroundColor, Colors.transparent);
    expect(
      theme.cardTheme.shape,
      isA<RoundedRectangleBorder>().having(
        (RoundedRectangleBorder shape) => shape.borderRadius,
        'borderRadius',
        BorderRadius.circular(AppTheme.cardRadius),
      ),
    );
  });

  test('theme controller persists and validates the seed colour', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer.test(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(themeControllerProvider).hex, '#FAF7F0');

    final bool ok = await container
        .read(themeControllerProvider.notifier)
        .setColor('#A8E6CF');
    expect(ok, isTrue);
    expect(container.read(themeControllerProvider).hex, '#A8E6CF');
    expect(prefs.getString(AppTheme.seedPrefsKey), '#A8E6CF');

    final bool invalid = await container
        .read(themeControllerProvider.notifier)
        .setColor('zzzzzz');
    expect(invalid, isFalse);
    expect(container.read(themeControllerProvider).hex, '#A8E6CF');

    await container.read(themeControllerProvider.notifier).resetToDefault();
    expect(container.read(themeControllerProvider).hex, '#FAF7F0');
  });
}
