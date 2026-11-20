/**
 * 海斗宝典后端 · 根包。
 *
 * <p>骨架占位，待方案评审后实现（方案全文见 docs/技术方案.md）。
 *
 * <p>应用入口 {@code HaidouApplication} 与分层职责在方案第 2 节定义：
 * controller（接口）→ service（业务）→ repository（content 目录数据包读取），
 * common.api 收口统一响应与错误码。
 *
 * <p>边界（方案第 1 节）：后端只做内容数据下发、版本与更新、健康检查三件事；
 * 搜索/筛选/排序、收藏/最近查看留在客户端；不新增 PRD 未定义的端点、权限或表结构，
 * 凡 PRD 未定义的能力均标注「新增假设，待产品确认」。
 */
package com.hykes.haidou;
