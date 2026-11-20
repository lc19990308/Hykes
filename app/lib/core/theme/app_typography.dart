import 'package:material_ui/material_ui.dart';

/// 字体 Token 单一来源：`../原型图/海斗宝典-设计体系.md` §3（v0.2 浅色主题）。
///
/// 平台字体沿用系统中文无衬线（iOS PingFang SC / Android Noto Sans CJK），
/// 不依赖在线字体，初版不下载商业字体。
/// 颜色不在本层绑定，由 [AppTheme] 装配到 Material 文本角色。
abstract final class AppTextStyles {
  /// 顶栏标题、弹层标题（type.pageTitle 28/34/600）
  static const TextStyle pageTitle = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w600,
  );

  /// 内容大分区、详情名称（type.sectionTitle 20/28/600）
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
  );

  /// 列表名、推荐标题、出装方案段标题（type.itemTitle 18/28/600）
  static const TextStyle itemTitle = TextStyle(
    fontSize: 18,
    height: 28 / 18,
    fontWeight: FontWeight.w600,
  );

  /// 正文；行高系数 1.47（type.body 17/25/400）
  static const TextStyle body = TextStyle(
    fontSize: 17,
    height: 25 / 17,
    fontWeight: FontWeight.w400,
  );

  /// 主/次/危险按钮、强调标签（type.label 15/22/600）
  static const TextStyle label = TextStyle(
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w600,
  );

  /// 辅助说明、列表副行（type.meta 14/22/400）
  static const TextStyle meta = TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
  );

  /// 非交互徽标、榜单说明行（type.caption 13/22/400）
  ///
  /// 13 字号只承载短辅助内容，不能承载完整效果或关键限制。
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    height: 22 / 13,
    fontWeight: FontWeight.w400,
  );

  /// 主导航短标签、顶栏眉标（type.navLabel 12/18/600）
  static const TextStyle navLabel = TextStyle(
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w600,
  );

  /// 版本号等可选统计值（type.stat 24/32/600，等宽数字，最多局部使用）
  static const TextStyle stat = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
