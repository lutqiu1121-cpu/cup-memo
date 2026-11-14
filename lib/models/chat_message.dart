import 'package:meta/meta.dart';

/// Who produced a [ChatMessage].
enum ChatRole {
  user('user'),
  assistant('assistant'),
  system('system');

  const ChatRole(this.wireName);

  final String wireName;

  static ChatRole fromWire(String value) {
    return ChatRole.values.firstWhere(
      (ChatRole role) => role.wireName == value,
      orElse: () => ChatRole.user,
    );
  }
}

/// A single message inside a chat session.
///
/// The model is provider agnostic: `role` + `content` is enough for the OpenAI
/// compatible, DeepSeek, Anthropic, Gemini and Ollama wire formats, which the
/// real clients (a later stage) will map themselves.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.providerId,
    this.model,
    this.parentId,
  });

  final String id;
  final String sessionId;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  /// Which provider produced the message, when it is an assistant message.
  final String? providerId;
  final String? model;
  final String? parentId;

  bool get isUser => role == ChatRole.user;

  Map<String, Object?> toRow() {
    return <String, Object?>{
      'id': id,
      'session_id': sessionId,
      'role': role.wireName,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'provider_id': providerId,
      'model': model,
      'parent_id': parentId,
    };
  }

  factory ChatMessage.fromRow(Map<String, Object?> row) {
    return ChatMessage(
      id: row['id'] as String? ?? '',
      sessionId: row['session_id'] as String? ?? '',
      role: ChatRole.fromWire(row['role'] as String? ?? 'user'),
      content: row['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      providerId: row['provider_id'] as String?,
      model: row['model'] as String?,
      parentId: row['parent_id'] as String?,
    );
  }

  /// Message shape accepted by the provider APIs.
  Map<String, String> toApiJson() {
    return <String, String>{'role': role.wireName, 'content': content};
  }
}
