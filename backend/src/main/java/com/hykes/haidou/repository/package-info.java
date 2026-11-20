/**
 * 数据访问层。
 *
 * <p>骨架占位，待方案评审后实现。MVP 无数据库：唯一实现为
 * {@code ContentPackageRepository}，读取运行时外部 {@code content/} 目录——
 * 按 datasetVersion 定位数据包文件、读取 latest 指针、提供下载流与校验和。
 *
 * <p>同一 datasetVersion 发布后内容不可变；latest 指针原子切换（临时文件 + rename）。
 * 引入数据库的条件与备选见技术方案 6.4（内容编辑后台立项时另行评审）。
 */
package com.hykes.haidou.repository;
