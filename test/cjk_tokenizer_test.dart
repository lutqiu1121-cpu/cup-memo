import 'package:cup_memo/core/utils/cjk_tokenizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tokenizeForFts', () {
    test('splits a Chinese sentence into overlapping bigrams', () {
      expect(
        tokenizeForFts('备忘录索引设计'),
        '备忘 忘录 录索 索引 引设 设计',
      );
    });

    test('keeps ASCII words and digits verbatim', () {
      expect(tokenizeForFts('SQLite FTS5'), 'SQLite FTS5');
      expect(tokenizeForFts('v2 版本'), 'v2 版本');
    });

    test('mixed CJK + ASCII input is split per run', () {
      expect(
        tokenizeForFts('用 FTS5 做备忘录搜索'),
        '用 FTS5 做备 备忘 忘录 录搜 搜索',
      );
    });

    test('a single CJK character is kept as one token', () {
      expect(tokenizeForFts('茶'), '茶');
    });

    test('punctuation and whitespace act as separators', () {
      expect(tokenizeForFts('备忘，搜索。'), '备忘 搜索');
      expect(tokenizeForFts('  '), '');
      expect(tokenizeForFts(''), '');
    });

    test('tokenization is stable and reusable for queries', () {
      const String query = '备忘录索引设计';
      expect(tokenizeForFts(query), tokenizeForFts(query));
      expect(CjkTokenizer.tokenizeForFts(query).split(' ').length, 6);
    });

    test('isCjk recognises Han, kana and hangul', () {
      expect(CjkTokenizer.isCjk('备'.runes.first), isTrue);
      expect(CjkTokenizer.isCjk('あ'.runes.first), isTrue);
      expect(CjkTokenizer.isCjk('한'.runes.first), isTrue);
      expect(CjkTokenizer.isCjk('a'.runes.first), isFalse);
      expect(CjkTokenizer.isCjk('1'.runes.first), isFalse);
    });
  });
}
