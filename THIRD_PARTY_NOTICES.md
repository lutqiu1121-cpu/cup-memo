# Third-Party Notices

Cup Memo 自有代码采用 GNU AGPL-3.0（根目录 `LICENSE`）。本文件列出实际使用的开源
组件、传递依赖、构建工具及其许可证。第三方组件仍保持各自原始许可证，不会因根目录
AGPL-3.0 而被重新许可。

## 审查结论

- `pubspec.lock` 当前锁定的全部包；未发现 GPL、LGPL 或 AGPL 第三方包。
- 主要许可证为 MIT、BSD-3-Clause、Apache-2.0；SQLite 本体为 Public Domain。
- 没有复制第三方 Dart/Flutter 源码；Agent、DAO、UI、tokenizer 与任务逻辑均为项目实现。
- `flutter_highlight` 未加入：其当前 pub 版本 SDK 约束为 `<3.0.0`，与 Dart 3.13 不兼容；没有将不可解析依赖写入项目。
- `assets/icon/app_icon.png` 是项目所有者提供的像素画素材，不是第三方开源依赖。

## 直接依赖与主动使用的工具

| 项目 | 上游链接 | License | 用途 |
| --- | --- | --- | --- |
| `crypto` `3.0.8` | [https://github.com/dart-lang/core/tree/main/pkgs/crypto](https://github.com/dart-lang/core/tree/main/pkgs/crypto) | BSD-3-Clause | content_hash SHA-256 |
| `cupertino_icons` `1.0.9` | [https://github.com/flutter/packages/tree/main/third_party/packages/cupertino_icons](https://github.com/flutter/packages/tree/main/third_party/packages/cupertino_icons) | MIT | 图标依赖 |
| `dartantic_ai` `3.4.2` | [https://pub.dev/packages/dartantic_ai](https://pub.dev/packages/dartantic_ai) | MIT | Agent、流式输出、思考与工具调用；底层依赖 openai_dart |
| `openai_dart` `7.0.0` | [https://pub.dev/packages/openai_dart](https://pub.dev/packages/openai_dart) | MIT | OpenAI-compatible API 与 ApiException 防御 |
| `dio` `5.11.1` | [https://github.com/cfug/dio/blob/main/dio](https://github.com/cfug/dio/blob/main/dio) | MIT | HTTP 客户端（Agent 内部也使用） |
| `flutter` `0.0.0` | [https://github.com/flutter/flutter](https://github.com/flutter/flutter) | BSD-3-Clause | Flutter SDK |
| `flutter_colorpicker` `1.1.0` | [https://github.com/mchome/flutter_colorpicker](https://github.com/mchome/flutter_colorpicker) | MIT | 颜色选择器 |
| `flutter_launcher_icons` `0.14.4` | [https://github.com/fluttercommunity/flutter_launcher_icons/](https://github.com/fluttercommunity/flutter_launcher_icons/) | MIT | 开发期 Android 图标生成 |
| `flutter_lints` `6.0.0` | [https://github.com/flutter/packages/tree/main/packages/flutter_lints](https://github.com/flutter/packages/tree/main/packages/flutter_lints) | BSD-3-Clause | 开发期 lint |
| `flutter_markdown` `0.7.7+1` | [https://github.com/flutter/packages/tree/main/packages/flutter_markdown](https://github.com/flutter/packages/tree/main/packages/flutter_markdown) | BSD-3-Clause | Markdown 渲染 |
| `flutter_riverpod` `3.5.0` | [https://github.com/rrousselGit/riverpod](https://github.com/rrousselGit/riverpod) | MIT | 状态管理 |
| `flutter_secure_storage` `10.3.4` | [https://github.com/mogol/flutter_secure_storage/tree/develop/flutter_secure_storage](https://github.com/mogol/flutter_secure_storage/tree/develop/flutter_secure_storage) | BSD-3-Clause | API Key 安全存储 |
| `flutter_test` `0.0.0` | [https://github.com/flutter/flutter](https://github.com/flutter/flutter) | BSD-3-Clause | Flutter 测试框架 |
| `markdown` `7.3.1` | [https://github.com/dart-lang/tools/tree/main/pkgs/markdown](https://github.com/dart-lang/tools/tree/main/pkgs/markdown) | BSD-3-Clause | Markdown AST 与代码块渲染 |
| `meta` `1.19.0` | [https://github.com/dart-lang/sdk/tree/main/pkg/meta](https://github.com/dart-lang/sdk/tree/main/pkg/meta) | BSD-3-Clause | 元数据注解 |
| `path` `1.9.1` | [https://github.com/dart-lang/core/tree/main/pkgs/path](https://github.com/dart-lang/core/tree/main/pkgs/path) | BSD-3-Clause | 路径处理 |
| `path_provider` `2.1.6` | [https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider](https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider) | BSD-3-Clause | 应用支持目录 |
| `shared_preferences` `2.5.6` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences) | BSD-3-Clause | 主题与搜索历史偏好 |
| `sqlite3` `2.9.4` | [https://github.com/simolus3/sqlite3.dart/tree/main/sqlite3](https://github.com/simolus3/sqlite3.dart/tree/main/sqlite3) | MIT | SQLite FFI 与手写 DAO |
| `sqlite3_flutter_libs` `0.5.42` | [https://github.com/simolus3/sqlite3.dart/tree/v2/sqlite3_flutter_libs](https://github.com/simolus3/sqlite3.dart/tree/v2/sqlite3_flutter_libs) | MIT | Android SQLite/FTS5 原生库 |

## 完整锁定依赖清单

以下覆盖 `pubspec.lock` 的全部包，包括测试、平台实现和传递依赖。

| Package | Version | Upstream | License | 用途 |
| --- | --- | --- | --- | --- |
| `archive` | `4.7.1` | [https://github.com/brendan-duncan/archive](https://github.com/brendan-duncan/archive) | MIT | Transitive dependency / platform support |
| `args` | `2.7.0` | [https://github.com/dart-lang/core/tree/main/pkgs/args](https://github.com/dart-lang/core/tree/main/pkgs/args) | BSD-3-Clause | Transitive dependency / platform support |
| `async` | `2.13.1` | [https://github.com/dart-lang/core/tree/main/pkgs/async](https://github.com/dart-lang/core/tree/main/pkgs/async) | BSD-3-Clause | Transitive dependency / platform support |
| `aws_common` | `0.7.16` | [https://github.com/aws-amplify/amplify-flutter/tree/main/packages/aws_common](https://github.com/aws-amplify/amplify-flutter/tree/main/packages/aws_common) | Apache-2.0 | Transitive dependency / platform support |
| `aws_signature_v4` | `0.6.13` | [https://github.com/aws-amplify/amplify-flutter/tree/main/packages/aws_signature_v4](https://github.com/aws-amplify/amplify-flutter/tree/main/packages/aws_signature_v4) | Apache-2.0 | Transitive dependency / platform support |
| `boolean_selector` | `2.1.2` | [https://github.com/dart-lang/tools/tree/main/pkgs/boolean_selector](https://github.com/dart-lang/tools/tree/main/pkgs/boolean_selector) | BSD-3-Clause | Transitive dependency / platform support |
| `built_collection` | `5.1.2` | [https://github.com/dart-lang/build/tree/master/built_types/built_collection](https://github.com/dart-lang/build/tree/master/built_types/built_collection) | BSD-3-Clause | Transitive dependency / platform support |
| `built_value` | `8.13.0` | [https://github.com/google/built_value.dart/tree/master/built_value](https://github.com/google/built_value.dart/tree/master/built_value) | BSD-3-Clause | Transitive dependency / platform support |
| `characters` | `1.4.1` | [https://github.com/dart-lang/core/tree/main/pkgs/characters](https://github.com/dart-lang/core/tree/main/pkgs/characters) | BSD-3-Clause | Transitive dependency / platform support |
| `checked_yaml` | `2.0.4` | [https://github.com/google/json_serializable.dart/tree/master/checked_yaml](https://github.com/google/json_serializable.dart/tree/master/checked_yaml) | BSD-3-Clause | Transitive dependency / platform support |
| `cli_util` | `0.4.2` | [https://github.com/dart-lang/tools/tree/main/pkgs/cli_util](https://github.com/dart-lang/tools/tree/main/pkgs/cli_util) | BSD-3-Clause | Transitive dependency / platform support |
| `clock` | `1.1.3` | [https://github.com/dart-lang/tools/tree/main/pkgs/clock](https://github.com/dart-lang/tools/tree/main/pkgs/clock) | Apache-2.0 | Transitive dependency / platform support |
| `collection` | `1.19.1` | [https://github.com/dart-lang/core/tree/main/pkgs/collection](https://github.com/dart-lang/core/tree/main/pkgs/collection) | BSD-3-Clause | Transitive dependency / platform support |
| `convert` | `3.1.2` | [https://github.com/dart-lang/core/tree/main/pkgs/convert](https://github.com/dart-lang/core/tree/main/pkgs/convert) | BSD-3-Clause | Transitive dependency / platform support |
| `crypto` | `3.0.8` | [https://github.com/dart-lang/core/tree/main/pkgs/crypto](https://github.com/dart-lang/core/tree/main/pkgs/crypto) | BSD-3-Clause | content_hash SHA-256 |
| `cupertino_icons` | `1.0.9` | [https://github.com/flutter/packages/tree/main/third_party/packages/cupertino_icons](https://github.com/flutter/packages/tree/main/third_party/packages/cupertino_icons) | MIT | 图标依赖 |
| `cupertino_ui` | `1.1.6` | [https://github.com/flutter/packages/tree/main/packages/cupertino_ui](https://github.com/flutter/packages/tree/main/packages/cupertino_ui) | BSD-3-Clause | Transitive dependency / platform support |
| `dartantic_ai` | `3.4.2` | [https://pub.dev/packages/dartantic_ai](https://pub.dev/packages/dartantic_ai) | MIT | Agent、流式输出、思考与工具调用 |
| `dio` | `5.11.1` | [https://github.com/cfug/dio/blob/main/dio](https://github.com/cfug/dio/blob/main/dio) | MIT | HTTP 客户端（Agent 内部也使用） |
| `dio_web_adapter` | `2.2.2` | [https://github.com/cfug/dio/blob/main/plugins/web_adapter](https://github.com/cfug/dio/blob/main/plugins/web_adapter) | MIT | Transitive dependency / platform support |
| `fake_async` | `1.3.3` | [https://github.com/dart-lang/test/tree/master/pkgs/fake_async](https://github.com/dart-lang/test/tree/master/pkgs/fake_async) | Apache-2.0 | Transitive dependency / platform support |
| `ffi` | `2.2.0` | [https://github.com/dart-lang/native/tree/main/pkgs/ffi](https://github.com/dart-lang/native/tree/main/pkgs/ffi) | BSD-3-Clause | Transitive dependency / platform support |
| `ffi_leak_tracker` | `0.1.2` | [https://github.com/halildurmus/win32/tree/main/packages/ffi_leak_tracker](https://github.com/halildurmus/win32/tree/main/packages/ffi_leak_tracker) | BSD-3-Clause | Transitive dependency / platform support |
| `file` | `7.0.1` | [https://github.com/dart-lang/tools/tree/main/pkgs/file](https://github.com/dart-lang/tools/tree/main/pkgs/file) | BSD-3-Clause | Transitive dependency / platform support |
| `fixnum` | `1.1.1` | [https://github.com/dart-lang/core/tree/main/pkgs/fixnum](https://github.com/dart-lang/core/tree/main/pkgs/fixnum) | BSD-3-Clause | Transitive dependency / platform support |
| `flutter` | `0.0.0` | [https://github.com/flutter/flutter](https://github.com/flutter/flutter) | BSD-3-Clause | Flutter SDK |
| `flutter_colorpicker` | `1.1.0` | [https://github.com/mchome/flutter_colorpicker](https://github.com/mchome/flutter_colorpicker) | MIT | 颜色选择器 |
| `flutter_launcher_icons` | `0.14.4` | [https://github.com/fluttercommunity/flutter_launcher_icons/](https://github.com/fluttercommunity/flutter_launcher_icons/) | MIT | 开发期 Android 图标生成 |
| `flutter_lints` | `6.0.0` | [https://github.com/flutter/packages/tree/main/packages/flutter_lints](https://github.com/flutter/packages/tree/main/packages/flutter_lints) | BSD-3-Clause | 开发期 lint |
| `flutter_localizations` | `0.0.0` | [https://pub.dev/packages/flutter_localizations](https://pub.dev/packages/flutter_localizations) | BSD-3-Clause | Transitive dependency / platform support |
| `flutter_markdown` | `0.7.7+1` | [https://github.com/flutter/packages/tree/main/packages/flutter_markdown](https://github.com/flutter/packages/tree/main/packages/flutter_markdown) | BSD-3-Clause | Markdown 渲染 |
| `flutter_riverpod` | `3.5.0` | [https://github.com/rrousselGit/riverpod](https://github.com/rrousselGit/riverpod) | MIT | 状态管理 |
| `flutter_secure_storage` | `10.3.4` | [https://github.com/mogol/flutter_secure_storage/tree/develop/flutter_secure_storage](https://github.com/mogol/flutter_secure_storage/tree/develop/flutter_secure_storage) | BSD-3-Clause | API Key 安全存储 |
| `flutter_secure_storage_darwin` | `0.3.2` | [https://pub.dev/packages/flutter_secure_storage_darwin](https://pub.dev/packages/flutter_secure_storage_darwin) | BSD-3-Clause | Transitive dependency / platform support |
| `flutter_secure_storage_linux` | `3.0.3` | [https://github.com/mogol/flutter_secure_storage](https://github.com/mogol/flutter_secure_storage) | BSD-3-Clause | Transitive dependency / platform support |
| `flutter_secure_storage_platform_interface` | `2.1.1` | [https://pub.dev/packages/flutter_secure_storage_platform_interface](https://pub.dev/packages/flutter_secure_storage_platform_interface) | BSD-3-Clause | Transitive dependency / platform support |
| `flutter_secure_storage_web` | `2.1.1` | [https://github.com/mogol/flutter_secure_storage](https://github.com/mogol/flutter_secure_storage) | BSD-3-Clause | Transitive dependency / platform support |
| `flutter_secure_storage_windows` | `4.2.2` | [https://github.com/mogol/flutter_secure_storage](https://github.com/mogol/flutter_secure_storage) | BSD-3-Clause | Transitive dependency / platform support |
| `flutter_test` | `0.0.0` | [https://github.com/flutter/flutter](https://github.com/flutter/flutter) | BSD-3-Clause | Flutter 测试框架 |
| `flutter_web_plugins` | `0.0.0` | [https://pub.dev/packages/flutter_web_plugins](https://pub.dev/packages/flutter_web_plugins) | BSD-3-Clause | Transitive dependency / platform support |
| `http` | `1.6.0` | [https://github.com/dart-lang/http/tree/master/pkgs/http](https://github.com/dart-lang/http/tree/master/pkgs/http) | BSD-3-Clause | Transitive dependency / platform support |
| `http2` | `2.3.1` | [https://github.com/dart-lang/http/tree/master/pkgs/http2](https://github.com/dart-lang/http/tree/master/pkgs/http2) | BSD-3-Clause | Transitive dependency / platform support |
| `http_parser` | `4.1.2` | [https://github.com/dart-lang/http/tree/master/pkgs/http_parser](https://github.com/dart-lang/http/tree/master/pkgs/http_parser) | BSD-3-Clause | Transitive dependency / platform support |
| `image` | `4.12.0` | [https://github.com/brendan-duncan/image](https://github.com/brendan-duncan/image) | MIT + bundled Apache-2.0/MIT notices | Transitive dependency / platform support |
| `intl` | `0.20.3` | [https://github.com/dart-lang/i18n/tree/main/pkgs/intl](https://github.com/dart-lang/i18n/tree/main/pkgs/intl) | BSD-3-Clause | Transitive dependency / platform support |
| `json_annotation` | `4.12.0` | [https://github.com/google/json_serializable.dart/tree/master/json_annotation](https://github.com/google/json_serializable.dart/tree/master/json_annotation) | BSD-3-Clause | Transitive dependency / platform support |
| `leak_tracker` | `11.0.2` | [https://github.com/dart-lang/leak_tracker/tree/main/pkgs/leak_tracker](https://github.com/dart-lang/leak_tracker/tree/main/pkgs/leak_tracker) | BSD-3-Clause | Transitive dependency / platform support |
| `leak_tracker_flutter_testing` | `3.0.10` | [https://github.com/dart-lang/leak_tracker/tree/main/pkgs/leak_tracker_flutter_testing](https://github.com/dart-lang/leak_tracker/tree/main/pkgs/leak_tracker_flutter_testing) | BSD-3-Clause | Transitive dependency / platform support |
| `leak_tracker_testing` | `3.0.2` | [https://github.com/dart-lang/leak_tracker/tree/main/pkgs/leak_tracker_testing](https://github.com/dart-lang/leak_tracker/tree/main/pkgs/leak_tracker_testing) | BSD-3-Clause | Transitive dependency / platform support |
| `lints` | `6.1.0` | [https://github.com/dart-lang/core/tree/main/pkgs/lints](https://github.com/dart-lang/core/tree/main/pkgs/lints) | BSD-3-Clause | Transitive dependency / platform support |
| `listen` | `1.0.1` | [https://github.com/flutter/core-packages/tree/main/packages/listen](https://github.com/flutter/core-packages/tree/main/packages/listen) | BSD-3-Clause | Transitive dependency / platform support |
| `logging` | `1.3.0` | [https://github.com/dart-lang/core/tree/main/pkgs/logging](https://github.com/dart-lang/core/tree/main/pkgs/logging) | BSD-3-Clause | Transitive dependency / platform support |
| `markdown` | `7.3.1` | [https://github.com/dart-lang/tools/tree/main/pkgs/markdown](https://github.com/dart-lang/tools/tree/main/pkgs/markdown) | BSD-3-Clause | Markdown AST 与代码块渲染 |
| `matcher` | `0.12.20` | [https://github.com/dart-lang/test/tree/master/pkgs/matcher](https://github.com/dart-lang/test/tree/master/pkgs/matcher) | BSD-3-Clause | Transitive dependency / platform support |
| `material_color_utilities` | `0.13.0` | [https://github.com/material-foundation/material-color-utilities/tree/main/dart](https://github.com/material-foundation/material-color-utilities/tree/main/dart) | Apache-2.0 | Transitive dependency / platform support |
| `material_ui` | `1.11.0` | [https://github.com/flutter/packages/tree/main/packages/material_ui](https://github.com/flutter/packages/tree/main/packages/material_ui) | BSD-3-Clause | Transitive dependency / platform support |
| `mcp_dart` | `2.4.3` | [https://github.com/leehack/mcp_dart](https://github.com/leehack/mcp_dart) | MIT | Transitive dependency / platform support |
| `meta` | `1.19.0` | [https://github.com/dart-lang/sdk/tree/main/pkg/meta](https://github.com/dart-lang/sdk/tree/main/pkg/meta) | BSD-3-Clause | 元数据注解 |
| `mime` | `2.1.0` | [https://github.com/dart-lang/tools/tree/main/pkgs/mime](https://github.com/dart-lang/tools/tree/main/pkgs/mime) | BSD-3-Clause | Transitive dependency / platform support |
| `os_detect` | `2.0.4` | [https://github.com/dart-lang/core/tree/main/pkgs/os_detect](https://github.com/dart-lang/core/tree/main/pkgs/os_detect) | BSD-3-Clause | Transitive dependency / platform support |
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
| `shared_preferences` | `2.5.6` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences) | BSD-3-Clause | 主题与搜索历史偏好 |
| `shared_preferences_android` | `2.4.15` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_android](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_android) | BSD-3-Clause | Transitive dependency / platform support |
| `shared_preferences_foundation` | `2.5.7` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_foundation](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_foundation) | BSD-3-Clause | Transitive dependency / platform support |
| `shared_preferences_linux` | `2.4.1` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_linux](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_linux) | BSD-3-Clause | Transitive dependency / platform support |
| `shared_preferences_platform_interface` | `2.4.2` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_platform_interface](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_platform_interface) | BSD-3-Clause | Transitive dependency / platform support |
| `shared_preferences_web` | `2.4.3` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_web](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_web) | BSD-3-Clause | Transitive dependency / platform support |
| `shared_preferences_windows` | `2.4.1` | [https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_windows](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences_windows) | BSD-3-Clause | Transitive dependency / platform support |
| `sky_engine` | `0.0.0` | [https://pub.dev/packages/sky_engine](https://pub.dev/packages/sky_engine) | BSD-3-Clause | Transitive dependency / platform support |
| `source_span` | `1.10.2` | [https://github.com/dart-lang/tools/tree/main/pkgs/source_span](https://github.com/dart-lang/tools/tree/main/pkgs/source_span) | BSD-3-Clause | Transitive dependency / platform support |
| `sqlite3` | `2.9.4` | [https://github.com/simolus3/sqlite3.dart/tree/main/sqlite3](https://github.com/simolus3/sqlite3.dart/tree/main/sqlite3) | MIT | SQLite FFI 与手写 DAO |
| `sqlite3_flutter_libs` | `0.5.42` | [https://github.com/simolus3/sqlite3.dart/tree/v2/sqlite3_flutter_libs](https://github.com/simolus3/sqlite3.dart/tree/v2/sqlite3_flutter_libs) | MIT | Android SQLite/FTS5 原生库 |
| `stack_trace` | `1.12.2` | [https://github.com/dart-lang/tools/tree/main/pkgs/stack_trace](https://github.com/dart-lang/tools/tree/main/pkgs/stack_trace) | BSD-3-Clause | Transitive dependency / platform support |
| `state_notifier` | `1.0.0` | [https://github.com/rrousselGit/state_notifier](https://github.com/rrousselGit/state_notifier) | MIT | Transitive dependency / platform support |
| `stream_channel` | `2.1.4` | [https://github.com/dart-lang/tools/tree/main/pkgs/stream_channel](https://github.com/dart-lang/tools/tree/main/pkgs/stream_channel) | BSD-3-Clause | Transitive dependency / platform support |
| `stream_transform` | `2.1.2` | [https://github.com/dart-lang/tools/tree/main/pkgs/stream_transform](https://github.com/dart-lang/tools/tree/main/pkgs/stream_transform) | BSD-3-Clause | Transitive dependency / platform support |
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
| Flutter SDK / Dart SDK | [flutter/flutter](https://github.com/flutter/flutter) | BSD-3-Clause（以随附 notices 为准） | 编译与运行 |
| Gradle 9.7.1 | [gradle/gradle](https://github.com/gradle/gradle) | Apache-2.0 | Android 构建编排 |
| Android Gradle Plugin 9.4.1 | [android/tools-base](https://android.googlesource.com/platform/tools/base) | Apache-2.0 / Android SDK 条款 | Android 打包 |
| Kotlin Gradle Plugin 2.4.20 | [JetBrains/kotlin](https://github.com/JetBrains/kotlin) | Apache-2.0 | Android 编译支持 |
| Android SDK / Build Tools / NDK | [developer.android.com](https://developer.android.com/studio/terms) | Android SDK License / Google 条款 | 构建 APK，不作为项目源码分发 |
| Pillow 13.0.0 | [python-pillow/Pillow](https://github.com/python-pillow/Pillow) | Pillow License | 本机图标转换工具，不进入 APK |

## 参考与复制情况

- 没有复制 flutter_riverpod、Flutter Material、Dio、SQLite 或 dartantic_ai 源码。
- Agent、工具、搜索、动态记忆、代码块复制、DAO 与 UI 均为本项目代码组合。
- App 图标使用项目所有者提供的像素画素材。

## 下游分发注意事项

1. 分发 APK 时保留本文件、`LICENSE`、Flutter 自动汇总 notices 与各依赖要求的版权文本。
2. AGPL-3.0 分发 APK 或提供网络服务时，应提供对应版本完整源码；远程交互需注意 AGPL 第 13 条。
3. Android SDK、签名密钥和用户 API Key 不等同于项目源码许可证，须分别管理。
4. 本表是工程级合规清单，不构成针对商业发行地域的法律意见。
