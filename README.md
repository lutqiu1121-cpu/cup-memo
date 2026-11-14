# Cup Memo ☕

一个本地优先（local-first）的备忘录 / 会话记录 Android 应用：记录、检索、与 AI 对话、把对话沉淀成任务与归档。

> **当前阶段：可编译的 APK 框架（Framework Skeleton）**
> 本阶段只交付“跑得起来的骨架”：页面结构、主题系统、多 Provider 配置与管理、
> 数据库建表、服务层接口与 stub。条目 CRUD、搜索实现、AI 真实调用、归档逻辑
> 均**未实现**，按钮会弹出「该板块待实现」的提示。

---

## 目录

- [功能现状](#功能现状)
- [技术栈](#技术栈)
- [目录结构](#目录结构)
- [架构说明](#架构说明)
- [环境要求](#环境要求)
- [如何运行](#如何运行)
- [如何配置 Provider](#如何配置-provider)
- [如何构建 APK](#如何构建-apk)
- [测试](#测试)
- [数据库与中文分词](#数据库与中文分词)
- [开源许可证说明](#开源许可证说明)
- [已知限制与 TODO](#已知限制与-todo)

---

## 功能现状

| 模块 | 状态 | 说明 |
| --- | --- | --- |
| 底部导航（备忘录 / 搜索 / 会话 / 任务 / 设置） | ✅ | 5 个 tab，切换正常，占位空状态 |
| 主题系统（分类预设色板 + 自定义 hex + 持久化） | ✅ | 背景固定米白 `#FAF7F0`，卡片白色圆角 16 |
| App 图标（极简咖啡杯 / 自适应图标） | ✅ | SVG 源 + 多密度 PNG，Android 13 自适应 + monochrome |
| Provider 管理（增删改、设默认、预设） | ✅ | 列表 / 添加 / 编辑 / 删除 / 设为默认，API Key 进安全存储 |
| 会话页 Provider 切换 | ✅ | 顶部显示当前 Provider，点击切换，仅影响后续消息 |
| 数据库建表（含 FTS5） | ✅ | schema version 1，`onUpgrade` 空实现 + 注释 |
| `cjk_tokenizer` bigram 预处理 | ✅ | 中英混排，写入 / 查询复用同一函数 |
| 条目 CRUD / Markdown 落盘 / 分类筛选 | ✅ | `EntryDao` 手写 SQL，正文原子写入 `entries/<id>.md` |
| 条目全文索引（FTS5 + bigram 同步） | ✅ | 写/改/删同步维护 `entries_fts`，`content_hash` 去重 |
| 搜索（FTS5 查询、SearchRegistry 实现） | ⛔ | 后续阶段，接口与 registry 已就位 |
| AI 真实调用（ProviderRouter 客户端） | ⛔ | `sendMessage` 抛 `UnimplementedError` |
| 任务 / 归档业务逻辑 | ⛔ | 后续阶段，`ArchiveService.archiveSession` 返回 `null` |

## 技术栈

| 领域 | 选型 |
| --- | --- |
| 框架 | Flutter stable（Android 为唯一目标平台） |
| 状态管理 | `flutter_riverpod`（`Notifier` / `NotifierProvider`） |
| 数据库 | `sqlite3` + `sqlite3_flutter_libs`，手写 DAO，**不使用 build_runner** |
| 网络 | `dio` |
| 密钥存储 | `flutter_secure_storage` |
| 本地偏好 | `shared_preferences` |
| Markdown | `flutter_markdown` |
| 颜色选择 | `flutter_colorpicker` |

> 本阶段**不引入** `llm_dart`、`flutter_chat_ui`。

## 目录结构

```text
lib/
  main.dart                     # 入口：初始化 prefs / database 并注入 ProviderScope
  app.dart                      # MaterialApp + 5 tab 的 HomeShell
  core/
    theme/
      app_colors.dart           # 固定色 + PresetTheme 分类色板 + hex 解析
      app_theme.dart            # ColorScheme.fromSeed + 米白背景/卡片/AppBar 规则
      theme_controller.dart     # ThemeController（Riverpod）持久化 seedColor
    db/
      database.dart             # AppDatabase：打开、建表、版本、onUpgrade 空实现
      schema.dart               # 全部建表 SQL（含 entries_fts）
      dao/provider_dao.dart     # 手写 DAO：providers 表 CRUD
      dao/entry_dao.dart        # 手写 DAO：entries + entries_fts 同步、去重、检索
    utils/
      cjk_tokenizer.dart        # 中文 bigram 预处理（写入/查询共用）
      atomic_file.dart          # 临时文件 + rename 的原子写入
      id.dart                   # 随机 TEXT 主键生成
    widgets/
      empty_state.dart          # 占位空状态卡片 + SnackBar 工具
  features/
    archive/archive_page.dart     # 归档占位页（设置 → 归档）
    entries/entries_page.dart     # 备忘录列表 + 新建/编辑页（EntryEditPage）
    search/search_page.dart
    chat/chat_page.dart
    tasks/tasks_page.dart
    settings/
      settings_page.dart
      provider_management_page.dart
      provider_form_page.dart
  services/
    provider/
      provider_config.dart      # ProviderConfig 模型 + ProviderKind
      provider_presets.dart     # 5 个内置预设
      provider_router.dart      # ProviderRouter + StubProviderClient
      api_key_store.dart        # flutter_secure_storage 封装
    search/
      search_provider.dart      # SearchProvider 接口
      search_registry.dart      # 注册 / 当前 provider / fallback 链
    archive_service.dart        # archiveSession -> null
  services/
    entry_service.dart          # 条目 + Markdown 文件的事务协调（EntryService）
  models/
    entry.dart  task.dart  chat_message.dart  search_result.dart
  providers/
    app_providers.dart          # 所有 Riverpod provider 的装配点
test/
  cjk_tokenizer_test.dart       # bigram 行为
  theme_test.dart               # hex 解析 / 主题规则 / 持久化
  widget_test.dart              # 5 tab 冒烟 + SnackBar
```

## 架构说明

```text
UI (features/*)  ──ref.watch/read──▶  providers/app_providers.dart
                                            │
                    ┌───────────────────────┼────────────────────────┐
                    ▼                       ▼                        ▼
             core/theme/*            core/db/*                 services/*
          (ThemeController)   (AppDatabase → ProviderDao)  (ProviderRouter /
                                                             ApiKeyStore /
                                                             SearchRegistry /
                                                             ArchiveService)
```

- **单一装配点**：所有 provider 集中在 `providers/app_providers.dart`，UI 不直接构造
  service / database。
- **同步优先**：`SharedPreferences` 与 `sqlite3` 在 `main()` 中完成初始化后注入
  `ProviderScope`，因此列表页无需 `FutureBuilder`，状态更新是同步的。
- **降级可用**：数据库打开失败时 `databaseProvider` 为 `null`，应用照常启动，只有
  Provider 管理页展示“数据库不可用”。
- **密钥边界**：`providers` 表只存 `api_key_ref`；真实 Key 写入
  `flutter_secure_storage`（`cup_memo.provider.api_key.<ref>`），永不落库、永不进日志。
- **会话隔离**：`currentProviderIdProvider` 只影响“后续消息”，`ProviderRouter` 由当前
  Provider 构造，历史消息模型与 Provider 无关。

## 环境要求

- Flutter stable（本项目在 Flutter 3.47.8 / Dart 3.13.7 上验证）
- JDK 17（AGP 需要）
- Android SDK：`platforms;android-37` + `build-tools;37.0.0`
- 设备 / 模拟器：Android 6.0（API 23）及以上

## 如何运行

```bash
flutter --version          # 确认 Flutter 可用
flutter pub get            # 拉取依赖
flutter devices            # 确认设备已连接
flutter run                # 直接运行到设备
```

只做静态检查：

```bash
flutter analyze
```

## 如何配置 Provider

1. 打开 **设置 → AI 与 Provider → Provider 管理**。
2. 点右下角 **添加**，选择预设：

   | 预设 | kind | baseUrl |
   | --- | --- | --- |
   | DeepSeek 官方 | `deepseek_native` | `https://api.deepseek.com` |
   | OpenRouter | `openai_compatible` | `https://openrouter.ai/api/v1` |
   | SiliconFlow 硅基流动 | `openai_compatible` | `https://api.siliconflow.cn/v1` |
   | Ollama 本地 | `ollama` | `http://127.0.0.1:11434/v1` |
   | 自定义 OpenAI 兼容 | `openai_compatible` | 自填 |

3. 填写 `baseUrl`、`API Key`、默认模型；如有需要可在「自定义 headers」里按
   `Key: Value` 每行一条填写（例如 OpenRouter 的 `HTTP-Referer`）。
4. 打开「设为默认 Provider」，保存。
5. 回到 **会话** tab，顶部会显示当前 Provider 名称；点击即可切换，**只影响后续消息**，
   已产生的历史不受影响。

> API Key 保存位置：`flutter_secure_storage`（Android Keystore）。
> 数据库 `providers.api_key_ref` 只保存一个随机引用 id。删除 Provider 时会一并删除 Key。
>
> 本阶段不会发起任何真实 API 请求；`ProviderRouter.createClient()` 返回
> `StubProviderClient`，`sendMessage` 抛 `UnimplementedError`。

## 如何构建 APK

```bash
flutter build apk --debug          # 调试包（本阶段验收用）
flutter build apk --release        # 发布包（当前用 debug 签名，见 android/app/build.gradle.kts）
```

产物路径：

```text
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-release.apk
```

APK 关键配置：

- `applicationId`: `com.cupmemo.app`
- `minSdk`: 23（见下方说明）
- `targetSdk` / `compileSdk`: 37
- `INTERNET` 权限已在 `AndroidManifest.xml` 声明
- 状态栏透明、图标深色，导航栏跟随米白 `#FAF7F0`

CI：`.github/workflows/build-apk.yml` 会在 push / PR 时执行
`pub get → analyze → test → build apk --release` 并上传 APK artifact。

CI 环境被显式钉住，避免滚动更新把构建打红：

- `runs-on: ubuntu-22.04`（而不是 `ubuntu-latest`）、`setup-java@v4` + `zulu` + JDK 17；
- `subosito/flutter-action@v2` 固定 `flutter-version: '3.47.8'`。Flutter 3.50 把 Material
  迁到了 `package:material_ui/material_ui.dart` 并把 `package:flutter/material.dart` 标记为
  废弃，会额外产生 16 条 info；
- analyze 只用 `flutter analyze --no-fatal-infos --no-fatal-warnings` 门禁 **error**，info /
  warning 不阻断流水线。

> **关于 minSdk 23**：Flutter 3.47 的 `flutter.minSdkVersion` 已经是 **24**，并且
> `MinSdkVersionMigration` 会把 `build.gradle.kts` 里字面量 `minSdk = 23` 改回
> `flutter.minSdkVersion`。为了真正产出 API 23 的包，本项目用命名常量
> `val cupMemoMinSdk = 23` 赋值，并把 `flutter_secure_storage` 钉在 10.x
> （11.x 声明 minSdk 24）、`path_provider_android` / `shared_preferences_android`
> 钉在声明 minSdk 21 的版本。构建时 Flutter 会给出一条 "minSdk 低于推荐值 24" 的
> 提示，但 `aapt2 dump badging` 中确认产物为 `minSdkVersion:'23'`。

### 在 Android / arm64 主机（Termux 类环境）上构建

本项目最初是在一台 **Android arm64 手机**的 Termux 类环境里完成验证的。如果你在同一类
环境里复现构建，除了装好 JDK 17 与 Android SDK（`platforms;android-37`、
`build-tools;37.0.0`）之外，还需要：

```bash
# 1) Flutter：官方不发布 Linux arm64 SDK，使用社区的原生 arm64 构建
export FLUTTER_ROOT="$HOME/opt/flutter-android-arm64/flutter"
export PATH="$FLUTTER_ROOT/bin:$JAVA_HOME/bin:$PATH"

# 2) Termux 的 JDK 把 user.home 编译死成了 /data/data/com.termux/files/home，
#    需要显式改回来，否则 Gradle 会在不存在的目录里下载发行版
export GRADLE_USER_HOME="$HOME/.gradle"
export JAVA_TOOL_OPTIONS="-Duser.home=$HOME -Djava.io.tmpdir=$HOME/tmp"

# 3) AGP 从 Maven 拉到的 aapt2 是 x86_64，跑不起来；指向本机的 arm64 aapt2
#    （写入 ~/.gradle/gradle.properties，不要写进仓库）
echo "android.aapt2FromMavenOverride=$PREFIX/bin/aapt2" >> ~/.gradle/gradle.properties

# 4) 构建 release 时 icon tree shaking 需要 glibc 版的 font-subset，arm64/bionic 主机上不可用
flutter build apk --release --no-tree-shake-icons
```

另外 `flutter test` 在这类主机上不可用：引擎自带的 `flutter_tester`
依赖系统私有库 `libbinder_ndk.so`，会直接崩溃。单元/Widget 测试请在 x86_64 的 CI 或
桌面环境里跑（本仓库的 GitHub Actions 就覆盖了这一步）。

> `ndkVersion` 与 `compileSdk` 在本仓库的 `android/app/build.gradle.kts` 中已固定，
> 无需额外设置。

## 测试

本地：

```bash
flutter analyze     # 0 issue
flutter test
```

覆盖内容：

- `cjk_tokenizer` 的 bigram 切分、英文数字保留、标点分隔
- hex 颜色解析 / 归一化、主题强制米白背景与 16px 圆角、seed 持久化
- 5 个 tab 渲染与切换、占位按钮的 SnackBar
- `EntryDao`（`test/entry_dao_test.dart`）：写入「备忘录索引设计」后，「索引」「备忘」
  均可命中；更新后旧词失效、新词命中；删除后 FTS 行同步清理；`content_hash` 去重

## 数据库与中文分词

- 数据库版本 1，表：`entries`、`entries_fts`（FTS5）、`current_tasks`、
  `history_tasks`、`chat_sessions`、`search_cache`、`providers`。
- `onUpgrade` 故意留空并带注释，等 schema 版本升级时按版本逐段补 `ALTER TABLE`。
- `entries_fts` **使用默认 tokenizer**，中文由 `cjk_tokenizer.tokenizeForFts()` 提前做
  bigram 切分：

  ```dart
  tokenizeForFts('备忘录索引设计');
  // => '备忘 忘录 录索 索引 引设 设计'
  ```

  写入与查询必须调用同一个函数，才能让两边的 token 流对齐；**不使用 trigram**。

## 预设色板

颜色不再写死在 UI 里，而是 `app_colors.dart` 中的 `PresetTheme` 数据：

```dart
class PresetTheme {
  final String name;      // 薄荷 / 蜜桃 …
  final String hex;       // '#A8E6CF'
  final String category;  // '马卡龙'，后续可加 '极简'、'莫兰迪'
}
```

- `AppColors.presetThemes` 是唯一数据源，`AppColors.presetsByCategory` 按分类分组；
- 设置页「预设色板」按分类渲染，新分类 / 新颜色只加数据，不改 UI；
- 颜色只作为 `ColorScheme.fromSeed` 的 seed，页面背景始终固定米白 `#FAF7F0`。

## App 图标

- 设计源：`assets/icon/cup_memo_icon.svg`（1024×1024，米白底、`#3A3A3A`
  等宽圆角线框、单缕热气、杯身浅灰填充 + 三层极淡椭圆投影）。
- 生成物：`assets/icon/cup_memo_icon.png`（传统图标）、`cup_memo_foreground.png`
  （自适应前景）、`cup_memo_monochrome.png`（Android 13 主题图标）。
- 配置在 `pubspec.yaml` 的 `flutter_launcher_icons` 段，重新生成：

  ```bash
  flutter pub run flutter_launcher_icons
  ```

  会写入 `mipmap-*dpi/ic_launcher.png`、`mipmap-anydpi-v26/ic_launcher.xml`
  （自适应：背景 `@color/ic_launcher_background` = `#FAF7F0`、前景 inset 16%、
  monochrome）与 `values/colors.xml`。
- 说明：本机没有可用的 SVG 光栅化器，PNG 由与本 SVG 几何一致的脚本按 4× 超采样
  烘焙，避免 SVG `filter`/`gradient` 在转 PNG 时丢失——阴影用三层半透明椭圆实现，
  不依赖滤镜。

## 条目与索引（EntryDao）

- 写入前先对 `title/body/tags/category` 做 `tokenizeForFts` bigram 预处理，然后
  **同一事务内**写 `entries` 与 `entries_fts`（`entries_fts.rowid = entries.rowid`）。
- 更新：先 `DELETE` 旧 FTS 行再插入新行，保证 token 流与内容一致；删除：先删 FTS
  行再删主表行。
- 去重：`content_hash = sha256(json[title, body, category, tags])`，命中已有行时
  返回 `EntryWriteOutcome.duplicate` 与已存在条目的 id，不产生重复数据。
- 正文落盘：`EntryService` 用 `atomic_file` 写入 `<support>/entries/<id>.md`，文件名
  与 `entries.md_path` 一致；DB 写入失败时回滚已写文件。
- 检索：`EntryDao.search()` 对查询词做同样的 bigram 预处理后 `MATCH`，供后续
  搜索页与 `SearchRegistry` 复用。
- UI：备忘录页支持新建 / 编辑 / 删除、分类筛选（全部 + 各分类）、标签展示。

## 开源许可证说明

- 本项目代码：**MIT**，见 [`LICENSE`](LICENSE)（版权年份与作者为占位符
  `<YEAR> <COPYRIGHT HOLDER>`，请按需替换）。
- 第三方组件许可证：见 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)。
- 运行时的完整许可证列表可在设备上通过 **设置 → 关于 → 开源许可** 查看
  （Flutter 的 `showLicensePage` 自动汇总）。

## 已知限制与 TODO

1. **其余业务逻辑未实现**：任务流转、会话归档、AI 调用；搜索页 UI 仍为占位
   （`EntryDao.search` 已可用，待接入 SearchRegistry 与搜索页）。
2. **AI 调用未实现**：`StubProviderClient.sendMessage` 抛 `UnimplementedError`；
   五种 `ProviderKind` 的请求 / 流式解析都待实现。
3. **搜索无具体实现**：`SearchRegistry` 为空，`search()` 返回空列表。
4. **`entries_fts` 由 DAO 手动同步**（未使用触发器）：所有写入都必须经过
   `EntryDao`，绕过它直接写 `entries` 表的 SQL 不会自动更新索引。
5. **依赖版本被有意钉住**（`dependency_overrides`）：
   - `sqlite3 ^2.9.4` + `sqlite3_flutter_libs ^0.5.39`：`sqlite3` 3.x 依赖 Dart native
     assets，而当前工具链的 Android 目标尚不支持；2.x + 0.5.x 由 AAR 内置带 FTS5 的
     SQLite。
   - `path_provider_foundation 2.5.1`、`shared_preferences_foundation 2.5.7`：避开
     `objective_c` 的 native-assets hook。
   - `flutter_secure_storage 10.3.4`：11.x 声明 minSdk 24，会把合并后的最低版本顶到 24。
  - `path_provider_android 2.2.18`、`shared_preferences_android 2.4.15`：更新版本要么通过
    `package:jni` 走 CMake/NDK 原生构建（arm64 构建机没有可运行的 x86_64 cmake），要么
    声明 minSdk 24。
   在标准 x86_64 构建机上这些钉住都可以移除。
6. **发布签名未配置**：release 包暂用 debug 签名，正式发布前需生成 keystore 并配置
   `key.properties`（已在 `.gitignore` 中忽略）。
7. **`THIRD_PARTY_NOTICES.md` 中的传递依赖**仍为 TODO，首次公开发布前需补齐。
