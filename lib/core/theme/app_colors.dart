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

  /// All 50 preset themes, grouped by category.
  static const List<PresetTheme> presetThemes = <PresetTheme>[
    PresetTheme(name: '薄荷', hex: '#A8E6CF', category: '马卡龙'),
    PresetTheme(name: '蜜桃', hex: '#FFD3B6', category: '马卡龙'),
    PresetTheme(name: '淡紫', hex: '#D4C1EC', category: '马卡龙'),
    PresetTheme(name: '奶油', hex: '#FFF1B6', category: '马卡龙'),
    PresetTheme(name: '天空', hex: '#B5D8FF', category: '马卡龙'),
    PresetTheme(name: '薰衣草', hex: '#E0C3FC', category: '马卡龙'),
    PresetTheme(name: '樱花', hex: '#FFC8DD', category: '马卡龙'),
    PresetTheme(name: '海盐蓝', hex: '#98D8C8', category: '马卡龙'),
    PresetTheme(name: '豆沙绿', hex: '#A8BBA2', category: '莫兰迪'),
    PresetTheme(name: '雾霾蓝', hex: '#A2B5CD', category: '莫兰迪'),
    PresetTheme(name: '灰粉', hex: '#D4C4C4', category: '莫兰迪'),
    PresetTheme(name: '燕麦色', hex: '#D4C4B7', category: '莫兰迪'),
    PresetTheme(name: '远山灰', hex: '#B0B5B9', category: '莫兰迪'),
    PresetTheme(name: '玫瑰灰', hex: '#C4A4A4', category: '莫兰迪'),
    PresetTheme(name: '枯茶色', hex: '#8B7D6B', category: '莫兰迪'),
    PresetTheme(name: '浅驼色', hex: '#C19A6B', category: '莫兰迪'),
    PresetTheme(name: '纯黑', hex: '#1A1A1A', category: '极简'),
    PresetTheme(name: '深空灰', hex: '#333333', category: '极简'),
    PresetTheme(name: '曜石黑', hex: '#0A0A0A', category: '极简'),
    PresetTheme(name: '银灰', hex: '#C0C0C0', category: '极简'),
    PresetTheme(name: '极光白', hex: '#F5F5F5', category: '极简'),
    PresetTheme(name: '月白', hex: '#E8F0FE', category: '极简'),
    PresetTheme(name: '霁蓝', hex: '#4A6D8C', category: '国风'),
    PresetTheme(name: '胭脂', hex: '#9D2933', category: '国风'),
    PresetTheme(name: '竹青', hex: '#789262', category: '国风'),
    PresetTheme(name: '藤黄', hex: '#FFB61E', category: '国风'),
    PresetTheme(name: '黛紫', hex: '#574266', category: '国风'),
    PresetTheme(name: '朱砂', hex: '#FF461F', category: '国风'),
    PresetTheme(name: '青莲', hex: '#8D4BBB', category: '国风'),
    PresetTheme(name: '天水碧', hex: '#88ADA6', category: '国风'),
    PresetTheme(name: '丁香', hex: '#CCA4E3', category: '国风'),
    PresetTheme(name: '矩阵绿', hex: '#00FF00', category: '赛博'),
    PresetTheme(name: '霓虹紫', hex: '#9D00FF', category: '赛博'),
    PresetTheme(name: '赛博黄', hex: '#FFF000', category: '赛博'),
    PresetTheme(name: '终端蓝', hex: '#00BFFF', category: '赛博'),
    PresetTheme(name: '暗夜红', hex: '#8B0000', category: '赛博'),
    PresetTheme(name: '极光青', hex: '#00FFFF', category: '赛博'),
    PresetTheme(name: '故障粉', hex: '#FF00FF', category: '赛博'),
    PresetTheme(name: '珊瑚橘', hex: '#FF7F50', category: '自然'),
    PresetTheme(name: '草木绿', hex: '#228B22', category: '自然'),
    PresetTheme(name: '经典蓝', hex: '#0F4C81', category: '自然'),
    PresetTheme(name: '孔雀蓝', hex: '#008080', category: '自然'),
    PresetTheme(name: '琥珀', hex: '#FFBF00', category: '自然'),
    PresetTheme(name: '橄榄绿', hex: '#556B2F', category: '自然'),
    PresetTheme(name: '陶土红', hex: '#E2725B', category: '自然'),
    PresetTheme(name: '藏青蓝', hex: '#2E4A62', category: '自然'),
    PresetTheme(name: '落日橙', hex: '#FF8C00', category: '自然'),
    PresetTheme(name: '松石绿', hex: '#40E0D0', category: '自然'),
    PresetTheme(name: '勃艮第红', hex: '#800020', category: '自然'),
    PresetTheme(name: '香槟金', hex: '#F7E7CE', category: '自然'),
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
