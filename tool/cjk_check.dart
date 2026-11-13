// Local sanity check for the bigram tokenizer (not part of the app).
// Run with: dart run tool/cjk_check.dart
// ignore_for_file: avoid_print
import 'package:cup_memo/core/utils/cjk_tokenizer.dart';

void main() {
  const List<String> samples = <String>[
    '备忘录索引设计',
    'SQLite FTS5',
    'v2 版本',
    '用 FTS5 做备忘录搜索',
    '茶',
    '备忘，搜索。',
  ];
  for (final String sample in samples) {
    print('"$sample" -> "${tokenizeForFts(sample)}"');
  }
}
