import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/app_providers.dart';
import 'app_colors.dart';
import 'app_theme.dart';

/// Immutable state of the theme layer.
@immutable
class ThemeState {
  const ThemeState({required this.seedColor, required this.hex, this.brightness = Brightness.light, this.backgroundHex, this.systemMode = false});

  /// Seed colour used by [ThemeData] / `ColorScheme.fromSeed`.
  final Color seedColor;

  /// Normalised `#RRGGBB` of [seedColor].
  final String hex;
  final Brightness brightness;
  final String? backgroundHex;
  final bool systemMode;
  ThemeState copyWith({Color? seedColor, String? hex, Brightness? brightness, String? backgroundHex, bool? systemMode}) {
    return ThemeState(
      seedColor: seedColor ?? this.seedColor,
      hex: hex ?? this.hex,
      brightness: brightness ?? this.brightness,
      backgroundHex: backgroundHex ?? this.backgroundHex,
      systemMode: systemMode ?? this.systemMode,
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
    final bool dark = prefs.getBool('cup_memo.theme.dark') ?? false;
    final bool systemMode = prefs.getBool('cup_memo.theme.system') ?? false;
    final String? background = prefs.getString('cup_memo.theme.background');
    final Color? parsed = stored == null ? null : AppColors.tryParseHex(stored);
    if (parsed == null) {
      return ThemeState(
        seedColor: AppColors.defaultSeed,
        hex: AppColors.defaultSeedHex,
        brightness: dark ? Brightness.dark : Brightness.light,
        backgroundHex: background,
        systemMode: systemMode,
      );
    }
    return ThemeState(seedColor: parsed, hex: AppColors.toHex(parsed), brightness: dark ? Brightness.dark : Brightness.light, backgroundHex: background, systemMode: systemMode);
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
    state = state.copyWith(seedColor: parsed, hex: normalised);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(AppTheme.seedPrefsKey, normalised);
    return true;
  }

  /// Restores the default off-white (米白) seed.
  Future<bool> resetToDefault() => setColor(AppColors.defaultSeedHex);

  Future<void> setBrightness(Brightness brightness, {bool system = false}) async {
    state = state.copyWith(brightness: brightness, systemMode: system);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('cup_memo.theme.dark', brightness == Brightness.dark);
    await prefs.setBool('cup_memo.theme.system', system);
  }


  Future<void> setBackgroundHex(String? hex) async {
    state = state.copyWith(backgroundHex: hex);
    final prefs = ref.read(sharedPreferencesProvider);
    if (hex == null) {
      await prefs.remove('cup_memo.theme.background');
    } else {
      await prefs.setString('cup_memo.theme.background', hex);
    }
  }

  /// Applies one of the categorised preset themes.
  Future<bool> setPreset(PresetTheme preset) => setColor(preset.hex);
}

/// The single source of truth for the active seed colour.
final NotifierProvider<ThemeController, ThemeState> themeControllerProvider =
    NotifierProvider<ThemeController, ThemeState>(ThemeController.new);
