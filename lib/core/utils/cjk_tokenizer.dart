/// CJK-aware pre-tokeniser for SQLite FTS5.
///
/// The FTS5 table (`entries_fts`) uses the **default** (unicode61) tokenizer,
/// which treats a whole Chinese sentence as a single token. To get useful
/// Chinese matching, every CJK run is split into overlapping **bigrams**
/// before it is written to the index *and* before it is used in a `MATCH`
/// query — both sides must call [tokenizeForFts] so that the token streams
/// line up.
///
/// Example:
/// ```dart
/// tokenizeForFts('备忘录索引设计');
/// // => '备忘 忘录 录索 索引 引设 设计'
/// ```
///
/// ASCII letters/digits are kept verbatim (FTS5's unicode61 tokenizer is
/// case-insensitive for them), and every other character acts as a separator.
/// The trigram tokenizer is deliberately not used.
class CjkTokenizer {
  const CjkTokenizer._();

  /// Returns the whitespace separated FTS5 token stream for [input].
  static String tokenizeForFts(String input) {
    if (input.isEmpty) {
      return '';
    }
    final List<int> runes = input.runes.toList(growable: false);
    final StringBuffer buffer = StringBuffer();
    var index = 0;

    while (index < runes.length) {
      final int rune = runes[index];
      if (isCjk(rune)) {
        var end = index;
        while (end < runes.length && isCjk(runes[end])) {
          end++;
        }
        final int length = end - index;
        if (length == 1) {
          _append(buffer, String.fromCharCode(rune));
        } else {
          for (var i = index; i + 1 < end; i++) {
            _append(
              buffer,
              String.fromCharCodes(<int>[runes[i], runes[i + 1]]),
            );
          }
        }
        index = end;
      } else if (_isAsciiWord(rune)) {
        var end = index;
        while (end < runes.length && _isAsciiWord(runes[end])) {
          end++;
        }
        _append(buffer, String.fromCharCodes(runes.sublist(index, end)));
        index = end;
      } else {
        index++;
      }
    }
    return buffer.toString();
  }

  /// True for Han / Hiragana / Katakana / Hangul / CJK compatibility runes.
  static bool isCjk(int rune) {
    return (rune >= 0x3400 && rune <= 0x4DBF) || // CJK Unified Ext A
        (rune >= 0x4E00 && rune <= 0x9FFF) || // CJK Unified
        (rune >= 0xF900 && rune <= 0xFAFF) || // CJK Compatibility Ideographs
        (rune >= 0x3040 && rune <= 0x30FF) || // Hiragana + Katakana
        (rune >= 0xAC00 && rune <= 0xD7AF) || // Hangul syllables
        (rune >= 0x20000 && rune <= 0x2FA1F); // CJK Ext B..F, Compat. Suppl.
  }

  static bool _isAsciiWord(int rune) {
    return (rune >= 0x30 && rune <= 0x39) || // 0-9
        (rune >= 0x41 && rune <= 0x5A) || // A-Z
        (rune >= 0x61 && rune <= 0x7A); // a-z
  }

  static void _append(StringBuffer buffer, String token) {
    if (token.isEmpty) {
      return;
    }
    if (buffer.isNotEmpty) {
      buffer.write(' ');
    }
    buffer.write(token);
  }
}

/// Convenience shortcut for [CjkTokenizer.tokenizeForFts].
String tokenizeForFts(String input) => CjkTokenizer.tokenizeForFts(input);
