/**
 * REST 接口层。
 *
 * <p>骨架占位，待方案评审后实现（方案第 3 节）。只做协议转换与参数校验，不含业务规则。
 *
 * <p>MVP 共四个只读端点（整体为「新增假设，待产品确认」——PRD 未定义后端接口）：
 *
 * <ul>
 *   <li>{@code GET /api/v1/health}：服务与 content 目录可用性。</li>
 *   <li>{@code GET /api/v1/datasets/latest}：最新数据包元信息。</li>
 *   <li>{@code GET /api/v1/datasets/{datasetVersion}}：指定版本元信息。</li>
 *   <li>{@code GET /api/v1/datasets/{datasetVersion}/download}：数据包原文件直出
 *       （application/json + ETag=sha256 + immutable，不走统一响应包装）。</li>
 * </ul>
 *
 * <p>不做搜索、筛选、排序、收藏类接口（PRD 15：列表能力留在客户端）。
 */
package com.hykes.haidou.controller;
