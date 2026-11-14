# RELEASE_GUIDE.md — Cup Memo 发布清单

本文件用于发布 Android APK、GitHub Release 或其他可下载构建物前的合规检查。

## Release Checklist

### 源码与版本

- [ ] Release commit 与 `pubspec.yaml` 版本号一致。
- [ ] `pubspec.lock` 已提交，构建可复现。
- [ ] GitHub Release 的说明中包含对应源码 commit 或源码压缩包链接。
- [ ] `main` 分支 CI 全绿，`flutter analyze`、`flutter test`、`flutter build apk --release` 均通过。
- [ ] Release artifact 与源码 commit 一一对应，并记录 SHA-256。

### AGPL-3.0

- [ ] APK/源码包中保留完整根目录 `LICENSE`（GNU AGPL-3.0）。
- [ ] README 明确写出 AGPL-3.0 和源码地址。
- [ ] Release 页面提供对应版本完整源码链接。
- [ ] 如果提供网络服务，检查 AGPL-3.0 第 13 条：远程交互用户应能获取运行版本的 Corresponding Source。
- [ ] 不把第三方依赖误标为 AGPL；第三方仍使用其原始许可证。

### 第三方许可证

- [ ] 保留 `THIRD_PARTY_NOTICES.md`。
- [ ] 检查 `pubspec.lock` 是否发生变化，并重新核对新增依赖的许可证。
- [ ] 保留 Flutter 自动生成/汇总的许可证页面。
- [ ] 分发 APK 时不删除第三方版权、许可证和 notices 资源。
- [ ] 检查 Android SDK、NDK、Build Tools 和 Gradle 的独立分发条款。

### 素材与品牌

- [ ] 确认 `assets/icon/app_icon.png` 的版权、商用和再分发授权。
- [ ] 确认第三方字体、图片、模型、提示词模板等新增素材的许可证。
- [ ] 不把用户密钥、Provider API Key、keystore、`local.properties` 或 `.env` 放入 Release。

### Android 发布

- [ ] 使用正式 release keystore，不使用 debug signing。
- [ ] 检查 `applicationId`、版本号、minSdk 和 targetSdk。
- [ ] 在 API 23、现代 Android 和 Android 13 自适应图标环境至少各验证一次。
- [ ] 检查 APK/AAB 签名、SHA-256 和 artifact 下载可用性。

## Recommended Release Notes

每个 Release 建议至少包含：

```text
Source commit: <full git SHA>
Source: https://github.com/lutqiu1121-cpu/cup-memo/tree/<tag>
License: GNU AGPL-3.0
Artifact SHA-256: <sha256>
Third-party notices: THIRD_PARTY_NOTICES.md
```

> 这是一份工程合规清单，不是针对具体法域的法律意见。正式商业发行前，建议对素材授权、APK 对应源码提供方式和 Android/Flutter notices 做法律复核。
