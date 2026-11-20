/**
 * 数据包元信息模型。
 *
 * <p>骨架占位，待方案评审后实现（方案 4.2 节）。
 *
 * <p>字段：datasetVersion（{@code {mode}-{主.次}}，发布后不可变）、schemaVersion（与客户端用户状态
 * schemaVersion 含义不同，PRD 11.3）、dataMode（demo→simulated 映射）、gamePatch（未知为 null）、
 * compiledAt；发布期新增字段——publishedAt / contentChecksum / fileSizeBytes / downloadUrl /
 * minClientSchemaVersion，均为「新增假设，待产品确认」。
 *
 * <p>预留 PRD 13.1 的 Snapshot 与 Coverage 结构；demo 阶段无对应数据，返回空/null，不编造。
 */
package com.hykes.haidou.domain.dataset;
