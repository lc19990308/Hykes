/**
 * 业务逻辑层。
 *
 * <p>骨架占位，待方案评审后实现（方案第 5 节）。
 *
 * <p>职责：
 *
 * <ul>
 *   <li>数据包元信息查询：读取 latest 指针、组装元信息（含 checksum / downloadUrl 等发布期字段）。</li>
 *   <li>发布校验：结构校验、引用闭合、计数有效性（0&le;wins&le;games 且 games&gt;0）、
 *       单一数据模式、id 唯一性；坏包拒绝发布并产出报告，验收夹具包需显式 allowBrokenReferences。</li>
 * </ul>
 *
 * <p>禁止事项（PRD 12.2）：不做任何胜率/选取率聚合、排序或差值计算；统计计数原样透传。
 */
package com.hykes.haidou.service;
