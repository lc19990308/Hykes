/**
 * 统一响应包装、错误码与全局异常处理。
 *
 * <p>骨架占位，待方案评审后实现（方案第 3 节）。
 *
 * <p>约定：
 *
 * <ul>
 *   <li>所有 {@code /api/v1} 接口返回 {@code ApiResponse<T>}
 *       （code / message / data / timestamp）；成功 code=0。</li>
 *   <li>错误码枚举集中在本包定义：0 成功、40001 参数非法、40401 数据包不存在、
 *       50000 内部错误、50001 内容目录读取失败；4xxxx 客户端侧、5xxxx 服务端侧。</li>
 *   <li>全局异常处理在本包统一收口；错误信息不泄露本机敏感路径、凭据或内部调用细节（PRD 14）。</li>
 * </ul>
 */
package com.hykes.haidou.common.api;
