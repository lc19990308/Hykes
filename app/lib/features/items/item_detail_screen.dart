import 'package:material_ui/material_ui.dart';

import '../../core/data/content_bundle.dart';
import '../../core/data/demo_stats.dart';
import '../../core/data/search.dart' show kDemoExcludedItemIds;
import '../../core/state/app_state.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/panels.dart';
import '../../shared/widgets/proto.dart';
import '../../shared/widgets/sections.dart';
import '../champions/champion_detail_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({
    required this.state,
    required this.itemId,
    this.initialOrder = 'all',
    super.key,
  });

  final AppState state;
  final String itemId;
  final String initialOrder;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  static const _orders = [
    ('all', '所有购买顺序'),
    ('1', '第 1 件'),
    ('2', '第 2 件'),
    ('3', '第 3 件'),
    ('4', '第 4 件'),
    ('5', '第 5 件'),
    ('6', '第 6 件'),
  ];
  late String _order;

  @override
  void initState() {
    super.initState();
    _order = _orders.any((option) => option.$1 == widget.initialOrder)
        ? widget.initialOrder
        : 'all';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.state.bundle?.itemById(widget.itemId) != null) {
        widget.state.recordView(EntityType.item, widget.itemId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final bundle = widget.state.bundle;
    final item = bundle?.itemById(widget.itemId);
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(title: const Text('装备详情')),
      body: item == null
          ? _notFound(context)
          : ListView(
              padding: detailPagePadding(context),
              children: [
                DetailHeader(
                  name: item.name,
                  iconPath: item.iconPath,
                  secondary: kItemAttrTags[item.id]?.join(' / ') ?? '装备资料',
                ),
                const SizedBox(height: AppSpacing.s6),
                const NoticeBlock(text: '价格、属性和效果请以游戏客户端为准。'),
                if (kDemoExcludedItemIds.contains(item.id)) ...[
                  const SizedBox(height: AppSpacing.s6),
                  const NoticeBlock(
                    text: '该装备为出门装、药水或鞋子，未纳入成装排行；统计仅在英雄出装关联内展示。',
                  ),
                ],
                const SizedBox(height: AppSpacing.s6),
                ..._performance(item),
                if (!kDemoExcludedItemIds.contains(item.id)) ...[
                  const SizedBox(height: AppSpacing.s6),
                  const SectionHeading(title: '购买顺序表现'),
                  for (final (order, label) in _orders.skip(1))
                    _orderRow(item, order, label),
                ],
                const SizedBox(height: AppSpacing.s6),
                ..._championStats(context, bundle!, item),
                ..._buildRefs(context, bundle, item),
                DetailSources(
                  state: widget.state,
                  sources: bundle.sources,
                  sourceIds: item.sourceIds,
                ),
              ],
            ),
    );
  }

  Widget _notFound(BuildContext context) => Center(
    child: EmptyPanel(
      title: '内容不存在或已移除',
      description: '该装备不在当前数据范围内。',
      action: TextButton(
        onPressed: () => Navigator.of(context).maybePop(),
        child: const Text('返回'),
      ),
    ),
  );

  List<Widget> _performance(Item item) {
    final stat = widget.state.stat('item', item.id, slice: _order);
    return [
      const SectionHeading(title: '装备表现'),
      const SizedBox(height: AppSpacing.s4),
      Row(
        children: [
          Expanded(
            child: DetailSelect(
              label: '购买顺序',
              value: _order,
              options: _orders,
              onChanged: (value) => setState(() => _order = value),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          const Spacer(),
        ],
      ),
      if (stat != null)
        MetricPanel(
          label: _order == 'all' ? '装备总体' : '第 $_order 件购买',
          stat: stat,
        )
      else
        const EmptyBlock(title: '该条件暂无统计', body: '当前条件下尚未整理统计，可切换其他购买顺序查看。'),
      const StatNote('高胜率可能与优势局更易完成装备有关，不能解释为购买收益。'),
    ];
  }

  Widget _orderRow(Item item, String order, String label) {
    final stat = widget.state.stat('item', item.id, slice: order);
    return SliceRow(
      title: label,
      meta: stat?.gamesLabel ?? '样本未知',
      value: stat?.winLabel ?? '暂无统计',
    );
  }

  List<Widget> _championStats(
    BuildContext context,
    ContentBundle bundle,
    Item item,
  ) {
    final relations = widget.state.demoChampionItem.where(
      (record) => record.id == item.id,
    );
    final rows = [
      for (final record in relations)
        if (record.championId case final championId?)
          if (bundle.championById(championId) case final champion?)
            (record, champion),
    ];
    return [
      const SectionHeading(title: '英雄搭配表现'),
      const StatNote('不限顺序 · 演示'),
      if (rows.isEmpty)
        const EmptyBlock(title: '暂无英雄搭配统计', body: '该装备的英雄搭配统计尚未整理；可从英雄出装中查看关联。')
      else
        for (final (index, (record, champion)) in rows.indexed)
          RankRow(
            name: champion.name,
            iconPath: champion.iconPath,
            tagLine: champion.roles.join(' / '),
            stat: detailStatWithRank(record, index + 1),
            leadingIndex: index,
            onTap: () => _openChampion(context, champion.id),
          ),
    ];
  }

  List<Widget> _buildRefs(
    BuildContext context,
    ContentBundle bundle,
    Item item,
  ) {
    final plans = bundle.buildsUsingItem(item.id);
    if (plans.isEmpty) return const [];
    return [
      const SizedBox(height: AppSpacing.s6),
      const SectionHeading(title: '出现在这些出装路线'),
      for (final plan in plans)
        if (bundle.championById(plan.championId) case final champion?)
          MiniLink(
            name: champion.name,
            iconPath: champion.iconPath,
            extra: plan.name,
            onTap: () => _openChampion(context, champion.id),
          ),
    ];
  }

  void _openChampion(BuildContext context, String id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ChampionDetailScreen(state: widget.state, championId: id),
      ),
    );
  }
}
