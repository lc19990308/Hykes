import 'package:material_ui/material_ui.dart';

/// 空间、形状与层级 Token：`../原型图/海斗宝典-设计体系.md` §4（v0.2）；
/// 布局与安全区基准：§5。
///
/// 固定值是默认或最小值，不能阻止系统字号放大后的布局增长（设计体系 §1）。
abstract final class AppSpacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20; // 页面左右边距（v0.2 新增）
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s12 = 48;
}

abstract final class AppRadius {
  /// 图标载体、紧凑控件、徽标
  static const double small = 8;

  /// 标准按钮、输入、mini 行
  static const double control = 12;

  /// 独立内容卡、确认弹窗
  static const double group = 18;

  /// 底部弹层（筛选 Sheet、对局助手）
  static const double sheet = 28;

  /// 筛选胶囊 chip（保留字面值 980，与原型一致）
  static const double pill = 980;
}

abstract final class AppStroke {
  /// 边界与分隔线
  static const double defaultWidth = 1;

  /// 选中下划线、导航顶标
  static const double selected = 2;
}

abstract final class AppFocusRing {
  static const double width = 2;
  static const double offset = 2;

  /// 弹层内焦点外发光（主色 35% 透明度，可选）
  static const double glow = 4;
}

/// 提升层级（设计体系 §4.2）：白底 + 柔和阴影 + 可辨认边界。
/// 平面层级靠 canvas/surface 色阶与 hairline，不滥用阴影。
abstract final class AppElevation {
  /// 边界式收纳：0 0 0 1px border
  static final BoxShadow ring = BoxShadow(
    offset: Offset.zero,
    blurRadius: 0,
    spreadRadius: AppStroke.defaultWidth,
    color: const Color(0xFFD2D2D7),
  );

  /// 弹窗/卡片软阴影：0 12px 32px rgba(0,0,0,0.08)
  static final BoxShadow raised = const BoxShadow(
    offset: Offset(0, 12),
    blurRadius: 32,
    color: Color(0x15000000),
  );

  /// 同上，ThemeExtension 装配用的 const 列表形态。
  static const List<BoxShadow> raisedShadowList = [
    BoxShadow(offset: Offset(0, 12), blurRadius: 32, color: Color(0x15000000)),
  ];
}

abstract final class AppLayout {
  /// 设计基准宽 390，支持 360–430（设计体系 §5）
  static const double designWidth = 390;
  static const double minWidth = 360;
  static const double maxWidth = 430;

  /// 页面左右边距 20；≤374 宽降至 16
  static const double pagePadding = 20;
  static const double pagePaddingCompact = 16;

  /// 顶部栏内容最小高度（不含安全区）：次级页 64，根页 68
  static const double topBarMinHeight = 64;
  static const double rootTopBarMinHeight = 68;

  /// 底部导航内容最小高度（不含安全区）
  static const double bottomNavMinHeight = 64;

  /// 大于 600 的窗口：单栏正文限制在 560 宽并居中，不新增桌面侧栏
  static const double wideBreakpoint = 600;
  static const double wideBodyMaxWidth = 560;

  /// 独立控件触控最小值；独立图标按钮载体按设计体系 §6 取 48
  static const double touchTarget = 44;
  static const double iconTarget = 48;
}
