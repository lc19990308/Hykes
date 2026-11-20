import 'package:flutter/animation.dart';

/// 动效 Token：`../原型图/海斗宝典-设计体系.md` §9（v0.2）。
///
/// 数据更新立即执行，动效仅呈现状态变化；
/// 无列表逐项入场、装饰循环、页面粒子或缩放脉冲。
abstract final class AppMotion {
  /// 按钮背景、选中标识
  static const Duration state = Duration(milliseconds: 150);

  /// 通用状态过渡（原型标准缓动 cubic-bezier(0.28, 0, 0.22, 1)）
  static const Duration base = Duration(milliseconds: 220);

  /// 底部弹层入场
  static const Duration enter = Duration(milliseconds: 200);

  /// 弹层退场（系统返回转场沿用平台规范）
  static const Duration exit = Duration(milliseconds: 160);

  static const Curve stateCurve = Curves.easeOut;
  static const Curve enterCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;

  /// 原型标准缓动（--ease-standard），供通用过渡引用
  static const Curve standardCurve = Cubic(0.28, 0, 0.22, 1);

  /// 减少动态效果：直接切换，不播放动效（motion.reduce 0ms）；
  /// 编程式滚动此时改为直接跳转。
  static const Duration reduced = Duration.zero;
}
