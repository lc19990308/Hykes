import 'package:material_ui/material_ui.dart';

import '../../core/data/augment_snapshot.dart';
import '../../core/data/content_bundle.dart';
import '../../core/data/demo_stats.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/panels.dart';
import '../../shared/widgets/proto.dart';
import '../../shared/widgets/prototype_icon.dart';
import '../../shared/widgets/sections.dart';
import '../augments/augment_detail_screen.dart';
import '../champions/champion_detail_screen.dart';
import '../data_info/data_info_screen.dart';
import '../items/item_detail_screen.dart';
import '../match/match_screen.dart';
import '../recents/recents_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/update_center_screen.dart';

/// 「查看全部」跳根页签而非压栈（PRD §2.2：根入口切换不反复堆叠首页）。
typedef TabSwitcher = void Function(int index);

/// 首页（R01，原型 home() 逐块对齐）：
/// 口径行 → 品牌语区 → 统计口径切换 → 搜索/离线内容/对局助手 → 地图环境 →
/// 三类前五摘要 → 趣味榜单（快照派生）→ 最近查看。
class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.state, required this.onSwitchTab, super.key});

  final AppState state;
  final TabSwitcher onSwitchTab;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final bundle = state.bundle;
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 76,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '海克斯大乱斗速查',
              style: AppTextStyles.navLabel.copyWith(color: palette.textMuted),
            ),
            const Text('海斗宝典', style: AppTextStyles.pageTitle),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '设置',
            onPressed: () => _push(context, SettingsScreen(state: state)),
            icon: const PrototypeIcon(PrototypeGlyph.settings),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: switch (state.phase) {
        LoadPhase.loading => const Center(child: Text('正在加载本地数据')),
        LoadPhase.failed => FailurePanel(
          message: '本地数据加载失败',
          onRetry: state.loadBundle,
        ),
        LoadPhase.ready when bundle != null => _HomeBody(
          state: state,
          bundle: bundle,
          onSwitchTab: onSwitchTab,
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.state,
    required this.bundle,
    required this.onSwitchTab,
  });

  final AppState state;
  final ContentBundle bundle;
  final TabSwitcher onSwitchTab;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final snap = state.snapshot;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s5,
        AppSpacing.s5,
        AppSpacing.s6,
      ),
      children: [
        // 口径行（原型 scope()）。
        ScopeLine(
          main: snap == null
              ? '海克斯大乱斗'
              : '海克斯大乱斗 · 版本 ${snap.gamePatch} 研究快照 · 更新 ${snap.sourceUpdatedAt ?? '未知'}',
          meta: snap == null ? '榜单为演示值' : '来源为站方公开页面快照 · 授权未核验，仅限本地研究',
          onInfo: () => _push(context, DataInfoScreen(state: state)),
        ),
        const ScopeBlock(
          brand: '对局前看环境，选择时查搭配',
          title: '这一局，从这里开始',
          secondary: '英雄、强化与出装，随手查一眼。',
        ),
        // 统计口径切换（仅快照就绪时，PRD R15）。
        if (snap != null && state.segmentOptions.length > 1) ...[
          Text(
            '统计口径',
            style: AppTextStyles.meta.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: 8),
          _SegmentChips(state: state),
          const StatNote('分段仅适用于海克斯榜'),
          const SizedBox(height: 24),
        ],
        // 搜索 + 离线内容 + 对局助手入口。
        SearchEntry(
          label: '搜英雄、海克斯、装备',
          onTap: () => _push(
            context,
            SearchScreen(state: state, initialType: EntityType.champion),
          ),
        ),
        SnapshotEntry(
          title: '离线内容已就绪',
          meta: '整理日期 ${bundle.dataset.compiledAt?.split('T').first ?? '未知'}',
          onTap: () => _push(context, UpdateCenterScreen(state: state)),
        ),
        MatchEntry(bundle: bundle, prefs: state.prefs),
        _mapEnvironment(context),
        _rankSection(
          context,
          title: '英雄排行',
          caption: snap == null ? '总体' : '总体 · 演示',
          rows: _homeRows(EntityType.champion),
        ),
        _rankSection(
          context,
          title: '海克斯排行',
          caption: state.snapshotReady
              ? '所有阶段 · 研究快照 · ${state.segmentLabel}'
              : '所有阶段',
          rows: _homeRows(EntityType.augment),
        ),
        _rankSection(
          context,
          title: '装备排行',
          caption: snap == null ? '不限顺序' : '不限顺序 · 演示',
          rows: _homeRows(EntityType.item),
        ),
        _funBoards(context, snap),
        _recentsSection(context),
      ],
    );
  }

  List<Widget> _homeRows(EntityType type) {
    final stats = state.homeStats(type.storageName);
    return [
      for (final (index, stat) in stats.indexed)
        Builder(
          builder: (context) {
            final id = stat.id;
            switch (type) {
              case EntityType.champion:
                final champion = bundle.championById(id);
                if (champion == null) return const SizedBox.shrink();
                return RankRow(
                  name: champion.name,
                  iconPath: champion.iconPath,
                  tagLine: champion.roles.join(' / '),
                  stat: stat,
                  leadingIndex: index,
                  tier: stat.tier ?? '',
                  onTap: () => _open(context, type, id),
                );
              case EntityType.augment:
                final augment = bundle.augmentById(id);
                if (augment == null) return const SizedBox.shrink();
                final snapAugment =
                    state.snapshot?.byId(id) ??
                    state.snapshot?.byName(augment.name);
                return RankRow(
                  name: augment.name,
                  iconPath: snapAugment?.iconLocalPath ?? augment.iconPath,
                  tagLine: augment.rarityZh,
                  stat: stat,
                  leadingIndex: index,
                  tier: stat.tier ?? '',
                  snapshot: state.snapshotReady,
                  onTap: () => _open(context, type, id),
                );
              case EntityType.item:
                final item = bundle.itemById(id);
                if (item == null) return const SizedBox.shrink();
                return RankRow(
                  name: item.name,
                  iconPath: item.iconPath,
                  tagLine: (kItemAttrTags[id] ?? const ['装备']).join(' / '),
                  stat: stat,
                  leadingIndex: index,
                  tier: stat.tier ?? '',
                  onTap: () => _open(context, type, id),
                );
            }
          },
        ),
    ];
  }

  void _open(BuildContext context, EntityType type, String id) {
    switch (type) {
      case EntityType.champion:
        _push(context, ChampionDetailScreen(state: state, championId: id));
      case EntityType.augment:
        _push(context, AugmentDetailScreen(state: state, augmentId: id));
      case EntityType.item:
        _push(context, ItemDetailScreen(state: state, itemId: id));
    }
  }

  /// R17 地图环境（原型 mapEnv）：示例内容徽标 + content-group。
  Widget _mapEnvironment(BuildContext context) {
    const tips = [
      ('单线兵线，推塔定节奏', '一条中路直通双方基地，没有野区与分带空间；防御塔与兵线的推进节奏决定团战发生的位置。'),
      ('治疗祭坛，轮换争夺', '地图两侧的祭坛会周期性提供恢复，靠近祭坛的一方更容易把血线优势转化为团战先手。'),
      ('全员快速发育', '起始等级较高、金币随时间被动增长，装备与技能成型更早，前中期就是主要对抗窗口。'),
      ('地形狭窄，站位即战术', '桥面与墙角的视野有限，先手开团与远程消耗空间小；留意绕后与贴脸突进的风险。'),
    ];
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(title: '地图环境', badge: const ExampleBadge()),
          const SizedBox(height: 12),
          Text(
            '大乱斗地图的环境要点，人工示例内容；具体数值与当前版本以游戏客户端为准。',
            style: AppTextStyles.meta.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: 16),
          for (final (heading, body) in tips)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: palette.borderSubtle)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading,
                    style: AppTextStyles.itemTitle.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: AppTextStyles.body.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _rankSection(
    BuildContext context, {
    required String title,
    required String caption,
    required List<Widget> rows,
  }) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: title,
            trailing: TextButton(
              onPressed: () => onSwitchTab(switch (title) {
                '英雄排行' => 1,
                '海克斯排行' => 2,
                _ => 3,
              }),
              child: const Text('全部'),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    caption,
                    style: AppTextStyles.caption
                        .copyWith(fontSize: 13, height: 20 / 13)
                        .copyWith(color: palette.textMuted),
                  ),
                ),
                Text(
                  '胜率',
                  style: AppTextStyles.caption
                      .copyWith(fontSize: 13, height: 20 / 13)
                      .copyWith(color: palette.textMuted),
                ),
              ],
            ),
          ),
          ...rows,
        ],
      ),
    );
  }

  /// C20/R18 趣味榜单（快照派生三榜，原型 funBoards 原样）。
  Widget _funBoards(BuildContext context, AugmentSnapshot? snap) {
    if (snap == null) return const SizedBox.shrink();
    final palette = AppPalette.of(context);
    final snapshotId = snap.snapshotIdOf(state.segment);
    final pool = snap.stats
        .where(
          (s) => s.snapshotId == snapshotId && s.scopeType == 'augment-overall',
        )
        .toList();
    if (pool.isEmpty) return const SizedBox.shrink();
    final pick = [...pool]
      ..sort((a, b) => (b.pickRatePct ?? -1).compareTo(a.pickRatePct ?? -1));
    final topPick = pick.take(3).toList();
    final prismIds = {
      for (final a in snap.augments)
        if (a.rarity == 'prismatic') a.id,
    };
    final cold = [...pool.where((s) => prismIds.contains(s.augmentId))]
      ..sort((a, b) => (a.pickRatePct ?? 999).compareTo(b.pickRatePct ?? 999));
    final topCold = cold.take(3).toList();
    final gap =
        [
          ...pool.where(
            (s) => s.blueWinRatePct != null && s.redWinRatePct != null,
          ),
        ]..sort((a, b) {
          final da = (a.blueWinRatePct! - a.redWinRatePct!).abs();
          final db = (b.blueWinRatePct! - b.redWinRatePct!).abs();
          return db.compareTo(da);
        });
    final topGap = gap.take(3).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(title: '趣味榜单', badge: const NeutralBadge('研究快照')),
          const SizedBox(height: 12),
          Text(
            '由 ${snap.gamePatch} 研究快照派生 · 当前口径：${state.segmentLabel} · 非模拟数值 · 行仅供阅读。',
            style: AppTextStyles.meta.copyWith(color: palette.textSecondary),
          ),
          _funBoard(
            context,
            '选取率最高的海克斯',
            '总体选取率',
            topPick,
            '派生规则：按当前分段海克斯总体选取率降序取前三，数值为研究快照原样收录；选取率口径未确认。',
            null,
          ),
          _funBoard(
            context,
            '最冷门棱彩',
            '总体选取率',
            topCold,
            '派生规则：棱彩海克斯中按总体选取率升序取前三；选取率口径未确认。',
            null,
          ),
          _funBoard(
            context,
            '蓝红方胜率差最大',
            '蓝 / 红方胜率',
            topGap,
            '派生规则：按总体蓝方与红方胜率差的绝对值降序取前三。',
            'gap',
          ),
        ],
      ),
    );
  }

  Widget _funBoard(
    BuildContext context,
    String title,
    String rightLabel,
    List<SnapshotStat> stats,
    String rule,
    String? kind,
  ) {
    final snap = state.snapshot!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.itemTitle.copyWith(
                  color: paletteText(context),
                ),
              ),
            ),
            Text(
              rightLabel,
              style: AppTextStyles.caption
                  .copyWith(fontSize: 13, height: 20 / 13)
                  .copyWith(color: paletteText(context)),
            ),
          ],
        ),
        for (final (index, stat) in stats.indexed)
          Builder(
            builder: (context) {
              final augment = snap.byId(stat.augmentId);
              if (augment == null) return const SizedBox.shrink();
              final right = kind == 'gap'
                  ? '蓝 ${stat.blueWinRatePct}%\n红 ${stat.redWinRatePct}%'
                  : '${stat.pickRatePct}%';
              return RankRow(
                name: augment.name,
                iconPath: augment.iconLocalPath,
                tagLine: _rarityZh(augment.rarity),
                stat: DemoStat(
                  id: augment.id,
                  rank: index + 1,
                  wins: null,
                  games: stat.sampleCount,
                  winRatePct: stat.winRatePct,
                  selectionRatePct: stat.pickRatePct,
                  tier: stat.tier,
                ),
                leadingIndex: index,
                winLabel: kind == 'gap' ? right : '${stat.pickRatePct}%',
                gamesLabel:
                    '${_fmtCount(stat.sampleCount)} 场${(stat.sampleCount ?? 0) < 200 ? ' · 样本较少' : ''}',
              );
            },
          ),
        StatNote(rule),
      ],
    );
  }

  Widget _recentsSection(BuildContext context) {
    final palette = AppPalette.of(context);
    final recent = state.recents.take(3).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: '最近查看',
            trailing: TextButton(
              onPressed: () => _push(context, RecentsScreen(state: state)),
              child: const Text('全部'),
            ),
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Text(
              '查看详情后，可在这里接着看。',
              style: AppTextStyles.body.copyWith(color: palette.textSecondary),
            )
          else
            for (final record in recent)
              Builder(
                builder: (context) {
                  final info = state.describe(record.type, record.id);
                  if (info == null) return const SizedBox.shrink();
                  return MiniLink(
                    name: info.name,
                    iconPath: info.iconPath,
                    onTap: () => _open(context, record.type, record.id),
                  );
                },
              ),
        ],
      ),
    );
  }
}

/// 统计口径 chips（墨底选中，原型 select 生成形态）。
class _SegmentChips extends StatelessWidget {
  const _SegmentChips({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in state.segmentOptions)
          InkWell(
            onTap: () => state.setSegment(option.segment),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: state.segment == option.segment
                    ? palette.textPrimary
                    : Colors.transparent,
                border: Border.all(color: palette.borderSubtle),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.segment == option.segment) ...[
                    Icon(Icons.check, size: 16, color: palette.canvas),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    option.labelZh,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 14,
                      fontWeight: state.segment == option.segment
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: state.segment == option.segment
                          ? palette.canvas
                          : palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

Color paletteText(BuildContext context) => AppPalette.of(context).textPrimary;

String _rarityZh(String? rarity) => switch (rarity) {
  'prismatic' => '棱彩',
  'gold' => '金色',
  'silver' => '银色',
  _ => '待核对',
};

String _fmtCount(int? value) {
  if (value == null) return '样本未知';
  final s = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    out.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) out.write(',');
  }
  return out.toString();
}

void _push(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}
