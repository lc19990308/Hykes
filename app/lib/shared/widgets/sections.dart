import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';

/// 游戏对象图标：保持固有比例完整包含，不拉伸裁切；
/// 缺图/加载失败移除图片列，不显示破图位（设计体系 §6、PRD §14）。
class ObjectImage extends StatelessWidget {
  const ObjectImage({required this.path, this.size = 40, super.key});

  /// 传入 null 直接不渲染图片列（无图对象不伪造图像）。
  final String? path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved = path;
    if (resolved == null || resolved.isEmpty) {
      return SizedBox(width: size, height: size);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Image.asset(
        resolved,
        width: size,
        height: size,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
      ),
    );
  }
}

/// C01 根页头部：左侧眉标（navLabel）+ 页面标题（pageTitle），
/// 右侧最多一个操作（首页为设置；设计体系 C01/C05）。
class RootHeader extends StatelessWidget {
  const RootHeader({required this.title, this.eyebrow, this.action, super.key});

  final String title;
  final String? eyebrow;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final eyebrowText = eyebrow;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s3,
        AppSpacing.s2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrowText != null)
                  Text(
                    eyebrowText,
                    style: AppTextStyles.navLabel.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  title,
                  style: AppTextStyles.pageTitle.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// 内容分区标题行：sectionTitle + 可选徽标 + 右侧文本动作（C13 榜单页样式）。
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    required this.title,
    this.badge,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget? badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final badgeWidget = badge;
    final trailingWidget = trailing;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.sectionTitle.copyWith(
              color: palette.textPrimary,
            ),
          ),
        ),
        ?badgeWidget,
        if (badgeWidget != null) const SizedBox(width: AppSpacing.s2),
        ?trailingWidget,
      ],
    );
  }
}

/// 榜单/摘要说明行：caption 尺寸的条件与口径说明（C13 结果计数行）。
class RankingCaption extends StatelessWidget {
  const RankingCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: palette.textMuted),
      ),
    );
  }
}

/// 独立内容卡（radius.group）：一屏可有多张；夜间用提升面成对值。
class ContentGroup extends StatelessWidget {
  const ContentGroup({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.group),
      ),
      child: child,
    );
  }
}
