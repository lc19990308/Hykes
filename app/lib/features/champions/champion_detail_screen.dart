import 'package:material_ui/material_ui.dart';

import '../../core/data/content_bundle.dart';
import '../../core/data/demo_stats.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/object_row.dart';
import '../../shared/widgets/panels.dart';
import '../../shared/widgets/proto.dart';
import '../../shared/widgets/sections.dart';
import '../augments/augment_detail_screen.dart';
import '../data_info/data_info_screen.dart';
import '../items/item_detail_screen.dart';

/// 英雄详情默认展示概览，强化和出装各自保留筛选条件。
class ChampionDetailScreen extends StatefulWidget {
  const ChampionDetailScreen({
    required this.state,
    required this.championId,
    super.key,
  });

  final AppState state;
  final String championId;

  @override
  State<ChampionDetailScreen> createState() => _ChampionDetailScreenState();
}

class _ChampionDetailScreenState extends State<ChampionDetailScreen> {
  int _section = 0;
  String _augmentStage = 'all';
  String _augmentRarity = 'all';
  String _augmentSort = 'win';
  String _buildOrder = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.state.bundle?.championById(widget.championId) != null) {
        widget.state.recordView(EntityType.champion, widget.championId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final bundle = widget.state.bundle;
    final champion = bundle?.championById(widget.championId);
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        // 短页标题；对象完整名称在正文详情头展示（C01）。
        title: const Text('英雄详情'),
      ),
      body: champion == null
          ? _notFound(context)
          : ListView(
              padding: detailPagePadding(context),
              children: [
                DetailHeader(
                  name: champion.name,
                  iconPath: champion.iconPath,
                  secondary: champion.title,
                  meta: champion.roles.join(' / '),
                  favorite: (widget.state, EntityType.champion, champion.id),
                ),
                const SizedBox(height: AppSpacing.s6),
                _sectionTabs(context),
                const SizedBox(height: AppSpacing.s6),
                switch (_section) {
                  0 => _overview(context, bundle!, champion),
                  1 => _augments(context, bundle!, champion),
                  _ => _builds(context, bundle!, champion),
                },
                DetailSources(
                  state: widget.state,
                  sources: bundle.sources,
                  sourceIds: champion.sourceIds,
                ),
              ],
            ),
    );
  }

  /// PRD §14「对象不存在」：不写历史、返回来源。
  Widget _notFound(BuildContext context) {
    return Center(
      child: EmptyPanel(
        title: '内容不存在或已移除',
        description: '该英雄不在当前数据范围内。',
        action: TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('返回'),
        ),
      ),
    );
  }

  /// C03 三分区标签：等宽、选中墨色下划线；分区切换不重置滚动外的状态。
  Widget _sectionTabs(BuildContext context) {
    final palette = AppPalette.of(context);
    const labels = ['概览', '强化', '出装'];
    return Row(
      children: [
        for (final (index, label) in labels.indexed)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _section = index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AppLayout.touchTarget + 4,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _section == index
                          ? palette.textPrimary
                          : palette.borderSubtle,
                      width: _section == index
                          ? AppStroke.selected
                          : AppStroke.defaultWidth,
                    ),
                  ),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: _section == index
                        ? palette.textPrimary
                        : palette.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _overview(
    BuildContext context,
    ContentBundle bundle,
    Champion champion,
  ) {
    final palette = AppPalette.of(context);
    final spells = [
      for (final id in champion.summonerSpells) ?bundle.summonerSpellById(id),
    ];
    final balanceBadges = Wrap(
      spacing: AppSpacing.s2,
      children: [
        if (champion.balanceStatus == 'pending') const PendingBadge(),
        if (champion.isStale) const StaleBadge(),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MetricPanel(
          label: '英雄总体',
          stat: widget.state.stat('champion', champion.id),
        ),
        const SizedBox(height: AppSpacing.s6),
        SectionHeading(
          title: '玩法概览',
          badge: champion.overviewIsExample ? const ExampleBadge() : null,
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          champion.overview ?? '暂无玩法概览',
          style: AppTextStyles.body.copyWith(color: palette.textPrimary),
        ),
        const SizedBox(height: AppSpacing.s6),
        _subheading(context, '模式调整', badge: balanceBadges),
        const SizedBox(height: AppSpacing.s6),
        NoticeBlock(text: champion.balanceNote ?? '暂无调整记录'),
        const SizedBox(height: AppSpacing.s6),
        _subheading(
          context,
          '技能加点',
          badge: champion.skillPriorityIsExample ? const ExampleBadge() : null,
        ),
        if (champion.skillPriority case final skillPriority?) ...[
          const SizedBox(height: AppSpacing.s3),
          Text(
            skillPriority,
            style: AppTextStyles.sectionTitle.copyWith(
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            champion.skillPriorityNote ?? '按技能优先级加点。',
            style: AppTextStyles.meta.copyWith(color: palette.textMuted),
          ),
        ],
        const SizedBox(height: AppSpacing.s6),
        _subheading(
          context,
          '召唤师技能',
          badge: champion.summonerSpellsIsExample ? const ExampleBadge() : null,
        ),
        const SizedBox(height: AppSpacing.s3),
        if (spells.isEmpty)
          Text(
            '暂未整理召唤师技能建议',
            style: AppTextStyles.meta.copyWith(color: palette.textMuted),
          )
        else
          Wrap(
            spacing: AppSpacing.s4,
            runSpacing: AppSpacing.s2,
            children: [
              for (final spell in spells)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ObjectImage(path: spell.iconPath, size: 40),
                    const SizedBox(width: AppSpacing.s2),
                    Text(
                      spell.name,
                      style: AppTextStyles.body.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        if (champion.summonerSpellNote case final spellNote?) ...[
          const SizedBox(height: AppSpacing.s3),
          Text(
            spellNote,
            style: AppTextStyles.body.copyWith(color: palette.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _subheading(BuildContext context, String title, {Widget? badge}) =>
      Wrap(
        spacing: AppSpacing.s2,
        runSpacing: AppSpacing.s1,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            title,
            style: AppTextStyles.itemTitle.copyWith(
              color: AppPalette.of(context).textPrimary,
            ),
          ),
          ?badge,
        ],
      );

  Widget _augments(
    BuildContext context,
    ContentBundle bundle,
    Champion champion,
  ) {
    final state = widget.state;
    final palette = AppPalette.of(context);
    final links = bundle.augmentsForChampion(champion.id)
      ..sort(
        (a, b) => (a.recommendationOrder ?? 99).compareTo(
          b.recommendationOrder ?? 99,
        ),
      );
    final records = _augmentStage == 'all'
        ? state.demoChampionAugment
        : state.demoChampionAugmentStage;
    final byId = {
      for (final record in records)
        if (record.championId == champion.id &&
            (_augmentStage == 'all' || record.stage == _augmentStage))
          record.id: record,
    };
    final rows =
        [
          for (final link in links)
            if (bundle.augmentById(link.augmentId) case final augment?)
              if (_augmentRarity == 'all' || augment.rarity == _augmentRarity)
                (augment, byId[augment.id]),
        ]..sort((a, b) {
          double? score(DemoStat? stat) => _augmentSort == 'pick'
              ? stat?.selectionRatePct
              : stat?.winRatePct;
          final byScore = (score(b.$2) ?? -1).compareTo(score(a.$2) ?? -1);
          return byScore == 0 ? a.$1.id.compareTo(b.$1.id) : byScore;
        });
    final baseline = state.stat('champion', champion.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(title: '英雄搭配表现'),
        StatNote(
          '${champion.name} × 海克斯 · ${_augmentStage == 'all' ? '所有阶段' : '阶段 $_augmentStage'} · 演示',
        ),
        _filterGrid([
          DetailSelect(
            label: '统计阶段',
            value: _augmentStage,
            options: const [
              ('all', '所有阶段'),
              ('1', '阶段 1'),
              ('2', '阶段 2'),
              ('3', '阶段 3'),
              ('4', '阶段 4'),
            ],
            onChanged: (value) => setState(() => _augmentStage = value),
          ),
          DetailSelect(
            label: '稀有度',
            value: _augmentRarity,
            options: const [
              ('all', '全部'),
              ('prismatic', '棱彩'),
              ('gold', '金色'),
              ('silver', '银色'),
            ],
            onChanged: (value) => setState(() => _augmentRarity = value),
          ),
          DetailSelect(
            label: '排序',
            value: _augmentSort,
            options: const [('win', '搭配胜率'), ('pick', '搭配选取率')],
            onChanged: (value) => setState(() => _augmentSort = value),
          ),
        ]),
        if (rows.isEmpty)
          const StatNote('暂无搭配统计，人工推荐仍可阅读。')
        else
          for (final (index, (augment, stat)) in rows.indexed)
            RankRow(
              name: augment.name,
              iconPath: augment.iconPath,
              tagLine: augment.rarityZh,
              stat: stat,
              leadingIndex: index,
              note: detailChampionDelta(stat, baseline),
              onTap: () =>
                  _openAugment(context, augment.id, stage: _augmentStage),
            ),
        const StatNote('基准为英雄总体胜率（同快照 · 模拟口径）；无统计的关系不参与排序，显示暂无统计。'),
        const SizedBox(height: AppSpacing.s6),
        const SectionHeading(title: '人工推荐'),
        const SizedBox(height: AppSpacing.s3),
        Text(
          '结合英雄玩法与触发条件选择，人工顺序不代表统计结论。',
          style: AppTextStyles.meta.copyWith(color: palette.textMuted),
        ),
        if (links.isEmpty)
          EmptyPanel(
            title: '暂未整理该英雄的强化推荐',
            description: '可以先到海克斯排行浏览全部强化。',
            action: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('返回浏览'),
            ),
          )
        else
          for (final link in links) _augmentRow(context, bundle, link),
      ],
    );
  }

  void _openAugment(BuildContext context, String id, {String stage = 'all'}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AugmentDetailScreen(
          state: widget.state,
          augmentId: id,
          initialStage: stage,
        ),
      ),
    );
  }

  Widget _filterGrid(List<Widget> fields) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.s4),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.s3) / 2;
        return Wrap(
          spacing: AppSpacing.s3,
          runSpacing: AppSpacing.s3,
          children: [
            for (final field in fields) SizedBox(width: width, child: field),
          ],
        );
      },
    ),
  );

  Widget _augmentRow(
    BuildContext context,
    ContentBundle bundle,
    ChampionAugment link,
  ) {
    final palette = AppPalette.of(context);
    final augment = bundle.augmentById(link.augmentId);
    if (augment == null) {
      // 引用失效：局部提示，其余内容保持可读（PRD §14）。
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s5,
          vertical: AppSpacing.s2,
        ),
        child: Text(
          '一条强化引用待补充（ID：${link.augmentId}）',
          style: AppTextStyles.meta.copyWith(color: palette.textMuted),
        ),
      );
    }
    return InkWell(
      onTap: () => _openAugment(context, augment.id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.borderSubtle)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ObjectImage(path: augment.iconPath, size: 40),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.s2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        augment.name,
                        style: AppTextStyles.itemTitle.copyWith(
                          color: palette.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      NeutralBadge(augment.rarityZh),
                      if (link.isExample) const ExampleBadge(),
                    ],
                  ),
                  if (link.reason != null) ...[
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      link.reason!,
                      style: AppTextStyles.meta.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                  if (link.caution != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '注意：${link.caution!}',
                      style: AppTextStyles.meta.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _builds(
    BuildContext context,
    ContentBundle bundle,
    Champion champion,
  ) {
    final plans = bundle.buildsForChampion(champion.id);
    if (plans.isEmpty) {
      return const EmptyBlock(title: '暂未整理出装方案', body: '该英雄暂无人工示例路线。');
    }
    final state = widget.state;
    final records =
        (_buildOrder == 'all'
                ? state.demoChampionItem
                : state.demoChampionItemOrder)
            .where(
              (record) =>
                  record.championId == champion.id &&
                  (_buildOrder == 'all' || record.order == _buildOrder),
            );
    final rows = [
      for (final record in records)
        if (bundle.itemById(record.id) case final item?) (record, item),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, plan) in plans.indexed) ...[
          if (index != 0) const SizedBox(height: AppSpacing.s6),
          ..._buildPlan(context, bundle, plan),
        ],
        const SizedBox(height: AppSpacing.s6),
        const SectionHeading(title: '英雄装备统计'),
        StatNote(
          '${champion.name} × 装备 · ${_buildOrder == 'all' ? '不限制购买顺序' : '第 $_buildOrder 件购买'} · 演示',
        ),
        _filterGrid([
          DetailSelect(
            label: '购买顺序',
            value: _buildOrder,
            options: [
              ('all', '不限制顺序'),
              for (var order = 1; order <= 6; order++) ('$order', '第 $order 件'),
            ],
            onChanged: (value) => setState(() => _buildOrder = value),
          ),
        ]),
        if (rows.isEmpty)
          const EmptyBlock(
            title: '该购买顺序暂无统计',
            body: '该英雄在此购买顺序下尚未整理统计，可切换其他顺序查看。',
          )
        else
          for (final (index, (record, item)) in rows.indexed)
            RankRow(
              name: item.name,
              iconPath: item.iconPath,
              tagLine: kItemRoleTags[item.id]?.join(' / ') ?? '装备资料',
              stat: record,
              leadingIndex: index,
              onTap: () => _openItem(context, item.id, order: _buildOrder),
            ),
        const SizedBox(height: AppSpacing.s6),
        const NoticeBlock(text: '当前模式价格、库存与可购买性待核对，以客户端为准。'),
      ],
    );
  }

  List<Widget> _buildPlan(
    BuildContext context,
    ContentBundle bundle,
    BuildPlan plan,
  ) {
    final palette = AppPalette.of(context);
    final secondary = AppTextStyles.body.copyWith(color: palette.textSecondary);
    final meta = AppTextStyles.meta.copyWith(color: palette.textMuted);
    return [
      _subheading(
        context,
        plan.name,
        badge: plan.isExample ? const NeutralBadge('示例出装，仅供练习') : null,
      ),
      if (plan.intent case final intent?) ...[
        const SizedBox(height: AppSpacing.s3),
        Text(intent, style: secondary),
      ],
      const SizedBox(height: AppSpacing.s6),
      _subheading(context, '出门装'),
      const SizedBox(height: AppSpacing.s2),
      for (final item in plan.startingItems)
        _equipment(context, bundle, item.itemId, quantity: item.quantity),
      if (plan.boots case final boots?) ...[
        const SizedBox(height: AppSpacing.s6),
        _subheading(context, '鞋子'),
        const SizedBox(height: AppSpacing.s2),
        _equipment(context, bundle, boots.itemId),
        if (boots.condition case final condition?) Text(condition, style: meta),
      ],
      const SizedBox(height: AppSpacing.s6),
      _subheading(context, '核心三件 · 购买顺序'),
      const SizedBox(height: AppSpacing.s2),
      for (final (index, id) in plan.coreItemIds.indexed)
        _equipment(context, bundle, id, order: index + 1),
      if (plan.alternatives.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s6),
        _subheading(context, '条件替换'),
        for (final alternative in plan.alternatives) ...[
          const SizedBox(height: AppSpacing.s6),
          if (alternative.condition case final condition?)
            Text(condition, style: secondary),
          Text(
            '替换 ${bundle.itemById(alternative.replaceItemId)?.name ?? '待补充'}',
            style: meta,
          ),
          _equipment(context, bundle, alternative.withItemId),
        ],
      ],
      if (plan.note case final note?) ...[
        const SizedBox(height: AppSpacing.s2),
        Text(note, style: meta),
      ],
    ];
  }

  Widget _equipment(
    BuildContext context,
    ContentBundle bundle,
    String id, {
    int? order,
    int? quantity,
  }) {
    final palette = AppPalette.of(context);
    final meta = AppTextStyles.meta.copyWith(color: palette.textMuted);
    final item = bundle.itemById(id);
    if (item == null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s6),
        child: Text('装备未收录，方案内容待补充（ID：$id）。', style: meta),
      );
    }
    return InkWell(
      onTap: () => _openItem(context, item.id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.borderSubtle)),
        ),
        child: Row(
          children: [
            if (order != null) ...[
              SizedBox(
                width: AppSpacing.s8,
                child: Text('$order', style: meta, textAlign: TextAlign.center),
              ),
              const SizedBox(width: AppSpacing.s3),
            ],
            ObjectImage(path: item.iconPath, size: 40),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                item.name,
                style: AppTextStyles.body.copyWith(color: palette.textPrimary),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            if (quantity != null)
              Text('×$quantity', style: meta)
            else
              Icon(Icons.chevron_right, size: 20, color: palette.textMuted),
          ],
        ),
      ),
    );
  }

  void _openItem(BuildContext context, String id, {String order = 'all'}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(
          state: widget.state,
          itemId: id,
          initialOrder: order,
        ),
      ),
    );
  }
}

// Reused by the three detail routes so their header, filters and footer align.
EdgeInsets detailPagePadding(BuildContext context) {
  final horizontal = MediaQuery.sizeOf(context).width < 375
      ? AppLayout.pagePaddingCompact
      : AppLayout.pagePadding;
  return EdgeInsets.fromLTRB(
    horizontal,
    AppSpacing.s5 + AppSpacing.s6,
    horizontal,
    AppSpacing.s8,
  );
}

class DetailHeader extends StatelessWidget {
  const DetailHeader({
    required this.name,
    required this.iconPath,
    this.secondary,
    this.meta,
    this.favorite,
    super.key,
  });

  final String name;
  final String? iconPath;
  final String? secondary;
  final String? meta;
  final (AppState, EntityType, String)? favorite;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (iconPath?.isNotEmpty ?? false) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: ObjectImage(path: iconPath, size: 64),
              ),
              const SizedBox(width: AppSpacing.s4),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                  if (secondary case final subtitle?) ...[
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      subtitle,
                      style: AppTextStyles.body.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                  if (meta case final metadata?)
                    Text(
                      metadata,
                      style: AppTextStyles.meta.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (favorite case (final state, final type, final id)) ...[
          const SizedBox(height: AppSpacing.s4),
          ListenableBuilder(
            listenable: state,
            builder: (context, _) => FavoriteButton(
              type: type,
              id: id,
              state: state,
              objectName: name,
            ),
          ),
        ],
      ],
    );
  }
}

class DetailSelect extends StatelessWidget {
  const DetailSelect({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.small),
      borderSide: BorderSide(color: palette.borderControl),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.meta.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s1),
        InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: palette.surface,
            border: border,
            enabledBorder: border,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s2,
            ),
          ),
          child: Semantics(
            label: label,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: options.any((option) => option.$1 == value)
                    ? value
                    : null,
                isExpanded: true,
                style: AppTextStyles.body.copyWith(color: palette.textPrimary),
                items: [
                  for (final (key, name) in options)
                    DropdownMenuItem(value: key, child: Text(name)),
                ],
                onChanged: (next) {
                  if (next != null) onChanged(next);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DetailSources extends StatelessWidget {
  const DetailSources({
    required this.state,
    required this.sources,
    required this.sourceIds,
    super.key,
  });

  final AppState state;
  final List<SourceEntry> sources;
  final List<String> sourceIds;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final links = sources
        .where(
          (source) =>
              sourceIds.contains(source.id) &&
              (source.url?.startsWith('https://') ?? false),
        )
        .toList();
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.s6),
      padding: const EdgeInsets.only(top: AppSpacing.s4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: palette.textSecondary,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DataInfoScreen(state: state)),
            ),
            child: const Text('数据说明'),
          ),
          if (links.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              title: Text(
                '查看内容来源',
                style: AppTextStyles.meta.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              children: [
                for (final source in links)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                    child: SelectableText(
                      [?source.title, source.url!].join('\n'),
                      style: AppTextStyles.meta.copyWith(
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

DemoStat detailStatWithRank(DemoStat stat, int rank) => DemoStat(
  id: stat.id,
  rank: rank,
  wins: stat.wins,
  games: stat.games,
  winRatePct: stat.winRatePct,
  selectionRatePct: stat.selectionRatePct,
  tier: stat.tier,
  stage: stat.stage,
  order: stat.order,
  championId: stat.championId,
);

String? detailChampionDelta(DemoStat? stat, DemoStat? baseline) {
  final win = stat?.winRatePct;
  final base = baseline?.winRatePct;
  if (win == null || base == null) return null;
  final delta = win - base;
  return '较英雄基准 ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} 个百分点';
}
