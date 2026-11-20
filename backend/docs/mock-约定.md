# 海斗宝典 · 前后端 Mock 约定（前端先行 · 契约冻结稿 v1.0）

日期：2026-11-20
地位：本文件是 [技术方案 §3 接口设计](技术方案.md) 的**前端可执行契约版**。后端尚处骨架（B0 之前），前端先按本文档 mock 开发；后端 B1 落地后**仅切换 base URL，契约零变更**。
口径来源：`../原型图/data/demo-0.1.json`（唯一 mock 数据包，原样字节）· 真实快照数据仍在抓取转换中（`../原型图/data/` 各 `*-16.22` 文件），到位后按 §5「真实包形态预演」另行升版，不影响本文契约。

## 0. 冻结规则

1. 字段名、响应包装、错误码、HTTP 状态码、ETag/Cache-Control 语义均以本文为准；前端 mock 不得私改结构（可以少实现字段，不可以发明字段）。
2. `data` 内字段**缺失即 `null`**（对齐 PRD「未知项不编造」）；前端不得把 `null` 当 `0`、`""` 或空数组。
3. 契约变更必须修订本文版本号并同步前后端两侧；与《技术方案》冲突时以较新修订为准。
4. 无鉴权：所有请求不带 token / cookie；`Content-Type: application/json` 即全部要求。
5. Base URL：`http://<host>:8080/api/v1`；mock 阶段可指向本地 fixture（见 §6），**URL 路径必须与真实端一致**。
6. 服务端生成的时间字段（`publishedAt`、包装 `timestamp`）mock 阶段固定取 `"2026-11-20T00:00:00Z"`；数据包内原样字段（如 `compiledAt`）保持来源格式不动（见 §3.2 说明）。

## 1. 统一响应包装（冻结）

元信息类接口（health / latest / by-version）统一包装；`download` 为文件直出（见 §4）：

```json
{
  "code": 0,
  "message": "ok",
  "data": { },
  "timestamp": "2026-11-20T00:00:00Z"
}
```

- `code=0` 才是成功；非 0 时 `data` 为 `null`，前端只依据 `code` 与 HTTP 状态分流，不解析 `message` 文案（文案仅用于展示兜底）。
- `timestamp` 恒为 UTC ISO 8601 `Z` 结尾。

## 2. 错误码矩阵（冻结）

| code | HTTP | 场景 | mock 触发方式（示例） | 前端处理 |
| --- | --- | --- | --- | --- |
| `0` | 200 | 成功 | — | — |
| `40001` | 400 | 参数非法：`datasetVersion` 不符 `^[a-z0-9]+-[0-9]+\.[0-9]+$` | `GET /api/v1/datasets/demo-0.x`、`GET /api/v1/datasets/Demo_0.1` | 提示参数错误，**不改本地数据** |
| `40401` | 404 | 数据包版本不存在 / latest 指针不可用 | `GET /api/v1/datasets/demo-9.9`；模拟空 content 目录的 `GET /api/v1/datasets/latest` | 回退当前本地数据并提示 |
| `50000` | 500 | 服务内部错误 | mock 开关：任意接口抛 | 提示稍后重试，保留本地数据 |
| `50001` | 500 | 数据包文件损坏 / 校验和不匹配 | mock 开关：latest 指向损坏包 | 同上（真实服务端会告警） |

错误 body 与成功包装**同构**（`data` 为 `null`）：

```json
{
  "code": 40401,
  "message": "数据包版本不存在",
  "data": null,
  "timestamp": "2026-11-20T00:00:00Z"
}
```

> `message` 文案 mock 可自定义，前端**不得**依赖其内容做逻辑判断。

## 3. 四接口逐一契约

### 3.1 GET /api/v1/health

正常（200）：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "status": "UP",
    "latestDatasetVersion": "demo-0.1",
    "datasetCount": 1
  },
  "timestamp": "2026-11-20T00:00:00Z"
}
```

降级（200，`status=DEGRADED`）：content 目录异常时 `latestDatasetVersion=null`、`datasetCount=0`（或实际可读包数）。响应不含任何服务器目录路径。前端：`UP`/`DEGRADED` 仅用于设置页诊断显示，**不参与数据更新决策**（更新决策只走 latest 接口）。

### 3.2 GET /api/v1/datasets/latest

正常（200，示例 A · 当前 mock 口径）：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "datasetVersion": "demo-0.1",
    "schemaVersion": 1,
    "dataMode": "simulated",
    "mode": "demo",
    "gamePatch": null,
    "compiledAt": "2026-11-17T04:28:18.010843+00:00",
    "publishedAt": "2026-11-20T00:00:00Z",
    "contentChecksum": "sha256:831eec54a66ef1368089d12424a8de431a0fc0bbea06712b1e9d3fac992d485b",
    "fileSizeBytes": 51449,
    "downloadUrl": "/api/v1/datasets/demo-0.1/download",
    "minClientSchemaVersion": 1,
    "contentPolicy": {
      "verifiedMeaning": "已逐条对照读取的来源页面；不表示官方核验或当前版本保证。",
      "pendingMeaning": "有来源摘要，但数值、分支或交互尚未确认。",
      "stats": "仅人工模拟；无数据保存为 null，不使用站方统计。",
      "recommendations": "人工示例顺序，不来自胜率排名。",
      "imagePathBase": "项目根目录；JSON 中所有 iconPath 均相对项目根目录。",
      "lowSampleThreshold": 200
    },
    "snapshots": [],
    "coverage": null,
    "defaultSnapshotId": null
  },
  "timestamp": "2026-11-20T00:00:00Z"
}
```

字段口径：

| 字段 | 规则 |
| --- | --- |
| `datasetVersion` / `schemaVersion` / `mode` / `gamePatch` / `compiledAt` / `contentPolicy` | demo-0.1.json 现有字段**原样透传**。注意 `compiledAt` 是来源原样格式（微秒精度 + `+00:00` 偏移），与包装 `timestamp`（秒级 `Z`）**两种时间风格并存是故意的**，前端分别解析、不做统一强校验 |
| `dataMode` | 由包内 `mode=demo` 映射为 PRD 13.1 的 `simulated`；真实快照包直接为 `source-snapshot`（见示例 B）。**两种模式永不混发**，前端按 dataMode 做模式隔离展示（V22） |
| `publishedAt` / `contentChecksum` / `fileSizeBytes` / `downloadUrl` / `minClientSchemaVersion` | 服务端发布时生成（新增假设，待产品确认）；`contentChecksum`/`fileSizeBytes` 与 §4 数据包实际值一致；`minClientSchemaVersion` 供客户端自检，服务端不拦截 |
| `snapshots` / `coverage` / `defaultSnapshotId` | demo 包无对应内容 → 空数组 / `null` / `null`，不编造 |

异常（404 + `40401`）：content 目录为空或 latest 指针不可用。
缓存：`Cache-Control: max-age=60`。

示例 B · 真实包形态预演（**draft**，快照数据落盘后升版本启用，前端可先建模型不接 UI）：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "datasetVersion": "snapshot-1.0",
    "schemaVersion": 1,
    "dataMode": "source-snapshot",
    "mode": null,
    "gamePatch": "16.22",
    "compiledAt": "2026-11-20T01:38:34Z",
    "publishedAt": "2026-11-20T00:00:00Z",
    "contentChecksum": "sha256:<发布时生成>",
    "fileSizeBytes": 0,
    "downloadUrl": "/api/v1/datasets/snapshot-1.0/download",
    "minClientSchemaVersion": 1,
    "contentPolicy": null,
    "snapshots": [
      {
        "id": "aramkit-16.22-all",
        "gamePatch": "16.22",
        "segment": "all",
        "segmentNote": "全分段（来源页面 all 口径）",
        "region": null,
        "windowStart": null,
        "windowEnd": null,
        "sourceUpdatedAt": "2026-11-15",
        "allMatches": 43491990,
        "allMatchesNote": "站方页面快照数字，仅作来源页记录；不可作为本地可复算的选取率分母",
        "methodologyId": null,
        "methodologyNote": "来源排名、梯队划分、选取率分母算法未取得；rank/tier/选取率为来源页面口径原样收录，未做任何再计算"
      }
    ],
    "coverage": {
      "expectedCount": 197,
      "includedCount": 197,
      "rankedCount": 118,
      "missingStatsCount": 79,
      "isComplete": true
    },
    "defaultSnapshotId": "aramkit-16.22-all"
  },
  "timestamp": "2026-11-20T00:00:00Z"
}
```

> 示例 B 的 snapshots/coverage 节选自 `原型图/data/items-16.22-snapshot.json`（真实落盘数据）；`datasetVersion` 编号规则（`snapshot-{主.次}` 重新编号 vs 沿用 `aramkit-16.22-*` 原名）**尚未拍板**（见 §7 遗留），拍板前前端不得对版本号格式做超出 §2 正则的假设。

### 3.3 GET /api/v1/datasets/{datasetVersion}

- 200：与 §3.2 示例同构（按指定版本返回，不受 latest 指针异常影响）。
- 400 + `40001`：版本号不符正则。
- 404 + `40401`：目录中不存在该版本。

### 3.4 GET /api/v1/datasets/{datasetVersion}/download

- 200：**数据包文件原样字节**（不是包装结构）。示例 A 即 `原型图/data/demo-0.1.json` 全文。
- 响应头（冻结）：

```http
Content-Type: application/json
ETag: "sha256:831eec54a66ef1368089d12424a8de431a0fc0bbea06712b1e9d3fac992d485b"
Cache-Control: public, max-age=31536000, immutable
```

- `If-None-Match` 命中 → `304` 空体（同 ETag）。
- 404 / 400：错误 body 与 §2 同构（简单 JSON + 正确状态码）。
- 500 + `50001`：包文件损坏（真实服务端告警；mock 用开关模拟）。
- **前端必须校验 sha256 与元信息 `contentChecksum` 一致后才切换本地数据**；校验失败保留旧数据（PRD R14）。

## 4. Mock 数据包内容（冻结）

- **唯一 mock 包**：`原型图/data/demo-0.1.json` **原样字节**（51,449 字节，sha256 `831eec54a66ef1368089d12424a8de431a0fc0bbea06712b1e9d3fac992d485b`）。
- 前端 mock 直接内置 / 读取该文件充当 download 响应，**不得复制改写**（防止 mock 内容与未来真实下发内容漂移；该文件当前正被数据侧维护，改写副本必然失同步）。
- 对象模型按技术方案 §4.1（champions 8 / augments 12 / items 27 / summonerSpells 3 / championAugments 24 / builds 8 / sources 22）。
- 必须 mock 到的关键路径：champion/augment 的 `stats` 全 `null` → 页面「暂无统计」；`championAugments[].stats` 仅 2 条模拟记录（`isSimulated=true`）；`effectStatus=pending` 的提示态。
- 数据包内 `iconPath` 相对项目根目录解析（`contentPolicy.imagePathBase`），是前端 asset 映射职责，与本契约无关。

## 5. 前端消费规则（冻结）

1. 启动/手动检查：`GET /datasets/latest` → 与本地 `datasetVersion` **字符串比较**（不等即视为有新版，不做语义/拆段比较）→ `GET download` → 校验 sha256 → 原子写缓存 → 切换。任一步失败：**保留旧数据并提示**（PRD R14）。
2. `minClientSchemaVersion` > 本地 schemaVersion → 不下载、提示（客户端自检，服务端不拦截）。
3. 超时建议：latest 5s、download 30s；超时按失败处理。
4. 兜底顺序：本地缓存 → 内置 `assets/data`（App 打包内 demo-0.1）；**断网首启必须可用**。
5. mock 阶段允许跳过网络直接指向内置包，但接口解析层必须走同一契约模型（同构 Dart model），保证切换真实后端零改动。

## 6. Mock 服务形态（建议，非冻结）

| 方案 | 做法 | 适用 |
| --- | --- | --- |
| A（推荐） | 前端 fixture：按本文 JSON 示例建 Dart 模型 + fake client，内置 demo-0.1.json | 前端先行开发，零部署 |
| B | 静态文件服务器按 §3 路径摆 JSON（nginx / `python3 -m http.server`），`Access-Control-Allow-Origin: *` | 需要 HTTP 语义（304/ETag/错误码）验证时 |
| C | 后端 B0 骨架提前跑起来（`content/` 放入 demo-0.1 数据包）当真 mock | B1 完成后自然过渡为真实端 |

- Web 联调 CORS：dev 环境一律 `Access-Control-Allow-Origin: *`（原生 App 调用不受影响）；后端 `config` 的 CORS 占位在 B0 实现为 dev profile 专用，生产不开。
- 无论选哪种，契约以本文为准；路径、字段、错误码与真实端**完全一致**。

## 7. 遗留与升版

| # | 事项 | 状态 |
| --- | --- | --- |
| 1 | 快照包（source-snapshot）的包形态：单文件合包 vs 多文件 manifest vs gzip；当前真实数据落盘总量已达数 MB～数十 MB 级（仅 item-roles 单文件 3.1MB，另有 champion-details ×173 逐英雄文件），技术方案「整包不压缩不分片」假设需在真实包阶段重评 | 待产品/后端预研（技术方案待确认 #10 延展） |
| 2 | 快照包版本编号：`snapshot-{主.次}` 重新编号（推荐，`aramkit-16.22-*` 原名记入包内 sources）vs 放宽 §2 正则 | 待拍板；拍板前 mock 只保证 demo-0.1 |
| 3 | 快照包的 stats 校验规则（winRatePct 0–100 范围、sampleCount 语义）与 demo 包（wins/games）分型 | 随 #1 一并评审 |
| 4 | 灰度下发、图片下发、签名 URL | 均维持技术方案「不做 / 待产品确认」结论，不在本契约范围 |

## 修订记录

| 版本 | 日期 | 变更 |
| --- | --- | --- |
| v1.0 | 2026-11-20 | 初稿：按技术方案 v0.2 §3 冻结四接口契约、错误矩阵、demo-0.1 数据包口径（真实 sha256/字节数），附真实包形态 draft 预演 |
