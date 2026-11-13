import 'package:flutter/material.dart';

/// Fixed background / foreground colours of Cup Memo.
///
/// The app deliberately keeps a paper-like "米白" (off-white) background in
/// every theme, no matter which macaron seed colour the user picks.
class AppColors {
  const AppColors._();

  /// Fixed page background (米白).
  static const Color background = Color(0xFFFAF7F0);

  /// Fixed card / surface colour.
  static const Color card = Color(0xFFFFFFFF);

  /// Primary text colour.
  static const Color textPrimary = Color(0xFF3A3A3A);

  /// Secondary / hint text colour.
  static const Color textSecondary = Color(0xFF8A8A8A);

  /// Default seed (also used by the "恢复默认米白" button).
  static const Color defaultSeed = background;
  static const String defaultSeedHex = '#FAF7F0';

  // ---- Macaron preset palette -------------------------------------------
  static const Color mint = Color(0xFFA8E6CF); // 薄荷
  static const Color peach = Color(0xFFFFD3B6); // 蜜桃
  static const Color lilac = Color(0xFFD4C1EC); // 淡紫
  static const Color cream = Color(0xFFFFF1B6); // 奶油
  static const Color sky = Color(0xFFB5D8FF); // 天空
  static const Color lavender = Color(0xFFE0C3FC); // 薰衣草
  static const Color sakura = Color(0xFFFFC8DD); // 樱花

  /// All selectable macaron presets, in display order.
  static const List<MacaronColor> macaronPalette = <MacaronColor>[
    MacaronColor(name: '薄荷', color: mint, hex: '#A8E6CF'),
    MacaronColor(name: '蜜桃', color: peach, hex: '#FFD3B6'),
    MacaronColor(name: '淡紫', color: lilac, hex: '#D4C1EC'),
    MacaronColor(name: '奶油', color: cream, hex: '#FFF1B6'),
    MacaronColor(name: '天空', color: sky, hex: '#B5D8FF'),
    MacaronColor(name: '薰衣草', color: lavender, hex: '#E0C3FC'),
    MacaronColor(name: '樱花', color: sakura, hex: '#FFC8DD'),
  ];

  /// Parses `#RRGGBB`, `RRGGBB`, `#AARRGGBB` or `AARRGGBB`.
  ///
  /// Returns `null` when the input is not a valid hex colour.
  static Color? tryParseHex(String input) {
    var value = input.trim();
    if (value.startsWith('#')) {
      value = value.substring(1);
    }
    if (value.length != 6 && value.length != 8) {
      return null;
    }
    final int? parsed = int.tryParse(value, radix: 16);
    if (parsed == null) {
      return null;
    }
    if (value.length == 8) {
      return Color(parsed);
    }
    return Color(0xFF000000 | parsed);
  }

  /// Normalises any accepted hex input to upper-case `#RRGGBB`.
  static String normaliseHex(String input) {
    final Color? color = tryParseHex(input);
    if (color == null) {
      return defaultSeedHex;
    }
    return toHex(color);
  }

  /// Formats a colour as upper-case `#RRGGBB` (alpha is dropped).
  static String toHex(Color color) {
    final int rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

/// A named macaron preset colour.
@immutable
class MacaronColor {
  const MacaronColor({
    required this.name,
    required this.color,
    required this.hex,
  });

  final String name;
  final Color color;
  final String hex;
}
