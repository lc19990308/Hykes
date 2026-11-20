import 'package:material_ui/material_ui.dart';

import '../../core/data/demo_stats.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/panels.dart';
import '../../shared/widgets/proto.dart';
import '../../shared/widgets/prototype_icon.dart';
import '../data_info/data_info_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

typedef _Filter = ({
  String category,
  int? slice,
  String? tier,
  bool low,
  bool known,
  String? attribute,
});
const _defaultFilter = (
  category: '全部',
  slice: null,
  tier: null,
  low: false,
  known: false,
  attribute: null,
);

class RankingPage extends StatefulWidget {
  const RankingPage({
    required this.state,
    required this.type,
    required this.onOpen,
    super.key,
  });

  final AppState state;
  final EntityType type;
  final void Function(BuildContext context, String id, int? slice) onOpen;

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  _Filter _filter = _defaultFilter;
  String _sort = 'rank';

  bool get _isAugment => widget.type == EntityType.augment;
  bool get _isItem => widget.type == EntityType.item;
  bool get _hasSlice => _isAugment || _isItem;
  bool get _snapshot => _isAugment && widget.state.snapshotReady;
  String get _sliceTitle => _isAugment ? '选择阶段' : '购买顺序';
  String _sliceLabel(int n) => _isAugment ? '阶段 $n' : '第 $n 件';

  List<(String, String)> get _categories => _isAugment
      ? const [
          ('全部', '全部'),
          ('silver', '银色'),
          ('gold', '金色'),
          ('prismatic', '棱彩'),
          ('unknown', '待核对'),
        ]
      : [
          for (final role in ['全部', '战士', '法师', '刺客', '射手', '坦克', '辅助'])
            (role, role),
        ];

  Map<String, String> get _sorts => {
    'rank': _snapshot ? '快照名次' : '示例排名',
    'win': '胜率优先',
    'pick': '选取率优先',
    'games': '样本优先',
  };

  List<String> get _active => [
    if (_filter.slice case final n?) _sliceLabel(n),
    if (_filter.tier case final tier?) '$tier 梯队',
    if (_filter.attribute case final attr?) '属性 $attr',
    if (_filter.low) '隐藏低样本',
    if (_filter.known) '仅有统计',
  ];

  List<({String id, String name, String? path, String tags, DemoStat? stat})>
  _rows() {
    final state = widget.state;
    final data = state.bundle;
    if (data == null) return [];
    final f = _filter;
    final pool = switch (widget.type) {
      EntityType.champion => [
        for (final c in data.champions)
          if (f.category == '全部' || c.roles.contains(f.category))
            (
              id: c.id,
              name: c.name,
              path: c.iconPath,
              tags: c.roles.join(' / '),
            ),
      ],
      EntityType.augment => [
        for (final a in data.augments)
          if ((f.category == '全部' || (a.rarity ?? 'unknown') == f.category) &&
              (f.slice == null || a.stages.contains(f.slice)))
            (id: a.id, name: a.name, path: a.iconPath, tags: a.rarityZh),
      ],
      EntityType.item => [
        for (final item in data.items)
          if (state.demoOverallItems.any((s) => s.id == item.id) &&
              (f.category == '全部' ||
                  (kItemRoleTags[item.id]?.contains(f.category) ?? false)) &&
              (f.attribute == null ||
                  (kItemAttrTags[item.id]?.contains(f.attribute) ?? false)))
            (
              id: item.id,
              name: item.name,
              path: item.iconPath,
              tags: (kItemAttrTags[item.id] ?? const ['装备']).join(' / '),
            ),
      ],
    };
    final rows =
        [
          for (final row in pool)
            (
              id: row.id,
              name: row.name,
              path: row.path,
              tags: row.tags,
              stat: state.stat(
                widget.type.storageName,
                row.id,
                slice: f.slice?.toString() ?? 'all',
              ),
            ),
        ]..removeWhere(
          (r) =>
              (f.low && (r.stat?.isLowSample ?? false)) ||
              (f.known && r.stat?.winRatePct == null) ||
              (f.tier != null && (r.stat?.tier ?? '未评级') != f.tier),
        );
    num? value(DemoStat? stat) => switch (_sort) {
      'win' => stat?.winRatePct,
      'pick' => stat?.selectionRatePct,
      'games' => stat?.games,
      _ => stat?.rank,
    };
    rows.sort((a, b) {
      final left = value(a.stat), right = value(b.stat);
      final order = left == null
          ? (right == null ? 0 : 1)
          : right == null
          ? -1
          : _sort == 'rank'
          ? left.compareTo(right)
          : right.compareTo(left);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final palette = AppPalette.of(context);
    final type = widget.type;
    final active = _active;
    final rows = _rows();
    final slice = _filter.slice;
    final countExcluded = _isAugment && slice != null
        ? state.bundle?.augments
                  .where((a) => !a.stages.contains(slice))
                  .length ??
              0
        : 0;
    return Scaffold(
      appBar: AppBar(
        title: Text('${type.labelZh}排行', style: AppTextStyles.pageTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: '设置',
            icon: const PrototypeIcon(PrototypeGlyph.settings),
            onPressed: () => _push(SettingsScreen(state: state)),
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
        LoadPhase.ready => ListView(
          key: PageStorageKey(type),
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width <= 374
                ? AppSpacing.s4
                : AppSpacing.s5,
            AppSpacing.s5,
            MediaQuery.sizeOf(context).width <= 374
                ? AppSpacing.s4
                : AppSpacing.s5,
            AppSpacing.s6,
          ),
          children: [
            SearchEntry(
              label: type == EntityType.champion
                  ? '搜索英雄、称号或拼音'
                  : '搜索${type.labelZh}',
              showLabel: false,
              onTap: () => _push(SearchScreen(state: state, initialType: type)),
            ),
            const SizedBox(height: AppSpacing.s4),
            Row(
              children: [
                Expanded(
                  child: CategoryTabs(
                    options: _categories,
                    selected: _filter.category,
                    onSelected: (value) => setState(
                      () => _filter = (
                        category: value,
                        slice: _filter.slice,
                        tier: _filter.tier,
                        low: _filter.low,
                        known: _filter.known,
                        attribute: _filter.attribute,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '筛选选项',
                  onPressed: _openFilters,
                  icon: const PrototypeIcon(PrototypeGlyph.filters),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _openSort,
                  style: TextButton.styleFrom(
                    foregroundColor: palette.textSecondary,
                    padding: EdgeInsets.zero,
                    textStyle: AppTextStyles.meta,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_sorts[_sort]!),
                      const SizedBox(width: AppSpacing.s1),
                      const PrototypeIcon(PrototypeGlyph.next, size: 16),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _openFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: palette.textSecondary,
                    padding: EdgeInsets.zero,
                    textStyle: AppTextStyles.meta,
                    minimumSize: const Size(
                      AppLayout.touchTarget,
                      AppLayout.touchTarget,
                    ),
                  ),
                  child: Text(active.isEmpty ? '筛选' : '筛选 · ${active.length}'),
                ),
              ],
            ),
            const Divider(),
            if (active.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      active.join(' · '),
                      style: AppTextStyles.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                  TextButton(onPressed: _reset, child: const Text('清除')),
                ],
              ),
            if (_snapshot && state.segmentOptions.length > 1) ...[
              const SizedBox(height: AppSpacing.s2),
              FilterChipRow<String>(
                options: state.segmentOptions
                    .map((s) => (s.segment, s.labelZh))
                    .toList(),
                selected: state.segment,
                onSelected: (v) {
                  if (v != null) state.setSegment(v);
                },
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.s4,
                bottom: AppSpacing.s2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${rows.length} 项 · ${slice == null ? '总体' : _sliceLabel(slice)}'
                      '${countExcluded > 0 ? ' · 另有 $countExcluded 项未收录该阶段' : ''}'
                      ' · ${_snapshot ? state.segmentLabel : '演示'}',
                      style: AppTextStyles.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    '胜率',
                    style: AppTextStyles.caption.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (rows.isEmpty) ...[
              const EmptyBlock(title: '没有符合条件的结果', body: '试试其他名称，或清除筛选条件。'),
              ElevatedButton(onPressed: _reset, child: const Text('重置搜索与筛选')),
            ],
            for (final (index, row) in rows.indexed)
              RankRow(
                name: row.name,
                iconPath: row.path,
                tagLine: row.tags,
                stat: row.stat,
                leadingIndex: index,
                tier: row.stat == null ? null : row.stat!.tier ?? '',
                snapshot: _snapshot,
                onTap: () => widget.onOpen(context, row.id, slice),
              ),
            TextButton(
              onPressed: () => _push(DataInfoScreen(state: state)),
              child: const Text('查看统计口径与覆盖范围'),
            ),
          ],
        ),
      },
    );
  }

  void _push(Widget screen) =>
      Navigator.of(context)
          .push<void>(MaterialPageRoute(builder: (_) => screen));
  void _reset() => setState(() {
    _filter = _defaultFilter;
    _sort = 'rank';
  });

  Future<void> _openSort() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppPalette.of(context).raised,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('排序方式', style: AppTextStyles.sectionTitle),
            ),
            for (final entry in _sorts.entries)
              ListTile(
                title: Text(entry.value),
                trailing: entry.key == _sort
                    ? const PrototypeIcon(PrototypeGlyph.check)
                    : null,
                onTap: () => Navigator.pop(context, entry.key),
              ),
          ],
        ),
      ),
    );
    if (mounted && selected != null) setState(() => _sort = selected);
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_Filter>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppPalette.of(context).raised,
      builder: (context) => _FilterSheet(
        initial: _filter,
        categories: _categories,
        categoryTitle: _isAugment
            ? '强化稀有度'
            : _isItem
            ? '英雄职业'
            : '英雄定位',
        sliceTitle: _sliceTitle,
        slices: _hasSlice
            ? [
                (null, '全部'),
                for (var i = 1; i <= (_isAugment ? 4 : 6); i++)
                  (i, _sliceLabel(i)),
              ]
            : const [],
        showAttributes: _isItem,
      ),
    );
    if (mounted && result != null) setState(() => _filter = result);
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.categories,
    required this.categoryTitle,
    required this.sliceTitle,
    required this.slices,
    required this.showAttributes,
  });

  final _Filter initial;
  final List<(String, String)> categories;
  final String categoryTitle;
  final String sliceTitle;
  final List<(int?, String)> slices;
  final bool showAttributes;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late var draft = widget.initial;

  void _update({
    String? category,
    int? slice,
    bool replaceSlice = false,
    String? tier,
    bool replaceTier = false,
    bool? low,
    bool? known,
    String? attribute,
    bool replaceAttribute = false,
  }) => setState(
    () => draft = (
      category: category ?? draft.category,
      slice: replaceSlice ? slice : draft.slice,
      tier: replaceTier ? tier : draft.tier,
      low: low ?? draft.low,
      known: known ?? draft.known,
      attribute: replaceAttribute ? attribute : draft.attribute,
    ),
  );

  Widget _group<T>(
    String title,
    List<(T, String)> options,
    T? value,
    ValueChanged<T?> select,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.s4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.itemTitle),
        const SizedBox(height: AppSpacing.s2),
        FilterChipRow<T>(
          options: options,
          selected: value,
          onSelected: select,
          columns: 3,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .75,
      child: Column(
        children: [
          ListTile(
            title: const Text('筛选', style: AppTextStyles.sectionTitle),
            trailing: IconButton(
              tooltip: '关闭，不应用修改',
              icon: const PrototypeIcon(PrototypeGlyph.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
              children: [
                _group(
                  widget.categoryTitle,
                  widget.categories,
                  draft.category,
                  (v) => _update(category: v ?? '全部'),
                ),
                if (widget.showAttributes)
                  _group<String?>(
                    '属性',
                    [(null, '全部'), for (final a in kItemAttrs) (a, a)],
                    draft.attribute,
                    (v) => _update(attribute: v, replaceAttribute: true),
                  ),
                if (widget.slices.isNotEmpty)
                  _group(
                    widget.sliceTitle,
                    widget.slices,
                    draft.slice,
                    (v) => _update(
                      slice: v,
                      replaceSlice: true,
                      replaceTier: true,
                    ),
                  ),
                _group<String?>(
                  '梯队',
                  const [
                    (null, '全部'),
                    ('S', 'S'),
                    ('A', 'A'),
                    ('B', 'B'),
                    ('C', 'C'),
                    ('D', 'D'),
                    ('未评级', '未评级'),
                  ],
                  draft.tier,
                  (v) => _update(tier: v, replaceTier: true),
                ),
                SwitchListTile(
                  title: const Text('隐藏已知低样本'),
                  subtitle: const Text('少于 200 场；未知样本仍保留'),
                  value: draft.low,
                  onChanged: (v) => _update(low: v),
                ),
                SwitchListTile(
                  title: const Text('仅看有统计'),
                  subtitle: const Text('隐藏暂无胜率的内容'),
                  value: draft.known,
                  onChanged: (v) => _update(known: v),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => draft = _defaultFilter),
                    child: const Text('重置'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, draft),
                    child: const Text('查看结果'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
