/**
 * 内容对象模型，与 {@code demo-0.1.json} 字段一一对应。
 *
 * <p>骨架占位，待方案评审后实现（方案 4.1 节字段映射表）。
 *
 * <p>模型清单：DatasetMeta、ContentPolicy、Champion、Augment、Item、SummonerSpell、
 * ChampionAugment、Build、SourceEntry。约定：
 *
 * <ul>
 *   <li>缺失即 null，不猜测补齐（PRD「未知项不编造」）。</li>
 *   <li>核对状态字段原样保留：effectStatus / balanceStatus / stageStatus / isExample / isStale /
 *       isSimulated / sourceIds（→sources 的 licenseNote 随包下发，支撑客户端数据说明页）。</li>
 *   <li>已知缺口：PRD v1.0 的 Item 还要求 itemType / roles / attributes / availabilityStatus，
 *       demo 数据未提供，由内容整理阶段补数据，后端不伪造。</li>
 * </ul>
 */
package com.hykes.haidou.domain.content;
