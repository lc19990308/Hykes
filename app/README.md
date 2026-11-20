# 海斗宝典 · Flutter 客户端

面向 Android 和 iOS 的离线资料与手录对局助手。包含英雄、海克斯与装备检索、示例榜单、收藏和最近查看。对局助手由用户手动录入当前局，记录保存在本机。

## 开发与运行

需要 Flutter 3.50 / Dart 3.14、Android SDK 或 Xcode，以及一个模拟器或真机。从 `app/` 运行：

```sh
flutter pub get
flutter devices
flutter run
```

默认使用 `assets/data/demo-0.1.json`，首次离线打开即可浏览。统计和推荐为人工模拟示例，缺失统计会显示为「暂无统计」。

## 连接内容服务

按[后端运行说明](../backend/README.md)启动服务。Android 模拟器通过宿主机别名访问服务：

```sh
flutter run --dart-define=HAIDOU_API_BASE_URL=http://10.0.2.2:8080/api/v1
```

iOS 模拟器或本机联调可配置 `http://127.0.0.1:8080/api/v1`。Android 非调试构建要求 HTTPS。客户端启动时先显示已校验缓存或内置包，再后台检查最新版本，也可在「设置 → 更新中心」手动检查。数据包经过版本、字节数和 SHA-256 校验并写入本机后才会生效，失败时保留当前内容。

## 测试

```sh
flutter analyze
flutter test
```

服务启动后，可额外执行真实联调测试：

```sh
flutter test --dart-define=HAIDOU_API_BASE_URL=http://127.0.0.1:8080/api/v1 test/content_live_test.dart
```

## 目录与资源

- `lib/core/data/` 和 `lib/core/state/` 分别负责内容更新、本地数据与应用状态。
- `lib/features/` 包含各业务页面和对局助手。
- [原创 Logo](branding/hykes-logo.png)随源码提供，并已用作 Android 和 iOS 启动图标。调整设计后，可在安装 Pillow 的环境运行 `python3 branding/render_logo.py` 重新生成各分辨率图标。
- 界面图标的许可证见 [Lucide LICENSE](assets/icons/lucide/LICENSE)。公开版本中的游戏对象缺图时沿用页面现有占位。第三方游戏图片和研究快照未随仓库发布。
