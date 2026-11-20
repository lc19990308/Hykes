import 'package:material_ui/material_ui.dart';

import '../../core/data/content_bundle.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/panels.dart';
import '../../shared/widgets/proto.dart';
import '../../shared/widgets/sections.dart';
import '../champions/champion_detail_screen.dart';

class AugmentDetailScreen extends StatefulWidget {
  const AugmentDetailScreen({
    required this.state,
    required this.augmentId,
    this.initialStage = 'all',
    super.key,
  });

  final AppState state;
  final String augmentId;
  final String initialStage;

  @override
  State<AugmentDetailScreen> createState() => _AugmentDetailScreenState();
}

class _AugmentDetailScreenState extends State<AugmentDetailScreen> {
  static const _stages = [
    ('all', '所有阶段'),
    ('1', '阶段 1'),
    ('2', '阶段 2'),
    ('3', '阶段 3'),
    ('4', '阶段 4'),
  ];
  late String _stage;

  @override
  void initState() {
    super.initState();
    _stage = _stages.any((option) => option.$1 == widget.initialStage)
        ? widget.initialStage
        : 'all';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.state.bundle?.augmentById(widget.augmentId) != null) {
        widget.state.recordView(EntityType.augment, widget.augmentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final bundle = widget.state.bundle;
    final augment = bundle?.augmentById(widget.augmentId);
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(title: const Text('海克斯详情')),
      body: augment == null
          ? _notFound(context)
          : ListenableBuilder(
              listenable: widget.state,
              builder: (context, _) => ListView(
                padding: detailPagePadding(context),
                children: [
                  DetailHeader(
                    name: augment.name,
                    iconPath: augment.iconPath,
                    secondary: augment.rarityZh,
                    favorite: (widget.state, EntityType.augment, augment.id),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  ..._effect(context, augment),
                  const SizedBox(height: AppSpacing.s6),
                  ..._performance(augment),
                  const SizedBox(height: AppSpacing.s6),
                  ..._stageRows(augment),
                  const SizedBox(height: AppSpacing.s6),
                  ..._championLinks(context, bundle!, augment),
                  DetailSources(
                    state: widget.state,
                    sources: bundle.sources,
                    sourceIds: augment.sourceIds,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _notFound(BuildContext context) {
    return Center(
      child: EmptyPanel(
        title: '内容不存在或已移除',
        description: '该海克斯不在当前数据范围内。',
        action: TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('返回'),
        ),
      ),
    );
  }

  List<Widget> _effect(BuildContext context, Augment augment) {
    final palette = AppPalette.of(context);
    return [
      SectionHeading(
        title: '海克斯效果',
        badge: augment.isStale ? const StaleBadge() : null,
      ),
      const SizedBox(height: AppSpacing.s6),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          augment.effectText ?? '效果待核对',
          style: AppTextStyles.body.copyWith(color: palette.textPrimary),
        ),
      ),
      const SizedBox(height: AppSpacing.s6),
      NoticeBlock(
        text: [
          if (augment.effectStatus == 'pending' || augment.effectText == null)
            '效果待核对。',
          ?augment.effectNote,
          '具体机制请以当前客户端为准。',
        ].join('\n'),
      ),
    ];
  }

  List<Widget> _performance(Augment augment) {
    final state = widget.state;
    final snapshot = state.snapshot;
    final stat = state.stat('augment', augment.id, slice: _stage);
    final unavailable =
        _stage != 'all' && !augment.stages.contains(int.parse(_stage));
    return [
      const SectionHeading(title: '胜率与选择阶段'),
      const SizedBox(height: AppSpacing.s4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DetailSelect(
              label: '统计阶段',
              value: _stage,
              options: _stages,
              onChanged: (value) => setState(() => _stage = value),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          if (state.segmentOptions.isEmpty)
            const Spacer()
          else
            Expanded(
              child: DetailSelect(
                label: '统计口径',
                value: state.segment,
                options: [
                  for (final option in state.segmentOptions)
                    (option.segment, option.labelZh),
                ],
                onChanged: state.setSegment,
              ),
            ),
        ],
      ),
      if (snapshot != null)
        StatNote(
          '总体与阶段统计来自 ${snapshot.gamePatch} 研究快照 · ${state.segmentLabel}；缺口显示暂无统计，不以总体值填充。',
        ),
      if (unavailable)
        const EmptyBlock(title: '该阶段未收录为可出现阶段', body: '这是来源资料中的阶段范围，当前客户端仍待核对。')
      else if (stat == null)
        const EmptyBlock(title: '暂无统计', body: '当前条件下尚未整理统计。')
      else
        MetricPanel(
          label: _stage == 'all' ? '海克斯总体' : '阶段 $_stage',
          stat: stat,
          snapshot: snapshot != null,
          segmentLabel: snapshot != null ? state.segmentLabel : null,
        ),
      StatNote(
        augment.stages.isEmpty
            ? '出现范围待核对。'
            : '出现范围：${augment.stages.map((stage) => '阶段 $stage').join(' / ')}，当前版本待核对。',
      ),
    ];
  }

  List<Widget> _stageRows(Augment augment) {
    final state = widget.state;
    return [
      const SectionHeading(title: '各阶段表现'),
      for (final (stage, label) in _stages.skip(1))
        _stageRow(augment, stage, label),
      StatNote(
        '各阶段单独统计，不同阶段表现可能有差异${state.snapshotReady ? ' · 研究快照 · ${state.segmentLabel}' : ''}。',
      ),
    ];
  }

  Widget _stageRow(Augment augment, String stage, String label) {
    final state = widget.state;
    final available = augment.stages.contains(int.parse(stage));
    final stat = state.stat('augment', augment.id, slice: stage);
    final win = stat?.winRatePct;
    return SliceRow(
      title: label,
      meta: available ? stat?.gamesLabel ?? '样本未知' : '未收录为可出现',
      value: !available
          ? '—'
          : win == null
          ? '暂无统计'
          : state.snapshotReady
          ? '$win%'
          : stat!.winLabel,
    );
  }

  List<Widget> _championLinks(
    BuildContext context,
    ContentBundle bundle,
    Augment augment,
  ) {
    final state = widget.state;
    final records =
        state.demoChampionAugment
            .where((record) => record.id == augment.id)
            .toList()
          ..sort((a, b) => (b.winRatePct ?? -1).compareTo(a.winRatePct ?? -1));
    final rows = [
      for (final record in records)
        if (record.championId case final championId?)
          if (bundle.championById(championId) case final champion?)
            (record, champion),
    ];
    final manualOnly = bundle
        .championsForAugment(augment.id)
        .where(
          (link) =>
              !records.any((record) => record.championId == link.championId),
        );
    return [
      const SectionHeading(title: '英雄搭配表现'),
      const StatNote('所有阶段 · 演示'),
      if (rows.isEmpty)
        const EmptyBlock(title: '暂未整理适配英雄的统计', body: '效果仍可阅读，未录入统计不代表不适配。')
      else
        for (final (index, (record, champion)) in rows.indexed)
          RankRow(
            name: champion.name,
            iconPath: champion.iconPath,
            tagLine: champion.roles.join(' / '),
            stat: detailStatWithRank(record, index + 1),
            note: detailChampionDelta(
              record,
              state.stat('champion', champion.id),
            ),
            leadingIndex: index,
            onTap: () => _openChampion(context, champion.id),
          ),
      for (final link in manualOnly)
        if (bundle.championById(link.championId) case final champion?)
          MiniLink(
            name: champion.name,
            iconPath: champion.iconPath,
            extra: link.reason == null
                ? '人工推荐 · 暂无统计'
                : '人工推荐 · 暂无统计\n${link.reason}',
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
