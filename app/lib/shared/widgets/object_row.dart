import 'package:material_ui/material_ui.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import 'sections.dart';

/// 榜单名次（C04 等宽数字，前三加重）。mock 阶段承载「示例排名」语义，
/// 不得标「来源排名」（PRD §4.2）；真实快照接入后由来源 rank 字段替代。
class RankNumber extends StatelessWidget {
  const RankNumber({required this.order, super.key});

  final int order;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SizedBox(
      width: 24,
      child: Text(
        '$order',
        textAlign: TextAlign.center,
        style: AppTextStyles.meta.copyWith(
          color: palette.textPrimary,
          fontWeight: order <= 3 ? FontWeight.w600 : FontWeight.w400,
          fontFeatures: [const FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// C04 对象行通用入参：图标 + 名称 + 副行；右侧内容按场景拼装。
class ObjectRow extends StatelessWidget {
  const ObjectRow({
    required this.iconPath,
    required this.name,
    required this.subline,
    required this.onTap,
    this.trailing,
    this.leading,
    this.showChevron = true,
    super.key,
  });

  final String? iconPath;
  final String name;
  final String? subline;
  final VoidCallback? onTap;

  /// 右侧附加信息（如查看日期、统计占位）。
  final Widget? trailing;

  /// 左侧名次/序号（等宽数字，C04 rank 行）。
  final Widget? leading;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5, vertical: AppSpacing.s3),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.s3)],
            ObjectImage(path: iconPath, size: 40),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.itemTitle
                        .copyWith(color: palette.textPrimary)
                        // 16/24 列表名（C04：名称与胜率优先，不挤压）
                        .copyWith(fontSize: 16, height: 24 / 16),
                  ),
                  if (subline != null && subline!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subline!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppTextStyles.meta.copyWith(color: palette.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.s2),
              trailing!,
            ],
            if (showChevron && onTap != null) ...[
              const SizedBox(width: AppSpacing.s1),
              Icon(Icons.chevron_right, size: 20, color: palette.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

/// 收藏按钮（C08）：线性书签 +「收藏 / 已收藏」；
/// 已收藏为 surface 底 + 主色文字与主色边界；操作即时生效。
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    required this.type,
    required this.id,
    required this.state,
    required this.objectName,
    super.key,
  });

  final EntityType type;
  final String id;
  final AppState state;

  /// 读屏名称描述动作，如「收藏亚索」（设计体系 §6）。
  final String objectName;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final active = state.isFavorite(type, id);
    final label = active ? '已收藏' : '收藏';
    return Semantics(
      button: true,
      label: active ? '取消收藏$objectName' : '收藏$objectName',
      child: OutlinedButton.icon(
        onPressed: () => state.toggleFavorite(type, id),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 44),
          backgroundColor: active ? palette.surface : null,
          side: BorderSide(color: active ? palette.actionPrimary : palette.borderControl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
          foregroundColor: active ? palette.actionPrimary : palette.textPrimary,
          textStyle: AppTextStyles.label.copyWith(
            color: active ? palette.actionPrimary : palette.textPrimary,
          ),
        ),
        icon: Icon(
          active ? Icons.bookmark : Icons.bookmark_border,
          size: 18,
          color: active ? palette.actionPrimary : palette.textSecondary,
        ),
        label: Text(label),
      ),
    );
  }
}
