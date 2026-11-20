import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import 'prototype_icon.dart';

/// C03 筛选胶囊标签：最小高 44、水平内边距 12、间距 8、可换行；
/// 未选 surface 底 + border.control + 次级文字；选中墨底白字（夜间浅底深字）
/// + 勾选标记。单选；全选项名统一「全部」。
class FilterChipRow<T> extends StatelessWidget {
  const FilterChipRow({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.columns,
    this.allowWrap = true,
    super.key,
  });

  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final int? columns;
  final bool allowWrap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final children = [
      for (final (value, label) in options)
        _Chip(
          label: label,
          selected: selected == value,
          palette: palette,
          onTap: () => onSelected(selected == value ? null : value),
        ),
    ];
    final count = columns;
    if (count == null) {
      if (!allowWrap) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.s2,
          children: children,
        );
      }
      return Wrap(
        spacing: AppSpacing.s2,
        runSpacing: AppSpacing.s2,
        children: children,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            ((constraints.maxWidth - (count - 1) * AppSpacing.s2) / count)
                .floorToDouble();
        return Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppLayout.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
          decoration: BoxDecoration(
            color: selected ? palette.selected : palette.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? palette.selected : palette.borderControl,
            ),
          ),
          child: Center(
            widthFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  PrototypeIcon(
                    PrototypeGlyph.check,
                    size: 16,
                    color: palette.onSelected,
                  ),
                  const SizedBox(width: AppSpacing.s1),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.meta.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? palette.onSelected
                          : palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// C11 加载失败：标题、说明、单一「重试」按钮；不循环自动重试。
class FailurePanel extends StatelessWidget {
  const FailurePanel({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: AppSpacing.s4),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(minimumSize: const Size(96, 48)),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

/// C11 空列表：标题、原因、单一恢复入口；不放大插画占屏。
class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    required this.title,
    required this.description,
    this.action,
    super.key,
  });

  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: AppSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.itemTitle.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            description,
            style: AppTextStyles.meta.copyWith(color: palette.textMuted),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.s4),
            action!,
          ],
        ],
      ),
    );
  }
}

/// C11 无条件统计占位：原统计位置显示「暂无统计」，不显示 0 或空白（C10）。
class NoStatsText extends StatelessWidget {
  const NoStatsText({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Text(
      '暂无统计',
      style: AppTextStyles.meta.copyWith(color: palette.textMuted),
    );
  }
}
