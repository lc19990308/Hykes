# content/ · 数据包发布目录（骨架占位，待方案评审后实现）

> 运行时**外部目录**（不随 jar 打包），存放版本化内容数据包与 latest 指针。方案见 [docs/技术方案.md](../docs/技术方案.md) 第 5 节。

## 约定

```
content/
├── latest.json                  # 指针文件：{ "datasetVersion": "demo-0.1" }，原子切换（写临时文件后 rename）
├── demo-0.1.json                # 数据包文件，与 ../原型图/data/demo-0.1.json 同构；发布后不可变
├── demo-0.1.sha256              # 校验和（sha256），发布校验通过后生成
└── reports/
    └── demo-0.1.report.json     # 发布校验报告（引用闭合、计数有效性、覆盖缺口），对齐 PRD R11
```

- 数据包版本命名 `{mode}-{主.次}`（如 `demo-0.1`）；发布前必须通过方案 5.2 的五项发布校验。
- 正常数据包不允许悬空引用。`--allow-broken-references` 允许将验收夹具写入 `fixtures/`，但不会进入 HTTP API，也不会更新 `latest`。
- **回滚**：使用 `--rollback <datasetVersion>` 检验旧包后原子切换 `latest.json`。不同版本可并存，同版本不可改写。
- 被拒绝的包只生成 `rejected/` 下的校验报告。首次发布与隔离目录参数见 [后端 README](../README.md)。
