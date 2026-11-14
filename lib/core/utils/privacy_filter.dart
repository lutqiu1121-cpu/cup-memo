import 'dart:convert';

/// Lightweight privacy redaction before local search, exports, or AI prompts.
class PrivacyFilter {
  const PrivacyFilter._();

  static String redact(String input) {
    var value = input;
    value = value.replaceAll(RegExp(r'\bsk-[A-Za-z0-9_-]{12,}\b'), '[REDACTED_API_KEY]');
    value = value.replaceAll(RegExp(r'\bghp_[A-Za-z0-9]{20,}\b'), '[REDACTED_GITHUB_TOKEN]');
    value = value.replaceAll(RegExp(r'\bgithub_pat_[A-Za-z0-9_]{20,}\b'), '[REDACTED_GITHUB_TOKEN]');
    value = value.replaceAll(RegExp(r'bearer\s+[A-Za-z0-9._-]{12,}', caseSensitive: false), 'Bearer [REDACTED_TOKEN]');
    value = value.replaceAll(RegExp(r'\b(?:\d[ -]*?){13,19}\b'), '[REDACTED_CARD]');
    value = value.replaceAll(RegExp(r'(password|passwd|secret)\s*[:=]\s*[^\s]+', caseSensitive: false), r'\1=[REDACTED]');
    return value;
  }

  static String redactJson(Object? value) => redact(jsonEncode(value));
}
