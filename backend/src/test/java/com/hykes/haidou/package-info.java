/**
 * 测试根包。
 *
 * <p>骨架占位，待方案评审后实现（方案第 7 节验收标准）。
 *
 * <p>测试约定：
 *
 * <ul>
 *   <li>B1 接口验收：latest 元信息与数据包一致、download sha256 一致、未知版本 404+40401、
 *       ETag/If-None-Match 304。</li>
 *   <li>B2 发布校验验收：悬空引用坏包被拒绝并出报告；allowBrokenReferences 夹具包可发布且被标记；
 *       wins&gt;games 等无效计数被隔离。</li>
 *   <li>引用闭合与计数有效性规则对齐 PRD 13.3 与 12.2；不测试不存在的功能。
 */
package com.hykes.haidou;
