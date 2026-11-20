import 'package:material_ui/material_ui.dart';

/// 颜色 Token 单一来源：`../原型图/海斗宝典-设计体系.md` §2（v0.2 浅色主题）。
///
/// 实现时只引用本文件的语义 Token，组件内不得另造近似值（设计体系 §1）。
/// v0.1 深色 Token（#0C1420 系、青蓝 #63D9E8 系、金色细节）已整体废弃。
///
/// 前景/背景成对使用的颜色（状态与标签，设计体系 §2.2）。
typedef AppColorPair = ({Color foreground, Color background});

abstract final class AppColors {
  // §2.1 页面、文字及交互
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F7);
  static const Color raised = Color(0xFFFFFFFF); // 弹窗/弹层底色，配 AppElevation.raised 阴影与边界区分层级

  /// 筛选 chip 选中底（墨底白字，设计体系 §2.2 选中证据）
  static const Color selected = Color(0xFF1D1D1F);

  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF424245);

  /// 辅助说明、占位、禁用态文字；对 surface 实测 4.66:1，达标但禁止再调浅
  static const Color textMuted = Color(0xFF6E6E73);

  static const Color actionPrimary = Color(0xFF0071E3);
  static const Color actionOnPrimary = Color(0xFFFFFFFF);
  static const Color actionPressed = Color(0xFF0066CC);
  static const Color actionHover = Color(0xFF0077ED);

  static const Color borderSubtle = Color(0xFFE8E8ED); // 行分隔、组内细分隔
  static const Color borderControl = Color(0xFFD2D2D7); // 次按钮边界；装饰性，不承担辨识职责

  /// 焦点环色（同按下色，设计体系 §4.2 focus 2/2）
  static const Color focus = Color(0xFF0066CC);

  /// 弹窗遮罩（40% 黑，设计体系 §2.1）
  static const Color overlayScrim = Color(0x66000000);

  // §2.2 状态与标签：非交互标签统一中性样式，语义由文字承担。
  static const AppColorPair statusDanger = (
    foreground: Color(0xFFFFFFFF),
    background: Color(0xFFDC2626),
  );

  /// 危险按钮按下/悬停加深（对应 CSS color-mix 78%/86% 黑）
  static const Color statusDangerPressed = Color(0xFFAC1E1E);
  static const Color statusDangerHover = Color(0xFFBD2121);

  // §2.2 稀有度（银色/金色/棱彩/待核对）：中性徽标，必须写出名称，不能仅凭颜色识别。
  static const AppColorPair rarityLabel = (
    foreground: Color(0xFF424245),
    background: Color(0xFFF5F5F7),
  );
}

/// 夜间 Token：设计体系 §2.4「夜间 Token 表」——已按实现侧 WCAG 实测回写值。
///
/// 与白天模式共用语义 Token 名与组件结构，仅替换映射值（成套使用，禁止混搭）；
/// 本文件只承载夜间**定值**，装配见 [AppTheme.dark]。
abstract final class AppNightColors {
  static const Color canvas = Color(0xFF0C1420); // --bg
  static const Color surface = Color(0xFF142131); // --surface
  static const Color surfaceWarm = Color(0xFF101A28); // --surface-warm（亮度过渡档）
  static const Color surfaceHover = Color(0xFF1C2D40); // --surface-hover（悬停与提升面共用）

  /// 筛选 chip 选中（浅底深字，与白天墨底白字互为反相）
  static const Color selected = Color(0xFFEDF3F8);
  static const Color onSelected = Color(0xFF0C1420);

  static const Color textPrimary = Color(0xFFEDF3F8); // --fg
  static const Color textSecondary = Color(0xFFB5C4D2); // --fg-2
  static const Color textMuted = Color(0xFF94A8BC); // --muted

  /// 夜间主交互（#0A84FF 对 surface 实测 4.46 不达标，微亮后 4.68 达标）
  static const Color actionPrimary = Color(0xFF0E89FF);
  static const Color actionOnPrimary = Color(0xFFFFFFFF);
  static const Color actionPressed = Color(0xFF3395FF); // --accent-active，兼焦点环
  static const Color actionHover = Color(0xFF3395FF);

  static const Color borderSubtle = Color(0xFF223141); // --border-soft（装饰 hairline）
  static const Color borderPlain = Color(0xFF2E3E4F); // --border（中间档）
  static const Color borderControl = Color(0xFF5E7A99); // 交互控件边界（≥3:1 实测定值）

  /// 夜间危险按钮：浅红底配深字（白字对 #F87171 仅 2.84 不达标，保对比取舍）
  static const AppColorPair statusDanger = (
    foreground: Color(0xFF0C1420),
    background: Color(0xFFF87171),
  );

  /// 夜间弹层阴影：0 8px 24px rgb(0 0 0 / 32%)
  static const List<BoxShadow> raisedShadowList = [
    BoxShadow(offset: Offset(0, 8), blurRadius: 24, color: Color(0x52000000)),
  ];
}
