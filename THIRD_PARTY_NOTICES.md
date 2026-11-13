# Third-Party Notices

Cup Memo is built on top of the following open-source projects. Each entry lists
the license declared by the upstream project. This file is a template — when the
dependency set changes, re-check the licenses and update the table.

| Component | Role in Cup Memo | Version constraint | License |
| --- | --- | --- | --- |
| [Flutter](https://flutter.dev) | UI framework / SDK | stable channel | BSD-3-Clause |
| [sqlite3](https://pub.dev/packages/sqlite3) (Dart bindings) | SQLite FFI bindings, hand-written DAO | `^2.9.4` | MIT |
| [sqlite3_flutter_libs](https://pub.dev/packages/sqlite3_flutter_libs) | Bundled native SQLite (FTS5 enabled) | `^0.5.39` | MIT |
| [SQLite](https://sqlite.org) (native library) | Storage engine, FTS5 virtual tables | bundled by sqlite3_flutter_libs | Public Domain |
| [dio](https://pub.dev/packages/dio) | HTTP client for provider calls | `^5.11.1` | MIT |
| [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) | State management | `^3.5.0` | MIT |
| [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) | API key storage (Android Keystore) | `^11.2.0` | BSD-3-Clause |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | Local preferences (theme seed colour) | `^2.5.6` | BSD-3-Clause |
| [flutter_markdown](https://pub.dev/packages/flutter_markdown) | Markdown rendering of entries | `^0.7.7` | BSD-3-Clause |
| [flutter_colorpicker](https://pub.dev/packages/flutter_colorpicker) | Colour picking helpers | `^1.1.0` | MIT |

## Transitive dependencies

The full transitive dependency tree is pinned in `pubspec.lock`; license texts
are generated per build by Flutter itself and can be inspected on device via
**设置 → 关于 → 开源许可**.

<!-- TODO: re-verify the license of every transitive dependency before the first
     public release, and replace this TODO with a generated list. -->

## Notes

- `sqlite3_flutter_libs 0.6.0+eol` is a tombstone release of the plugin for
  `sqlite3` 3.x. This project intentionally stays on `sqlite3` 2.x +
  `sqlite3_flutter_libs` 0.5.x, where the native library (built with FTS5) ships
  inside the plugin AAR instead of relying on Dart native assets.
- `LICENSE` in the repository root covers Cup Memo's own code (MIT).
