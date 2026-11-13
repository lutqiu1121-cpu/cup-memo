import 'dart:math';

/// Generates a URL-safe random id (no external `uuid` dependency needed).
///
/// Entries, tasks, chat sessions and providers all use client generated TEXT
/// primary keys, so ids never depend on a server round-trip.
String newId([String prefix = '']) {
  final Random random = Random.secure();
  final StringBuffer buffer = StringBuffer();
  for (var i = 0; i < 16; i++) {
    buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  final String timestamp = DateTime.now().microsecondsSinceEpoch
      .toRadixString(36)
      .padLeft(8, '0');
  if (prefix.isEmpty) {
    return '$timestamp-$buffer';
  }
  return '$prefix-$timestamp-$buffer';
}

/// Ids for the append-only tables.
String newEntryId() => newId('entry');

String newTaskId() => newId('task');

String newSessionId() => newId('session');

String newMessageId() => newId('msg');

String newProviderId() => newId('provider');
