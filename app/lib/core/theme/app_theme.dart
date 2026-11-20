import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// 主题装配：设计体系 §1「颜色、字号、间距…集中定义；实现时引用语义 Token」。
///
/// 白天/晚上双模式（PRD v1.2 R19）：白天沿用 v0.2 浅色基准零变化；
/// 夜间按设计体系 §2.4 实测回写值，共用组件结构，仅替换映射值。
abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.actionPrimary,
      onPrimary: AppColors.actionOnPrimary,
      secondary: AppColors.actionPressed,
      onSecondary: AppColors.actionOnPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.statusDanger.background,
      onError: AppColors.statusDanger.foreground,
      outline: AppColors.borderControl,
      outlineVariant: AppColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: _textTheme(Brightness.light),
      extensions: [AppPalette.light],
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle:
            AppTextStyles.itemTitle.copyWith(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.canvas,
        selectedItemColor: AppColors.actionPrimary,
        unselectedItemColor: AppColors.textSecondary,
        // type.navLabel 12/18：选中 600 字重 + 主色顶标（C09）
        selectedLabelStyle: AppTextStyles.navLabel,
        unselectedLabelStyle:
            AppTextStyles.navLabel.copyWith(fontWeight: FontWeight.w400),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: AppStroke.defaultWidth,
        space: AppStroke.defaultWidth,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionPrimary,
          foregroundColor: AppColors.actionOnPrimary,
          // 禁用态：muted 文字 + surface 底，不用整组透明度（设计体系 §8）
          disabledForegroundColor: AppColors.textMuted,
          disabledBackgroundColor: AppColors.surface,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          textStyle:
              AppTextStyles.label.copyWith(color: AppColors.actionOnPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.actionPrimary,
          minimumSize: const Size(64, 44),
          textStyle: AppTextStyles.label.copyWith(color: AppColors.actionPrimary),
        ),
      ),
    );
  }

  /// 夜间主题（设计体系 §2.4 实测定值）：与白天共用组件结构。
  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: AppNightColors.actionPrimary,
      onPrimary: AppNightColors.actionOnPrimary,
      secondary: AppNightColors.actionPressed,
      onSecondary: AppNightColors.actionOnPrimary,
      surface: AppNightColors.surface,
      onSurface: AppNightColors.textPrimary,
      error: AppNightColors.statusDanger.background,
      onError: AppNightColors.statusDanger.foreground,
      outline: AppNightColors.borderControl,
      outlineVariant: AppNightColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppNightColors.canvas,
      textTheme: _textTheme(Brightness.dark),
      extensions: [AppPalette.night],
      appBarTheme: AppBarTheme(
        backgroundColor: AppNightColors.canvas,
        foregroundColor: AppNightColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle:
            AppTextStyles.itemTitle.copyWith(color: AppNightColors.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppNightColors.canvas,
        selectedItemColor: AppNightColors.actionPrimary,
        unselectedItemColor: AppNightColors.textSecondary,
        selectedLabelStyle: AppTextStyles.navLabel,
        unselectedLabelStyle:
            AppTextStyles.navLabel.copyWith(fontWeight: FontWeight.w400),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppNightColors.borderSubtle,
        thickness: AppStroke.defaultWidth,
        space: AppStroke.defaultWidth,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppNightColors.actionPrimary,
          foregroundColor: AppNightColors.actionOnPrimary,
          disabledForegroundColor: AppNightColors.textMuted,
          disabledBackgroundColor: AppNightColors.surface,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          textStyle: AppTextStyles.label
              .copyWith(color: AppNightColors.actionOnPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppNightColors.actionPrimary,
          minimumSize: const Size(64, 44),
          textStyle:
              AppTextStyles.label.copyWith(color: AppNightColors.actionPrimary),
        ),
      ),
    );
  }

  /// 设计 Token → Material 文本角色的映射。
  /// 组件优先直接使用 [AppTextStyles]；本映射保证默认控件拿到同源样式。
  static TextTheme _textTheme(Brightness brightness) {
    final textPrimary = switch (brightness) {
      Brightness.light => AppColors.textPrimary,
      Brightness.dark => AppNightColors.textPrimary,
    };
    final textSecondary = switch (brightness) {
      Brightness.light => AppColors.textSecondary,
      Brightness.dark => AppNightColors.textSecondary,
    };
    return TextTheme(
      // type.pageTitle 28/34/600：顶栏标题、弹层标题
      headlineMedium:
          AppTextStyles.pageTitle.copyWith(color: textPrimary),
      // type.sectionTitle 20/28/600：内容大分区、详情名称
      titleLarge: AppTextStyles.sectionTitle.copyWith(color: textPrimary),
      // type.itemTitle 18/28/600：列表名、推荐标题
      titleMedium: AppTextStyles.itemTitle.copyWith(color: textPrimary),
      // type.body 17/25/400：正文（行高系数 1.47）
      bodyMedium: AppTextStyles.body.copyWith(color: textPrimary),
      // type.label 15/22/600：按钮、强调标签
      labelLarge: AppTextStyles.label.copyWith(color: textPrimary),
      // type.meta 14/22/400：辅助说明、列表副行
      bodySmall: AppTextStyles.meta.copyWith(color: textSecondary),
      // type.stat 24/32/600：版本号等可选统计值（等宽数字）
      displaySmall: AppTextStyles.stat.copyWith(color: textPrimary),
    );
  }
}

/// 语义调色板（白天/夜间成对）：白天零变化地映射 [AppColors]，
/// 夜间映射 [AppNightColors]；页面组件一律经 [AppPalette.of] 取色，
/// 不直接引用具体 Token 值，保证 R19 双模式共用同一组件结构。
///
/// 选取证据（设计体系 §2.2/§2.4）：白天 chip 选中为墨底白字，
/// 夜间为浅底深字，互为反相；文字语义（primary/secondary/muted）成套切换。
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceHover,
    required this.raised,
    required this.selected,
    required this.onSelected,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.actionPrimary,
    required this.actionOnPrimary,
    required this.actionPressed,
    required this.focus,
    required this.borderSubtle,
    required this.borderPlain,
    required this.borderControl,
    required this.dangerForeground,
    required this.dangerBackground,
    required this.neutralBadgeForeground,
    required this.neutralBadgeBackground,
    required this.scrim,
    required this.raisedShadows,
  });

  static const AppPalette light = AppPalette(
    canvas: AppColors.canvas,
    surface: AppColors.surface,
    surfaceHover: AppColors.surface, // 白天悬停底（无独立夜间 surfaceHover 对应提升面语义）
    raised: AppColors.raised,
    selected: AppColors.selected,
    onSelected: AppColors.actionOnPrimary,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    actionPrimary: AppColors.actionPrimary,
    actionOnPrimary: AppColors.actionOnPrimary,
    actionPressed: AppColors.actionPressed,
    focus: AppColors.focus,
    borderSubtle: AppColors.borderSubtle,
    borderPlain: AppColors.borderControl, // 白天无中间档，控制边界即装饰边界档
    borderControl: AppColors.borderControl,
    dangerForeground: Color(0xFFFFFFFF), // AppColors.statusDanger.foreground（const record 字段不可引用，取定值）
    dangerBackground: Color(0xFFDC2626),
    neutralBadgeForeground: Color(0xFF424245), // AppColors.rarityLabel.foreground
    neutralBadgeBackground: Color(0xFFF5F5F7),
    scrim: AppColors.overlayScrim,
    raisedShadows: AppElevation.raisedShadowList,
  );

  static const AppPalette night = AppPalette(
    canvas: AppNightColors.canvas,
    surface: AppNightColors.surface,
    surfaceHover: AppNightColors.surfaceHover,
    raised: AppNightColors.surfaceHover, // 夜间提升面与悬停共用值
    selected: AppNightColors.selected,
    onSelected: AppNightColors.onSelected,
    textPrimary: AppNightColors.textPrimary,
    textSecondary: AppNightColors.textSecondary,
    textMuted: AppNightColors.textMuted,
    actionPrimary: AppNightColors.actionPrimary,
    actionOnPrimary: AppNightColors.actionOnPrimary,
    actionPressed: AppNightColors.actionPressed,
    focus: AppNightColors.actionPressed,
    borderSubtle: AppNightColors.borderSubtle,
    borderPlain: AppNightColors.borderPlain,
    borderControl: AppNightColors.borderControl,
    dangerForeground: Color(0xFF0C1420), // AppNightColors.statusDanger.foreground（const 定值）
    dangerBackground: Color(0xFFF87171),
    neutralBadgeForeground: AppNightColors.textSecondary,
    neutralBadgeBackground: AppNightColors.surface,
    scrim: AppColors.overlayScrim,
    raisedShadows: AppNightColors.raisedShadowList,
  );

  final Color canvas;
  final Color surface;

  /// 行/按钮按下与悬停底（白天 surface，夜间 surfaceHover）
  final Color surfaceHover;

  /// 弹窗/弹层底色
  final Color raised;

  /// 筛选 chip 选中底
  final Color selected;

  /// chip 选中底上的文字
  final Color onSelected;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color actionPrimary;
  final Color actionOnPrimary;
  final Color actionPressed;
  final Color focus;

  /// 行分隔、组内细分隔（装饰 hairline）
  final Color borderSubtle;

  /// 中间档边界
  final Color borderPlain;

  /// 交互控件边界（搜索框、次按钮）
  final Color borderControl;

  final Color dangerForeground;
  final Color dangerBackground;
  final Color neutralBadgeForeground;
  final Color neutralBadgeBackground;
  final Color scrim;
  final List<BoxShadow> raisedShadows;

  static AppPalette of(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>();
    assert(palette != null, 'AppPalette 未注册：ThemeData 必须经 AppTheme 装配');
    return palette ?? light;
  }

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceHover,
    Color? raised,
    Color? selected,
    Color? onSelected,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? actionPrimary,
    Color? actionOnPrimary,
    Color? actionPressed,
    Color? focus,
    Color? borderSubtle,
    Color? borderPlain,
    Color? borderControl,
    Color? dangerForeground,
    Color? dangerBackground,
    Color? neutralBadgeForeground,
    Color? neutralBadgeBackground,
    Color? scrim,
    List<BoxShadow>? raisedShadows,
  }) {
    return AppPalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      raised: raised ?? this.raised,
      selected: selected ?? this.selected,
      onSelected: onSelected ?? this.onSelected,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      actionPrimary: actionPrimary ?? this.actionPrimary,
      actionOnPrimary: actionOnPrimary ?? this.actionOnPrimary,
      actionPressed: actionPressed ?? this.actionPressed,
      focus: focus ?? this.focus,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderPlain: borderPlain ?? this.borderPlain,
      borderControl: borderControl ?? this.borderControl,
      dangerForeground: dangerForeground ?? this.dangerForeground,
      dangerBackground: dangerBackground ?? this.dangerBackground,
      neutralBadgeForeground:
          neutralBadgeForeground ?? this.neutralBadgeForeground,
      neutralBadgeBackground:
          neutralBadgeBackground ?? this.neutralBadgeBackground,
      scrim: scrim ?? this.scrim,
      raisedShadows: raisedShadows ?? this.raisedShadows,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      onSelected: Color.lerp(onSelected, other.onSelected, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      actionPrimary: Color.lerp(actionPrimary, other.actionPrimary, t)!,
      actionOnPrimary: Color.lerp(actionOnPrimary, other.actionOnPrimary, t)!,
      actionPressed: Color.lerp(actionPressed, other.actionPressed, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderPlain: Color.lerp(borderPlain, other.borderPlain, t)!,
      borderControl: Color.lerp(borderControl, other.borderControl, t)!,
      dangerForeground: Color.lerp(dangerForeground, other.dangerForeground, t)!,
      dangerBackground: Color.lerp(dangerBackground, other.dangerBackground, t)!,
      neutralBadgeForeground:
          Color.lerp(neutralBadgeForeground, other.neutralBadgeForeground, t)!,
      neutralBadgeBackground:
          Color.lerp(neutralBadgeBackground, other.neutralBadgeBackground, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      raisedShadows:
          BoxShadow.lerpList(raisedShadows, other.raisedShadows, t) ??
              raisedShadows,
    );
  }
}
