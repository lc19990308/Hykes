# 海斗宝典 · 内容服务

基于 Java 17、Maven 和 Spring Boot 3.5，为客户端提供演示数据包的发布、查询、下载与回滚。发布通过本地 CLI 完成，HTTP 接口提供只读内容。

## 本地启动

从 `backend/` 运行：

```sh
mvn package
java -jar target/haidou-backend-0.1.0-SNAPSHOT.jar --publish ../原型图/data/demo-0.1.json
java -jar target/haidou-backend-0.1.0-SNAPSHOT.jar --server.address=127.0.0.1
```

服务默认在端口 `8080` 启动。发布和启动必须使用相同的数据目录。可为两条命令同时添加 `--haidou.content.base-dir=<目录>`，使用独立的验证目录。连接移动端时参阅[前端联调说明](../app/README.md#连接内容服务)。

## HTTP 接口

| 请求 | 用途 |
| --- | --- |
| `GET /api/v1/health` | 返回健康状态、最新可用版本和可读版本数 |
| `GET /api/v1/datasets/latest` | 返回最新数据包元信息，包括下载地址与 SHA-256 |
| `GET /api/v1/datasets/{datasetVersion}` | 返回指定版本元信息 |
| `GET /api/v1/datasets/{datasetVersion}/download` | 返回原样 JSON 字节，支持 `ETag` 与 `304` |

```sh
curl -fsS http://127.0.0.1:8080/api/v1/health
curl -fsS http://127.0.0.1:8080/api/v1/datasets/latest
```

字段、状态码和缓存规则见[接口契约](docs/mock-约定.md)。

## 发布、回滚与测试

发布前检查格式、引用关系和模拟统计。已发布版本不可改写，内容有变化时应使用新版本号。回滚将 `latest` 指向指定的已发布版本：

```sh
java -jar target/haidou-backend-0.1.0-SNAPSHOT.jar --rollback demo-0.1
mvn test
```

测试覆盖发布及下载原样字节、`304`、错误码、夹具隔离、版本不可变与回滚。运行时目录结构见[内容目录说明](content/README.md)。当前只发布 `demo-*` 模拟数据包，本地运行命令绑定回环地址。
