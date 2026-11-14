# Third-Party Notices

Cup Memo 本身使用 GNU AGPL-3.0（见根目录 `LICENSE`）。本文件记录实际依赖、构建工具、
生成工具及其上游来源。第三方组件**仍然保持各自的原始许可证**；根目录 AGPL-3.0 不会
把这些独立组件重新许可为 AGPL。

## 审查结论

- 锁定的 Dart/Flutter 依赖中未发现 GPL、LGPL 或 AGPL 组件。
- 发现的主要许可证：MIT、BSD-3-Clause、Apache-2.0；SQLite 本体为 Public Domain。
- 本仓库没有复制第三方 Dart/Flutter 源码；DAO、tokenizer、原子文件与 UI 均为本项目代码。
- `flutter_launcher_icons` 仅是开发期 MIT 工具；Pillow 仅用于本地图标转换，不进入 APK。
- `assets/icon/app_icon.svg` 与由其生成的 `app_icon.png` 是本项目原创图形，不是第三方依赖。
  `tool/render_app_icon.py` 只使用仓库内 SVG 几何与颜色参数生成 PNG；不再使用或提交外部图片素材。

## 直接依赖与主动使用的工具

| 项目 | GitHub / 上游链接 | License | 用途 |
| --- | --- | --- | --- |
| `crypto` `3.0.8` | [https://github.com/dart-lang/core/tree/main/pkgs/crypto](https://github.com/dart-lang/core/tree/main/pkgs/crypto) | BSD-3-Clause | content_hash SHA-256 |
| `cupertino_icons` `1.0.9` | [https://github.com/flutter/packages/tree/main/third_party/packages/cupertino_icons](https://github.com/flutter/packages/tree/main/third_party/packages/cupertino_icons) | MIT | 图标依赖 |
| `dio` `5.11.1` | [https://github.com/cfug/dio/blob/main/dio](https://github.com/cfug/dio/blob/main/dio) | MIT | HTTP 客户端骨架 |
| `flutter` `0.0.0` | [https://github.com/flutter/flutter](https://github.com/flutter/flutter) | BSD-3-Clause | Flutter SDK |
| `flutter_colorpicker` `1.1.0` | [https://github.com/mchome/flutter_colorpicker](https://github.com/mchome/flutter_colorpicker) | MIT | 颜色选择器依赖 |
| `flutter_launcher_icons` `0.14.4` | [https://github.com/fluttercommunity/flutter_launcher_icons/](https://github.com/fluttercommunity/flutter_launcher_icons/) | MIT | 开发期 Android 图标生成工具 |
| `flutter_lints` `6.0.0` | [https://github.com/flutter/packages/tree/main/packages/flutter_lints](https://github.com/flutter/packages/tree/main/packages/flutter_lints) | BSD-3-Clause | 开发期 lint 规则 |
| `flutter_markdown` `0.7.7+1` | [https://github.com/flutter/packages/tree/main/packages/flutter_markdown](https://github.com/flutter/packages/tree/main/packages/flutter_markdown) | BSD-3-Clause | Markdown 渲染依赖 |
| `flutter_riverpod` `3.5.0` | [https://github.com/rrousselGit/riverpod](https://github.com/rrousselGit/riverpod) | MIT | Riverpod 状态管理 |
| `flutter_secure_storage` `10.3.4` | [https://github.com/mogol/flutter_secure_storage/tree/develop/flutter_secure_storage](https://github.com/mogol/flutter_secure_storage/tree/develop/flutter_secure_storage) | BSD-3-Clause | Android Keystore API Key 存储 |
| `flutter_test` `0.0.0` | [https://github.com/flutter/flutter](https://github.com/flutter/flutter) | BSD-3-Clause | Flutter 测试框架 |
| `meta` `1.19.0` | [https://github.com/dart-lang/sdk/tree/main/pkg/meta](https://github.com/dart-lang/sdk/tree/main/pkg/meta) | BSD-3-Clause | 元数据注解 |
| `path` `1.9.1` | [https://github.com/dart-lang/core/tree/main/pkgs/path](https://github.com/dart-lang/core/tree/main/pkgs/path) | BSD-3-Clause | 路径处理 |
| `path_provider` `2.1.6` | [https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider](https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider) | BSD-3-Clause | 应用支持目录 |
| `shared_preferences` `2.5.6` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences) | BSD-3-Clause | 主题和搜索历史偏好 |
| `sqlite3` `2.9.4` | [https://github.com/simolus3/sqlite3.dart/tree/main/sqlite3](https://github.com/simolus3/sqlite3.dart/tree/main/sqlite3) | MIT | SQLite FFI 与手写 DAO |
| `sqlite3_flutter_libs` `0.5.42` | [https://github.com/simolus3/sqlite3.dart/tree/v2/sqlite3_flutter_libs](https://github.com/simolus3/sqlite3.dart/tree/v2/sqlite3_flutter_libs) | MIT | Android SQLite/FTS5 原生库 |

## 完整锁定依赖清单

下表覆盖 `pubspec.lock` 中的全部包，包括测试、平台实现和传递依赖。

| Package | Version | Upstream | License | 用途 |
| --- | --- | --- | --- | --- |
| `archive` | `4.7.1` | [https://github.com/brendan-duncan/archive](https://github.com/brendan-duncan/archive) | MIT + bundled MIT/Apache notices | Transitive dependency / platform support |
| `args` | `2.7.0` | [https://github.com/dart-lang/core/tree/main/pkgs/args](https://github.com/dart-lang/core/tree/main/pkgs/args) | BSD-3-Clause | Transitive dependency / platform support |
| `async` | `2.13.1` | [https://github.com/dart-lang/core/tree/main/pkgs/async](https://github.com/dart-lang/core/tree/main/pkgs/async) | BSD-3-Clause | Transitive dependency / platform support |
| `boolean_selector` | `2.1.2` | [https://github.com/dart-lang/tools/tree/main/pkgs/boolean_selector](https://github.com/dart-lang/tools/tree/main/pkgs/boolean_selector) | BSD-3-Clause | Transitive dependency / platform support |
| `characters` | `1.4.1` | [https://github.com/dart-lang/core/tree/main/pkgs/characters](https://github.com/dart-lang/core/tree/main/pkgs/characters) | BSD-3-Clause | Transitive dependency / platform support |
| `checked_yaml` | `2.0.4` | [https://github.com/google/json_serializable.dart/tree/master/checked_yaml](https://github.com/google/json_serializable.dart/tree/master/checked_yaml) | BSD-3-Clause | Transitive dependency / platform support |
| `cli_util` | `0.4.2` | [https://github.com/dart-lang/tools/tree/main/pkgs/cli_util](https://github.com/dart-lang/tools/tree/main/pkgs/cli_util) | BSD-3-Clause | Transitive dependency / platform support |
| `clock` | `1.1.3` | [https://github.com/dart-lang/tools/tree/main/pkgs/clock](https://github.com/dart-lang/tools/tree/main/pkgs/clock) | Apache-2.0 | Transitive dependency / platform support |
| `collection` | `1.19.1` | [https://github.com/dart-lang/core/tree/main/pkgs/collection](https://github.com/dart-lang/core/tree/main/pkgs/collection) | BSD-3-Clause | Transitive dependency / platform support |
| `crypto` | `3.0.8` | [https://github.com/dart-lang/core/tree/main/pkgs/crypto](https://github.com/dart-lang/core/tree/main/pkgs/crypto) | BSD-3-Clause | content_hash SHA-256 |
| `cupertino_icons` | `1.0.9` | [https://github.com/flutter/packages/tree/main/third_party/packages/cupertino_icons](https://github.com/flutter/packages/tree/main/third_party/packages/cupertino_icons) | MIT | 图标依赖 |
| `cupertino_ui` | `1.1.6` | [https://github.com/flutter/packages/tree/main/packages/cupertino_ui](https://github.com/flutter/packages/tree/main/packages/cupertino_ui) | BSD-3-Clause | Transitive dependency / platform support |
| `dio` | `5.11.1` | [https://github.com/cfug/dio/blob/main/dio](https://github.com/cfug/dio/blob/main/dio) | MIT | HTTP 客户端骨架 |
| `dio_web_adapter` | `2.2.2` | [https://github.com/cfug/dio/blob/main/plugins/web_adapter](https://github.com/cfug/dio/blob/main/plugins/web_adapter) | MIT | Transitive dependency / platform support |
| `fake_async` | `1.3.3` | [https://github.com/dart-lang/test/tree/master/pkgs/fake_async](https://github.com/dart-lang/test/tree/master/pkgs/fake_async) | Apache-2.0 | Transitive dependency / platform support |
| `ffi` | `2.2.0` | [https://github.com/dart-lang/native/tree/main/pkgs/ffi](https://github.com/dart-lang/native/tree/main/pkgs/ffi) | BSD-3-Clause | Transitive dependency / platform support |
| `ffi_leak_tracker` | `0.1.2` | [https://github.com/halildurmus/win32/tree/main/packages/ffi_leak_tracker](https://github.com/halildurmus/win32/tree/main/packages/ffi_leak_tracker) | BSD-3-Clause | Transitive dependency / platform support |
| `file` | `7.0.1` | [https://github.com/dart-lang/tools/tree/main/pkgs/file](https://github.com/dart-lang/tools/tree/main/pkgs/file) | BSD-3-Clause | Transitive dependency / platform support |
| `fixnum` | `1.1.1` | [https://github.com/dart-lang/core/tree/main/pkgs/fixnum](https://github.com/dart-lang/core/tree/main/pkgs/fixnum) | BSD-3-Clause | Transitive dependency / platform support |
| `flutter` | `0.0.0` | [https://github.com/flutter/flutter](https://github.com/flutter/flutter) | BSD-3-Clause | Flutter SDK |
| `flutter_colorpicker` | `1.1.0` | [https://github.com/mchome/flutter_colorpicker](https://github.com/mchome/flutter_colorpicker) | MIT | 颜色选择器依赖 |
| `flutter_launcher_icons` | `0.14.4` | [https://github.com/fluttercommunity/flutter_launcher_icons/](https://github.com/fluttercommunity/flutter_launcher_icons/) | MIT | 开发期 Android 图标生成工具 |
| `flutter_lints` | `6.0.0` | [https://github.com/flutter/packages/tree/main/packages/flutter_lints](https://github.com/flutter/packages/tree/main/packages/flutter_lints) | BSD-3-Clause | 开发期 lint 规则 |
| `flutter_localizations` | `0.0.0` | [https://github.com/flutter/flutter](https://github.com/flutter/flutter) | BSD-3-Clause | Transitive dependency / platform support |
| `flutter_markdown` | `0.7.7+1` | [https://github.com/flutter/packages/tree/main/packages/flutter_markdown](https://github.com/flutter/packages/tree/main/packages/flutter_markdown) | BSD-3-Clause | Markdown 渲染依赖 |
| `flutter_riverpod` | `3.5.0` | [https://github.com/rrousselGit/riverpod](https://github.com/rrousselGit/riverpod) | MIT | Riverpod 状态管理 |
| `flutter_secure_storage` | `10.3.4` | [https://github.com/mogol/flutter_secure_storage/tree/develop/flutter_secure_storage](https://github.com/mogol/flutter_secure_storage/tree/develop/flutter_secure_storage) | BSD-3-Clause | Android Keystore API Key 存储 |
| `flutter_secure_storage_darwin` | `0.3.2` | [https://github.com/juliansteenbakker/flutter_secure_storage](https://github.com/juliansteenbakker/flutter_secure_storage) | BSD-3-Clause | Transitive dependency / platform support |
| `flutter_secure_storage_linux` | `3.0.3` | [https://github.com/mogol/flutter_secure_storage](https://github.com/mogol/flutter_secure_storage) | BSD-3-Clause | Transitive dependency / platform support |
| `flutter_secure_storage_platform_interface` | `2.1.1` | [https://github.com/mogol/flutter_secure_storage](https://github.com/mogol/flutter_secure_storage) | BSD-3-Clause | Transitive dependency / platform support |
| `flutter_secure_storage_web` | `2.1.1` | [https://github.com/mogol/flutter_secure_storage](https://github.com/mogol/flutter_secure_storage) | BSD-3-Clause | Transitive dependency / platform support |
| `flutter_secure_storage_windows` | `4.2.2` | [https://github.com/mogol/flutter_secure_storage](https://github.com/mogol/flutter_secure_storage) | BSD-3-Clause | Transitive dependency / platform support |
| `flutter_test` | `0.0.0` | [https://github.com/flutter/flutter](https://github.com/flutter/flutter) | BSD-3-Clause | Flutter 测试框架 |
| `flutter_web_plugins` | `0.0.0` | [https://github.com/flutter/flutter](https://github.com/flutter/flutter) | BSD-3-Clause | Transitive dependency / platform support |
| `http_parser` | `4.1.2` | [https://github.com/dart-lang/http/tree/master/pkgs/http_parser](https://github.com/dart-lang/http/tree/master/pkgs/http_parser) | BSD-3-Clause | Transitive dependency / platform support |
| `image` | `4.12.0` | [https://github.com/brendan-duncan/image](https://github.com/brendan-duncan/image) | MIT + bundled Apache-2.0/MIT notices | Transitive dependency / platform support |
| `intl` | `0.20.3` | [https://github.com/dart-lang/i18n/tree/main/pkgs/intl](https://github.com/dart-lang/i18n/tree/main/pkgs/intl) | BSD-3-Clause | Transitive dependency / platform support |
| `json_annotation` | `4.12.0` | [https://github.com/google/json_serializable.dart/tree/master/json_annotation](https://github.com/google/json_serializable.dart/tree/master/json_annotation) | BSD-3-Clause | Transitive dependency / platform support |
| `leak_tracker` | `11.0.2` | [https://github.com/dart-lang/leak_tracker/tree/main/pkgs/leak_tracker](https://github.com/dart-lang/leak_tracker/tree/main/pkgs/leak_tracker) | BSD-3-Clause | Transitive dependency / platform support |
| `leak_tracker_flutter_testing` | `3.0.10` | [https://github.com/dart-lang/leak_tracker/tree/main/pkgs/leak_tracker_flutter_testing](https://github.com/dart-lang/leak_tracker/tree/main/pkgs/leak_tracker_flutter_testing) | BSD-3-Clause | Transitive dependency / platform support |
| `leak_tracker_testing` | `3.0.2` | [https://github.com/dart-lang/leak_tracker/tree/main/pkgs/leak_tracker_testing](https://github.com/dart-lang/leak_tracker/tree/main/pkgs/leak_tracker_testing) | BSD-3-Clause | Transitive dependency / platform support |
| `lints` | `6.1.0` | [https://github.com/dart-lang/core/tree/main/pkgs/lints](https://github.com/dart-lang/core/tree/main/pkgs/lints) | BSD-3-Clause | Transitive dependency / platform support |
| `listen` | `1.0.1` | [https://github.com/flutter/core-packages/tree/main/packages/listen](https://github.com/flutter/core-packages/tree/main/packages/listen) | BSD-3-Clause | Transitive dependency / platform support |
| `markdown` | `7.3.1` | [https://github.com/dart-lang/tools/tree/main/pkgs/markdown](https://github.com/dart-lang/tools/tree/main/pkgs/markdown) | BSD-3-Clause | Transitive dependency / platform support |
| `matcher` | `0.12.20` | [https://github.com/dart-lang/test/tree/master/pkgs/matcher](https://github.com/dart-lang/test/tree/master/pkgs/matcher) | BSD-3-Clause | Transitive dependency / platform support |
| `material_color_utilities` | `0.13.0` | [https://github.com/material-foundation/material-color-utilities/tree/main/dart](https://github.com/material-foundation/material-color-utilities/tree/main/dart) | Apache-2.0 | Transitive dependency / platform support |
| `material_ui` | `1.11.0` | [https://github.com/flutter/packages/tree/main/packages/material_ui](https://github.com/flutter/packages/tree/main/packages/material_ui) | BSD-3-Clause | Transitive dependency / platform support |
| `meta` | `1.19.0` | [https://github.com/dart-lang/sdk/tree/main/pkg/meta](https://github.com/dart-lang/sdk/tree/main/pkg/meta) | BSD-3-Clause | 元数据注解 |
| `mime` | `2.1.0` | [https://github.com/dart-lang/tools/tree/main/pkgs/mime](https://github.com/dart-lang/tools/tree/main/pkgs/mime) | BSD-3-Clause | Transitive dependency / platform support |
| `path` | `1.9.1` | [https://github.com/dart-lang/core/tree/main/pkgs/path](https://github.com/dart-lang/core/tree/main/pkgs/path) | BSD-3-Clause | 路径处理 |
| `path_provider` | `2.1.6` | [https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider](https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider) | BSD-3-Clause | 应用支持目录 |
| `path_provider_android` | `2.2.18` | [https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider_android](https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider_android) | BSD-3-Clause | Transitive dependency / platform support |
| `path_provider_foundation` | `2.5.1` | [https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider_foundation](https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider_foundation) | BSD-3-Clause | Transitive dependency / platform support |
| `path_provider_linux` | `2.2.2` | [https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider_linux](https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider_linux) | BSD-3-Clause | Transitive dependency / platform support |
| `path_provider_platform_interface` | `2.1.3` | [https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider_platform_interface](https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider_platform_interface) | BSD-3-Clause | Transitive dependency / platform support |
| `path_provider_windows` | `2.3.0` | [https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider_windows](https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider_windows) | BSD-3-Clause | Transitive dependency / platform support |
| `platform` | `3.2.0` | [https://github.com/dart-lang/core/tree/main/pkgs/platform](https://github.com/dart-lang/core/tree/main/pkgs/platform) | BSD-3-Clause | Transitive dependency / platform support |
| `plugin_platform_interface` | `2.1.8` | [https://github.com/flutter/packages/tree/main/packages/plugin_platform_interface](https://github.com/flutter/packages/tree/main/packages/plugin_platform_interface) | BSD-3-Clause | Transitive dependency / platform support |
| `posix` | `6.5.4` | [https://github.com/onepub-dev/dart_posix](https://github.com/onepub-dev/dart_posix) | MIT | Transitive dependency / platform support |
| `riverpod` | `3.5.0` | [https://github.com/rrousselGit/riverpod](https://github.com/rrousselGit/riverpod) | MIT | Transitive dependency / platform support |
| `shared_preferences` | `2.5.6` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences) | BSD-3-Clause | 主题和搜索历史偏好 |
| `shared_preferences_android` | `2.4.15` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_android](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_android) | BSD-3-Clause | Transitive dependency / platform support |
| `shared_preferences_foundation` | `2.5.7` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_foundation](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_foundation) | BSD-3-Clause | Transitive dependency / platform support |
| `shared_preferences_linux` | `2.4.1` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_linux](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_linux) | BSD-3-Clause | Transitive dependency / platform support |
| `shared_preferences_platform_interface` | `2.4.2` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_platform_interface](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_platform_interface) | BSD-3-Clause | Transitive dependency / platform support |
| `shared_preferences_web` | `2.4.3` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_web](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_web) | BSD-3-Clause | Transitive dependency / platform support |
| `shared_preferences_windows` | `2.4.1` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_windows](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_windows) | BSD-3-Clause | Transitive dependency / platform support |
| `sky_engine` | `0.0.0` | [https://github.com/flutter/flutter](https://github.com/flutter/flutter) | BSD-3-Clause | Transitive dependency / platform support |
| `source_span` | `1.10.2` | [https://github.com/dart-lang/tools/tree/main/pkgs/source_span](https://github.com/dart-lang/tools/tree/main/pkgs/source_span) | BSD-3-Clause | Transitive dependency / platform support |
| `sqlite3` | `2.9.4` | [https://github.com/simolus3/sqlite3.dart/tree/main/sqlite3](https://github.com/simolus3/sqlite3.dart/tree/main/sqlite3) | MIT | SQLite FFI 与手写 DAO |
| `sqlite3_flutter_libs` | `0.5.42` | [https://github.com/simolus3/sqlite3.dart/tree/v2/sqlite3_flutter_libs](https://github.com/simolus3/sqlite3.dart/tree/v2/sqlite3_flutter_libs) | MIT | Android SQLite/FTS5 原生库 |
| `stack_trace` | `1.12.2` | [https://github.com/dart-lang/tools/tree/main/pkgs/stack_trace](https://github.com/dart-lang/tools/tree/main/pkgs/stack_trace) | BSD-3-Clause | Transitive dependency / platform support |
| `state_notifier` | `1.0.0` | [https://github.com/rrousselGit/state_notifier](https://github.com/rrousselGit/state_notifier) | MIT | Transitive dependency / platform support |
| `stream_channel` | `2.1.4` | [https://github.com/dart-lang/tools/tree/main/pkgs/stream_channel](https://github.com/dart-lang/tools/tree/main/pkgs/stream_channel) | BSD-3-Clause | Transitive dependency / platform support |
| `string_scanner` | `1.4.1` | [https://github.com/dart-lang/tools/tree/main/pkgs/string_scanner](https://github.com/dart-lang/tools/tree/main/pkgs/string_scanner) | BSD-3-Clause | Transitive dependency / platform support |
| `term_glyph` | `1.2.2` | [https://github.com/dart-lang/tools/tree/main/pkgs/term_glyph](https://github.com/dart-lang/tools/tree/main/pkgs/term_glyph) | BSD-3-Clause | Transitive dependency / platform support |
| `test_api` | `0.7.12` | [https://github.com/dart-lang/test/tree/master/pkgs/test_api](https://github.com/dart-lang/test/tree/master/pkgs/test_api) | BSD-3-Clause | Transitive dependency / platform support |
| `typed_data` | `1.4.0` | [https://github.com/dart-lang/core/tree/main/pkgs/typed_data](https://github.com/dart-lang/core/tree/main/pkgs/typed_data) | BSD-3-Clause | Transitive dependency / platform support |
| `uuid` | `4.6.0` | [https://github.com/Daegalus/dart-uuid](https://github.com/Daegalus/dart-uuid) | MIT | Transitive dependency / platform support |
| `vector_math` | `2.4.0` | [https://github.com/flutter/core-packages/tree/main/packages/vector_math](https://github.com/flutter/core-packages/tree/main/packages/vector_math) | BSD-3-Clause | Transitive dependency / platform support |
| `vm_service` | `15.4.0` | [https://github.com/dart-lang/sdk/tree/main/pkg/vm_service](https://github.com/dart-lang/sdk/tree/main/pkg/vm_service) | BSD-3-Clause | Transitive dependency / platform support |
| `web` | `1.1.2` | [https://github.com/dart-lang/web](https://github.com/dart-lang/web) | BSD-3-Clause | Transitive dependency / platform support |
| `win32` | `6.4.0` | [https://github.com/halildurmus/win32](https://github.com/halildurmus/win32) | BSD-3-Clause | Transitive dependency / platform support |
| `xdg_directories` | `1.1.0` | [https://github.com/flutter/packages/tree/main/packages/xdg_directories](https://github.com/flutter/packages/tree/main/packages/xdg_directories) | BSD-3-Clause | Transitive dependency / platform support |
| `yaml` | `3.1.4` | [https://github.com/dart-lang/tools/tree/main/pkgs/yaml](https://github.com/dart-lang/tools/tree/main/pkgs/yaml) | MIT | Transitive dependency / platform support |

## Flutter / Android / Gradle 构建工具

| 工具 | 来源 | License / 条款 | 说明 |
| --- | --- | --- | --- |
| Flutter SDK / Dart SDK | [flutter/flutter](https://github.com/flutter/flutter) | BSD-3-Clause（各随附 notices 为准） | 编译和运行框架 |
| Gradle 9.7.1 | [gradle/gradle](https://github.com/gradle/gradle) | Apache-2.0 | Android 构建编排 |
| Android Gradle Plugin 9.4.1 | [android/tools-base](https://android.googlesource.com/platform/tools/base) | Apache-2.0 / Android SDK 条款 | Android 打包 |
| Kotlin Gradle Plugin 2.4.20 | [JetBrains/kotlin](https://github.com/JetBrains/kotlin) | Apache-2.0 | Android Gradle 编译支持 |
| Android SDK / Build Tools / NDK | [developer.android.com](https://developer.android.com/studio/terms) | Android SDK License / Google 条款 | 构建 APK，不作为项目源码分发 |
| Pillow 13.0.0 | [python-pillow/Pillow](https://github.com/python-pillow/Pillow) | Pillow License | 本机图标光栅化工具，不进入 APK |

## 参考与复制情况

- 没有复制 flutter_riverpod、Flutter Material、Dio、SQLite 或其他项目源码片段。
- UI、搜索高亮、任务列表、EntryDao、TaskDao、tokenizer、原子文件均为本项目实现。
- App 图标使用仓库内原创 SVG 几何稿与渲染脚本，不声明为第三方开源素材。

## 下游分发注意事项

1. 分发 APK 时保留本文件、`LICENSE`、Flutter 自动汇总的 notices，以及各依赖要求的版权/许可证文本。
2. AGPL-3.0 项目分发 APK 时应提供对应版本完整源码；若未来提供网络服务，还需注意 AGPL 第 13 条源码提供义务。
3. Android SDK、签名密钥和用户 API Key 不等同于项目源码许可证，须分别管理。
4. 本文件是工程级合规清单，不是法律意见；正式商业发布前建议律师复核素材授权、APK 源码提供方式及 Android/Flutter notices。
