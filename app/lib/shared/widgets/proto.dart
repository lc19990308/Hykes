import 'package:material_ui/material_ui.dart';

import '../../core/data/demo_stats.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import 'prototype_icon.dart';
import 'sections.dart';

/// 原型视觉组件（app-v1.css / index.html 内层样式逐参数对齐）。
/// 数值均来自设计稿实测：rank-row 20/44/1fr/auto、metric 2×2 strong 28/36、
/// scope 13/22、chip 14/pill、stat-note 14/24 muted 等。

// ─────────────────────────── rank-row ───────────────────────────

/// 榜单行（.rank-row）：grid 20px 44px minmax(0,1fr) auto，gap 12，
/// padding-block 14，底部分隔 border-soft；rank-index mono 16（前三 fg-2 600）；
/// 名称 16/600；meta 13/20 muted；右侧 rank-value 17/600 mono。
class RankRow extends StatelessWidget {
  const RankRow({
    required this.name,
    required this.iconPath,
    required this.tagLine,
    required this.stat,
    this.leadingIndex,
    this.tier,
    this.selectionLabel,
    this.winLabel,
    this.gamesLabel,
    this.note,
    this.onTap,
    this.snapshot = false,
    super.key,
  });

  final String name;
  final String? iconPath;
  final String tagLine;

  /// 演示/快照统计（null → 全部「—/暂无统计」）。
  final DemoStat? stat;

  /// 行序（原型 rankRow 的 index 参数，前三 leading 加重）。
  final int? leadingIndex;
  final String? tier;
  final String? selectionLabel;
  final String? winLabel;
  final String? gamesLabel;
  final String? note;
  final VoidCallback? onTap;

  /// 快照行：胜率原样精度、选取率标「口径未确认」。
  final bool snapshot;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final s = stat;
    final win =
        winLabel ??
        (s?.winRatePct == null
            ? '—'
            : snapshot
            ? '${_fmtWin(s!.winRatePct!)}%'
            : s!.winLabel);
    final games =
        gamesLabel ??
        (s == null
            ? '暂无统计'
            : s.winRatePct == null
            ? '暂无统计'
            : s.gamesLabel + (s.isLowSample ? ' · 样本较少' : ''));
    final selection =
        selectionLabel ??
        (s?.selectionRatePct == null
            ? '暂无统计'
            : snapshot
            ? '${_fmtWin(s!.selectionRatePct!)}% · 口径未确认'
            : '选取 ${s!.selectionLabel}');
    final tierBadge = tier == null
        ? null
        : (tier!.isEmpty ? const _TierText() : _TierBadge(value: tier!));
    final isLeading = (leadingIndex ?? 99) < 3;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.borderSubtle)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              child: Text(
                s == null || s.rank <= 0 ? '—' : '${s.rank}',
                textAlign: TextAlign.center,
                style: AppTextStyles.meta.copyWith(
                  fontSize: 16,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isLeading ? palette.textSecondary : palette.textMuted,
                  fontWeight: isLeading ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ObjectImage(path: iconPath, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.itemTitle.copyWith(
                      color: palette.textPrimary,
                      fontSize: 16,
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tagLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption
                              .copyWith(fontSize: 13, height: 20 / 13)
                              .copyWith(color: palette.textMuted),
                        ),
                      ),
                      if (tierBadge != null) ...[
                        const SizedBox(width: 6),
                        tierBadge,
                      ],
                    ],
                  ),
                  Text(
                    selection,
                    style: AppTextStyles.caption
                        .copyWith(fontSize: 13, height: 20 / 13)
                        .copyWith(color: palette.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  win,
                  style: AppTextStyles.itemTitle.copyWith(
                    color: palette.textPrimary,
                    fontSize: 17,
                    height: 28 / 17,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  games,
                  style: AppTextStyles.caption
                      .copyWith(fontSize: 13, height: 20 / 13)
                      .copyWith(color: palette.textMuted),
                ),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    note!,
                    style: AppTextStyles.caption
                        .copyWith(fontSize: 13, height: 20 / 13)
                        .copyWith(color: palette.textMuted),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtWin(double v) {
  // 快照胜率原样精度（19.3：4 位小数百分比原样，如 57.41）。
  var text = v.toString();
  if (text.contains('.')) {
    text = text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return text;
}

/// .tier 徽标：min 24、边框、radius 4、14/22；S 档 fg 加重边框。
class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isTop = value == 'S';
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: isTop ? palette.borderPlain : palette.borderSubtle,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: AppTextStyles.caption.copyWith(
          fontSize: 14,
          height: 22 / 14,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}

class _TierText extends StatelessWidget {
  const _TierText();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Text(
      '未评级',
      style: AppTextStyles.caption.copyWith(
        fontSize: 13,
        height: 20 / 13,
        color: palette.textMuted,
      ),
    );
  }
}

// ─────────────────────────── metric 面板 ───────────────────────────

/// 详情统计（.stats-context + .summary-stats 2×2 + .stat-note）。
class MetricPanel extends StatelessWidget {
  const MetricPanel({
    required this.label,
    required this.stat,
    this.snapshot = false,
    this.segmentLabel,
    super.key,
  });

  final String label;
  final DemoStat? stat;
  final bool snapshot;
  final String? segmentLabel;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final s = stat;
    Widget cell(String value, String caption) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.stat.copyWith(
            color: palette.textPrimary,
            fontSize: 28,
            height: 36 / 28,
          ),
        ),
        Text(
          caption,
          style: AppTextStyles.meta.copyWith(color: palette.textMuted),
        ),
      ],
    );
    final provenance = snapshot
        ? '研究快照 · ${segmentLabel ?? ''} · 选取率口径未确认'
        : '演示';
    final noteLine = [
      s == null ? '样本未知' : s.gamesLabel,
      if (s?.wins != null && s?.games != null) '${s!.wins} 胜',
      if (s?.isLowSample ?? false) '样本较少',
      if (s != null) provenance,
    ].where((part) => part.isNotEmpty).join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          label,
          style: AppTextStyles.meta.copyWith(color: palette.textSecondary),
        ),
        Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: palette.borderSubtle),
              bottom: BorderSide(color: palette.borderSubtle),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: cell(
                      s == null || s.rank <= 0 ? '—' : '${s.rank}',
                      '名次',
                    ),
                  ),
                  Expanded(child: cell(s?.tier ?? '未评级', '梯队')),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: cell(
                      s?.winRatePct == null
                          ? '暂无统计'
                          : snapshot
                          ? '${_fmtWin(s!.winRatePct!)}%'
                          : s!.winLabel,
                      '胜率',
                    ),
                  ),
                  Expanded(
                    child: cell(
                      s?.selectionRatePct == null
                          ? '暂无统计'
                          : snapshot
                          ? '${_fmtWin(s!.selectionRatePct!)}%'
                          : s!.selectionLabel,
                      '选取率',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          noteLine,
          style: AppTextStyles.meta.copyWith(
            color: palette.textMuted,
            height: 24 / 14,
          ),
        ),
      ],
    );
  }
}

/// .slice-row：阶段/顺序表现行，strong 20 mono。
class SliceRow extends StatelessWidget {
  const SliceRow({
    required this.title,
    required this.meta,
    required this.value,
    super.key,
  });

  final String title;
  final String meta;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  meta,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 13,
                    height: 20 / 13,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: AppTextStyles.sectionTitle.copyWith(
              color: palette.textPrimary,
              fontSize: 20,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// .stat-note：14/24 muted。
class StatNote extends StatelessWidget {
  const StatNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        style: AppTextStyles.meta.copyWith(
          color: palette.textMuted,
          height: 24 / 14,
        ),
      ),
    );
  }
}

// ─────────────────────────── 首页区块 ───────────────────────────

/// .scope-line：两行 13/22 + 底部分隔 + info 按钮。
class ScopeLine extends StatelessWidget {
  const ScopeLine({
    required this.main,
    required this.meta,
    this.onInfo,
    super.key,
  });

  final String main;
  final String meta;
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            main,
            style: AppTextStyles.caption
                .copyWith(fontSize: 13, height: 22 / 13)
                .copyWith(color: palette.textSecondary),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  meta,
                  style: AppTextStyles.caption
                      .copyWith(fontSize: 13, height: 22 / 13)
                      .copyWith(color: palette.textMuted),
                ),
              ),
              if (onInfo != null)
                GestureDetector(
                  onTap: onInfo,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: PrototypeIcon(
                      PrototypeGlyph.info,
                      size: 16,
                      color: palette.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// .scope-block：brand 13 muted + 标题 28/1.25 + secondary 15/1.6。
class ScopeBlock extends StatelessWidget {
  const ScopeBlock({
    required this.brand,
    required this.title,
    required this.secondary,
    super.key,
  });

  final String brand;
  final String title;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            brand,
            style: AppTextStyles.caption
                .copyWith(fontSize: 13, height: 22 / 13)
                .copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.pageTitle.copyWith(
              color: palette.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            secondary,
            style: AppTextStyles.label.copyWith(
              color: palette.textSecondary,
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// 首页搜索入口（.search-entry：52 高 surface radius 12）。
class SearchEntry extends StatelessWidget {
  const SearchEntry({
    required this.label,
    required this.onTap,
    this.showLabel = true,
    super.key,
  });

  final bool showLabel;

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          children: [
            PrototypeIcon(PrototypeGlyph.search, color: palette.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: palette.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (showLabel)
              Text(
                '搜索',
                style: AppTextStyles.meta.copyWith(color: palette.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

/// .snapshot-entry：min 64 行分隔 + chevron。
class SnapshotEntry extends StatelessWidget {
  const SnapshotEntry({
    required this.title,
    required this.meta,
    this.onTap,
    this.trailing,
    super.key,
  });

  final String title;
  final String meta;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.borderSubtle)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.label.copyWith(
                      color: palette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 13,
                      height: 20 / 13,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right, size: 20, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

/// .category-tab：min 44，选中墨色文字 + 2px 墨色下划线 + 600。
class CategoryTabs extends StatelessWidget {
  const CategoryTabs({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Wrap(
      spacing: AppSpacing.s2,
      runSpacing: AppSpacing.s2,
      children: [
        for (final (value, label) in options)
          GestureDetector(
            onTap: () => onSelected(value),
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected == value
                        ? palette.textPrimary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.label.copyWith(
                  fontSize: 14,
                  fontWeight: selected == value
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: selected == value
                      ? palette.textPrimary
                      : palette.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// .mini-link：64 高 pic 40 分隔。
class MiniLink extends StatelessWidget {
  const MiniLink({
    required this.name,
    required this.iconPath,
    required this.onTap,
    this.extra,
    super.key,
  });

  final String name;
  final String? iconPath;
  final VoidCallback onTap;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.borderSubtle)),
        ),
        child: Row(
          children: [
            ObjectImage(path: iconPath, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.itemTitle.copyWith(
                      color: palette.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  if (extra != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      extra!,
                      style: AppTextStyles.meta.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

/// .empty：padding 32 上下、标题 + 副文。
class EmptyBlock extends StatelessWidget {
  const EmptyBlock({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.sectionTitle.copyWith(
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: AppTextStyles.body.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// .notice：surface 底 radius 8 padding 12/16 14/22。
class NoticeBlock extends StatelessWidget {
  const NoticeBlock({required this.text, this.danger = false, super.key});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        text,
        style: AppTextStyles.meta.copyWith(
          color: danger ? palette.dangerBackground : palette.textSecondary,
        ),
      ),
    );
  }
}
