import 'dart:io';

/// Writes [contents] to [absolutePath] atomically.
///
/// The payload is first written to a sibling temporary file, flushed to disk
/// and only then `rename`d over the destination. Because `rename` is atomic on
/// the same filesystem, a crash mid-write can never leave a half-written
/// Markdown file behind — the destination keeps either its old or its new
/// content.
Future<void> writeStringAtomic(String absolutePath, String contents) async {
  final File destination = File(absolutePath);
  await destination.parent.create(recursive: true);

  final File temporary = File(
    '$absolutePath.tmp-${DateTime.now().microsecondsSinceEpoch}',
  );
  try {
    final RandomAccessFile handle = await temporary.open(mode: FileMode.write);
    try {
      await handle.writeString(contents);
      await handle.flush();
    } finally {
      await handle.close();
    }
    await temporary.rename(absolutePath);
  } catch (_) {
    if (await temporary.exists()) {
      await temporary.delete();
    }
    rethrow;
  }
}

/// Reads [absolutePath], returning `null` when the file does not exist.
Future<String?> readStringIfExists(String absolutePath) async {
  final File file = File(absolutePath);
  if (!await file.exists()) {
    return null;
  }
  return file.readAsString();
}
