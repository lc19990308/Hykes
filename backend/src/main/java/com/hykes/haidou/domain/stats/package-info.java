/**
 * 统计记录模型（PRD 13.2 完整结构，v1.0 预留）。
 *
 * <p>骨架占位，待方案评审后实现。demo-0.1 仅有简化统计
 * {@code {wins, games, isSimulated, gamePatch, segment}}（当前只有 2 条模拟记录，其余为 null），
 * 后端原样透传、不计算不聚合。
 *
 * <p>本包预留 PRD 13.2 的完整字段：scopeType 七种口径、interactionPolicy、selectionMetricId、
 * baselineRecordId / comparisonDefinitionId 等。demo 阶段无对应数据，不启用、不反向构造；
 * 待内容侧按 PRD 13 节整理出数据后随新 datasetVersion 启用。
 */
package com.hykes.haidou.domain.stats;
