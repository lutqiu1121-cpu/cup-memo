import 'package:flutter/material.dart';

/// A named, categorised theme seed. Keeping presets as data rather than UI
/// literals makes it possible to add categories such as 极简 or 莫兰迪 later.
@immutable
class PresetTheme {
  const PresetTheme({
    required this.name,
    required this.hex,
    required this.category,
  });

  final String name;
  final String hex;
  final String category;

  Color get color => AppColors.tryParseHex(hex) ?? AppColors.defaultSeed;
}

/// Fixed background / foreground colours of Cup Memo.
class AppColors {
  const AppColors._();

  static const Color background = Color(0xFFFAF7F0);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF3A3A3A);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color defaultSeed = background;
  static const String defaultSeedHex = '#FAF7F0';

  static const Color mint = Color(0xFFA8E6CF);
  static const Color peach = Color(0xFFFFD3B6);
  static const Color lilac = Color(0xFFD4C1EC);
  static const Color cream = Color(0xFFFFF1B6);
  static const Color sky = Color(0xFFB5D8FF);
  static const Color lavender = Color(0xFFE0C3FC);
  static const Color sakura = Color(0xFFFFC8DD);

  /// All preset themes are data. UI should render this list by category.
  static const List<PresetTheme> presetThemes = <PresetTheme>[
    PresetTheme(name: '薄荷', hex: '#A8E6CF', category: '马卡龙'),
    PresetTheme(name: '蜜桃', hex: '#FFD3B6', category: '马卡龙'),
    PresetTheme(name: '淡紫', hex: '#D4C1EC', category: '马卡龙'),
    PresetTheme(name: '奶油', hex: '#FFF1B6', category: '马卡龙'),
    PresetTheme(name: '天空', hex: '#B5D8FF', category: '马卡龙'),
    PresetTheme(name: '薰衣草', hex: '#E0C3FC', category: '马卡龙'),
    PresetTheme(name: '樱花', hex: '#FFC8DD', category: '马卡龙'),
  ];

  static Map<String, List<PresetTheme>> get presetsByCategory {
    final Map<String, List<PresetTheme>> grouped = <String, List<PresetTheme>>{};
    for (final PresetTheme preset in presetThemes) {
      grouped.putIfAbsent(preset.category, () => <PresetTheme>[]).add(preset);
    }
    return grouped;
  }

  static Color? tryParseHex(String input) {
    var value = input.trim();
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length != 6 && value.length != 8) return null;
    final int? parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return null;
    return value.length == 8 ? Color(parsed) : Color(0xFF000000 | parsed);
  }

  static String normaliseHex(String input) {
    final Color? color = tryParseHex(input);
    return color == null ? defaultSeedHex : toHex(color);
  }

  static String toHex(Color color) {
    final int rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
