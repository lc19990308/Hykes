<p align="center">
  <img src="app/branding/hykes-logo.png" width="128" height="128" alt="海斗宝典图标">
</p>

# 海斗宝典 · Hykes

面向极地大乱斗玩家的离线资料与手录对局助手。Android 和 iOS 客户端可浏览英雄、海克斯和装备，查看人工示例，保存收藏并手动记录当前对局。客户端自带演示数据，可按需连接 Spring Boot 内容服务。

| 模块 | 运行环境 | 文档 |
| --- | --- | --- |
| Android / iOS 客户端 | Flutter 3.50 / Dart 3.14 | [前端 README](app/README.md) |
| 数据包发布与下载 | Java 17 / Maven / Spring Boot | [后端 README](backend/README.md) |

初次体验可直接从 `app/` 运行 `flutter pub get` 和 `flutter run`。需要验证内容更新时，按后端文档启动服务，再为客户端设置 `HAIDOU_API_BASE_URL`。

本仓库的统计和推荐均为人工模拟示例。Hykes 是独立项目，与 Riot Games 及 ARAMKit 无官方关联。公开版本只使用原创启动图标和随附许可证的界面图标。第三方游戏图片和研究快照保留在本地。
