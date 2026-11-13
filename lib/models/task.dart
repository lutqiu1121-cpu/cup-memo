import 'package:flutter/foundation.dart';

/// Lifecycle of a task.
enum TaskStatus {
  /// Lives in `current_tasks`.
  current,

  /// Lives in `history_tasks`.
  completed,
}

/// A task, either still open (`current_tasks`) or completed
/// (`history_tasks`).
@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    this.detail = '',
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final String detail;
  final DateTime createdAt;
  final DateTime? completedAt;

  TaskStatus get status =>
      completedAt == null ? TaskStatus.current : TaskStatus.completed;

  bool get isCompleted => completedAt != null;

  Map<String, Object?> toCurrentRow() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'detail': detail,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, Object?> toHistoryRow() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'detail': detail,
      'completed_at': (completedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Task.fromCurrentRow(Map<String, Object?> row) {
    return Task(
      id: row['id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      detail: row['detail'] as String? ?? '',
      createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
    );
  }

  factory Task.fromHistoryRow(Map<String, Object?> row) {
    return Task(
      id: row['id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      detail: row['detail'] as String? ?? '',
      createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
      completedAt: _parseDate(row['completed_at']) ?? DateTime.now(),
    );
  }

  Task copyWith({String? title, String? detail, DateTime? completedAt}) {
    return Task(
      id: id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
