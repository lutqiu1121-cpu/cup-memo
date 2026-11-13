import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/app_providers.dart';
import 'app_colors.dart';
import 'app_theme.dart';

/// Immutable state of the theme layer.
@immutable
class ThemeState {
  const ThemeState({required this.seedColor, required this.hex});

  /// Seed colour used by [ThemeData] / `ColorScheme.fromSeed`.
  final Color seedColor;

  /// Normalised `#RRGGBB` of [seedColor].
  final String hex;

  ThemeState copyWith({Color? seedColor, String? hex}) {
    return ThemeState(
      seedColor: seedColor ?? this.seedColor,
      hex: hex ?? this.hex,
    );
  }
}

/// Holds the currently selected seed colour and persists it to
/// [SharedPreferences].
class ThemeController extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
    final String? stored = prefs.getString(AppTheme.seedPrefsKey);
    final Color? parsed = stored == null ? null : AppColors.tryParseHex(stored);
    if (parsed == null) {
      return const ThemeState(
        seedColor: AppColors.defaultSeed,
        hex: AppColors.defaultSeedHex,
      );
    }
    return ThemeState(seedColor: parsed, hex: AppColors.toHex(parsed));
  }

  /// Applies [hex] (`#RRGGBB`, `RRGGBB`, …) and persists it.
  ///
  /// Returns `false` when [hex] is not a valid colour, in which case the state
  /// is left untouched.
  Future<bool> setColor(String hex) async {
    final Color? parsed = AppColors.tryParseHex(hex);
    if (parsed == null) {
      return false;
    }
    final String normalised = AppColors.toHex(parsed);
    state = ThemeState(seedColor: parsed, hex: normalised);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(AppTheme.seedPrefsKey, normalised);
    return true;
  }

  /// Restores the default off-white (米白) seed.
  Future<bool> resetToDefault() => setColor(AppColors.defaultSeedHex);

  /// Applies one of the macaron presets.
  Future<bool> setPreset(MacaronColor preset) => setColor(preset.hex);
}

/// The single source of truth for the active seed colour.
final NotifierProvider<ThemeController, ThemeState> themeControllerProvider =
    NotifierProvider<ThemeController, ThemeState>(ThemeController.new);
