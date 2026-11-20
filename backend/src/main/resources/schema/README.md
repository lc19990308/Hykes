# 模拟包校验

[demo-1.json](demo-1.json) 是 `schemaVersion=1` 的 JSON Schema。发布 CLI 在结构校验之后检查 ID/素材键唯一、跨清单引用闭合、模拟统计计数和模式隔离。拒绝发布的包不会切换 `latest`，错误记录到独立报告；不把无效计数改成 0。`--allow-broken-references` 只例外允许悬空引用，数据包不会进入公开目录。
