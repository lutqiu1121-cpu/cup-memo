import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Builds the single light theme used by Cup Memo.
///
/// The seed colour is the only thing that changes when the user picks another
/// macaron colour: every surface keeps the fixed off-white background, the
/// cards stay white with a 16 px radius and a soft shadow, and the app bar is
/// fully transparent so the page background shows through.
class AppTheme {
  const AppTheme._();

  /// [SharedPreferences] key holding the selected seed colour as `#RRGGBB`.
  static const String seedPrefsKey = 'cup_memo.theme.seed_hex';

  static const double cardRadius = 16;

  static ThemeData build(Color seedColor, {Brightness brightness = Brightness.light, Color? backgroundColor}) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ).copyWith(surface: AppColors.card, onSurface: AppColors.textPrimary);

    final ThemeData base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final Color foreground = brightness == Brightness.dark ? Colors.white : AppColors.textPrimary;
    final TextTheme textTheme = base.textTheme
        .apply(bodyColor: foreground, displayColor: foreground)
        .copyWith(
          titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        );

    return base.copyWith(
      scaffoldBackgroundColor: backgroundColor ?? (brightness == Brightness.dark ? const Color(0xFF121212) : AppColors.background),
      canvasColor: backgroundColor ?? (brightness == Brightness.dark ? const Color(0xFF121212) : AppColors.background),
      colorScheme: scheme,
      textTheme: textTheme,
      brightness: brightness,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.dark ? const Color(0xFF1E1E1E) : AppColors.card,
        elevation: 2,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.dark ? const Color(0xFF1E1E1E) : AppColors.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: seedColor.withValues(alpha: 0.45),
        elevation: 2,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          return TextStyle(
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: _inputBorder(const Color(0xFFE6E0D4)),
        enabledBorder: _inputBorder(const Color(0xFFE6E0D4)),
        focusedBorder: _inputBorder(scheme.primary),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: Color(0xFFE0D9CB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: AppColors.card),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEDE7DA),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: brightness == Brightness.dark ? const Color(0xFF1E1E1E) : AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(cardRadius)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: brightness == Brightness.dark ? const Color(0xFF1E1E1E) : AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: brightness == Brightness.dark ? const Color(0xFF1E1E1E) : AppColors.card,
        side: const BorderSide(color: Color(0xFFE6E0D4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }
}
