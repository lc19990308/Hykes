import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/content_bundle.dart';
import '../../core/data/search.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/object_row.dart';
import '../../shared/widgets/proto.dart';
import '../../shared/widgets/prototype_icon.dart';
import '../../shared/widgets/sections.dart';
import 'match_content.dart';
import 'match_store.dart';

/// Keeps the session available when the panel is closed, including if saving
/// failed. The store only uses the supplied local bundle and preferences.
class MatchEntry extends StatefulWidget {
  const MatchEntry({required this.bundle, required this.prefs, super.key});

  final ContentBundle bundle;
  final SharedPreferences? prefs;

  @override
  State<MatchEntry> createState() => _MatchEntryState();
}

class _MatchEntryState extends State<MatchEntry> {
  MatchStore? _store;
  bool _isOpen = false;
  final _entryFocus = FocusScopeNode(debugLabel: '对局助手入口');

  Future<void> _open() async {
    if (_isOpen) return;
    _isOpen = true;
    if (!_entryFocus.hasFocus) _entryFocus.nextFocus();
    final store = _store ??= MatchStore(widget.bundle, widget.prefs);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      enableDrag: false,
      barrierColor: AppPalette.of(context).scrim,
      backgroundColor: Colors.transparent,
      builder: (_) => _MatchPanel(store: store),
    );
    _isOpen = false;
    if (mounted) _entryFocus.requestFocus();
  }

  @override
  void didUpdateWidget(covariant MatchEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bundle != oldWidget.bundle || widget.prefs != oldWidget.prefs) {
      _store = null;
    }
  }

  @override
  void dispose() {
    _entryFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusScope(
    node: _entryFocus,
    child: SnapshotEntry(
      title: '对局助手',
      meta: '离线手录 · 本局英雄、海克斯与出装',
      trailing: Icon(
        Icons.auto_awesome,
        size: 22,
        color: AppPalette.of(context).textSecondary,
      ),
      onTap: _open,
    ),
  );
}

enum _Page { quick, full, record, champion, owned, candidates }

enum _Tab {
  play('怎么玩'),
  augments('拿什么'),
  build('怎么出装');

  const _Tab(this.title);
  final String title;
}

class _MatchPanel extends StatefulWidget {
  const _MatchPanel({required this.store});

  final MatchStore store;

  @override
  State<_MatchPanel> createState() => _MatchPanelState();
}

class _MatchPanelState extends State<_MatchPanel> {
  _Page _page = _Page.quick;
  _Page _pickerBack = _Page.quick;
  _Tab _tab = _Tab.play;
  String _query = '';
  Set<String> _draft = {};
  String? _pickWarning;
  bool _saving = false;

  ContentBundle get _bundle => widget.store.bundle;
  MatchRecord get _record => widget.store.record;
  Champion? get _champion {
    final id = _record.championId;
    return id == null ? null : _bundle.championById(id);
  }

  String _names(Iterable<String> ids) =>
      ids.map((id) => _bundle.augmentById(id)?.name).nonNulls.join('、');

  void _showTab(_Tab tab) => setState(() {
    _page = _Page.full;
    _tab = tab;
  });

  void _openPicker(_Page page) => setState(() {
    _pickerBack = _page;
    _page = page;
    _query = '';
    _pickWarning = null;
    _draft = switch (page) {
      _Page.owned => _record.owned.toSet(),
      _Page.candidates => _record.candidates.toSet(),
      _ => {},
    };
  });

  void _back() => setState(() {
    FocusScope.of(context).unfocus();
    _page = switch (_page) {
      _Page.champion || _Page.owned || _Page.candidates => _pickerBack,
      _ => _Page.quick,
    };
    _query = '';
  });

  Future<void> _save(MatchRecord next, {_Page? page, _Tab? tab}) async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.store.save(next);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _page = page ?? _page;
      _tab = tab ?? _tab;
      if (page != null) _query = '';
    });
  }

  Future<bool> _confirm(
    String title,
    String message, {
    String action = '确认录入',
  }) async {
    FocusScope.of(context).unfocus();
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppPalette.of(dialogContext).raised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.group),
            ),
            title: Text(title),
            content: Text(message),
            scrollable: true,
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _selectChampion(Champion champion) async {
    if (_record.championId != null && _record.championId != champion.id) {
      final confirmed = await _confirm(
        '确认更换英雄？',
        '英雄：${champion.name}\n更换英雄会清除原来的已选强化、候选与防守选择。',
      );
      if (!mounted || !confirmed) return;
    }
    FocusScope.of(context).unfocus();
    await _save(
      _record.selectChampion(champion.id),
      page: _Page.quick,
      tab: _Tab.play,
    );
  }

  Future<void> _take(Augment augment) async {
    if (_record.owned.contains(augment.id) ||
        _record.owned.length >= matchOwnedLimit) {
      return;
    }
    final confirmed = await _confirm(
      '确认本轮选择？',
      '将「${augment.name}」加入已选海克斯，并清空本轮候选。',
    );
    if (!mounted || !confirmed) return;
    await _save(_record.take(augment.id), tab: _Tab.play);
  }

  Future<void> _end() async {
    final confirmed = await _confirm(
      '结束并清空当前本局？',
      '结束时会清除当前英雄、已选强化、候选与防守选择；收藏和浏览历史保留。',
      action: '结束本局',
    );
    if (!mounted || !confirmed) return;
    await _save(const MatchRecord.empty(), page: _Page.quick, tab: _Tab.play);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isQuick = _page == _Page.quick;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final champion = _champion;
    final title = switch (_page) {
      _Page.champion => '这局玩谁？',
      _Page.owned => '已选海克斯',
      _Page.candidates => '录入候选',
      _Page.record => '录入海克斯',
      _ => '对局助手',
    };
    return PopScope<void>(
      canPop: isQuick && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving && !isQuick) _back();
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            width: double.infinity,
            height:
                constraints.maxHeight * (isQuick && keyboard == 0 ? .78 : 1),
            child: Material(
              color: palette.canvas,
              borderRadius: isQuick
                  ? const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.sheet),
                    )
                  : BorderRadius.zero,
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.wideBodyMaxWidth,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s3,
                            vertical: AppSpacing.s2,
                          ),
                          child: Row(
                            children: [
                              if (!isQuick)
                                IconButton(
                                  tooltip: '返回对局助手',
                                  onPressed: _saving ? null : _back,
                                  icon: const PrototypeIcon(
                                    PrototypeGlyph.previous,
                                  ),
                                ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.s2,
                                  ),
                                  child: Semantics(
                                    header: true,
                                    child: Text(
                                      title,
                                      style: AppTextStyles.sectionTitle,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: '关闭对局助手',
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                icon: const PrototypeIcon(PrototypeGlyph.close),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        if (_saving) const LinearProgressIndicator(),
                        Expanded(
                          child: AbsorbPointer(
                            absorbing: _saving,
                            child: ListView(
                              key: ValueKey((_page, _tab)),
                              padding: const EdgeInsets.all(AppSpacing.s5),
                              children: [
                                if (widget.store.hasStorageWarning) ...[
                                  Semantics(
                                    liveRegion: true,
                                    child: _MatchNote(
                                      widget.store.storageMessage,
                                      warning: true,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.s3),
                                ],
                                ...switch (_page) {
                                  _Page.quick => _quick(champion),
                                  _Page.full when champion != null => _full(
                                    champion,
                                  ),
                                  _Page.champion => _championPicker(),
                                  _Page.owned ||
                                  _Page.candidates => _augmentPicker(),
                                  _Page.record => _recordMenu(),
                                  _ => _championPicker(),
                                },
                              ],
                            ),
                          ),
                        ),
                        if (_page == _Page.owned || _page == _Page.candidates)
                          _pickerFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _quick(Champion? champion) {
    if (champion == null) return _championPicker(quick: true);
    return [
      _currentChampion(champion, quick: true),
      const SizedBox(height: AppSpacing.s5),
      Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: AppPalette.of(context).surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.group),
        ),
        clipBehavior: Clip.antiAlias,
        child: _MatchAction(
          title: '玩法要点',
          subtitle: champion.overview ?? '暂未整理玩法',
          onTap: () => _showTab(_Tab.play),
        ),
      ),
      const SizedBox(height: AppSpacing.s4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuickAction(
            '录海克斯',
            PrototypeGlyph.gem,
            () => setState(() {
              FocusScope.of(context).unfocus();
              _page = _Page.record;
            }),
          ),
          _QuickAction(
            '比候选',
            PrototypeGlyph.swords,
            () => _showTab(_Tab.augments),
          ),
          _QuickAction(
            '查出装',
            PrototypeGlyph.shield,
            () => _showTab(_Tab.build),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.s4),
      const _MatchNote('离线手录 · 玩法、搭配与出装均为人工示例，仅供参考。'),
    ];
  }

  Widget _currentChampion(Champion champion, {bool quick = false}) {
    final chosen = _names(_record.owned);
    return Row(
      children: [
        ObjectImage(path: champion.iconPath, size: AppLayout.iconTarget),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!quick) const _MatchNote('当前对局'),
              Text(champion.name, style: AppTextStyles.sectionTitle),
              if (quick) _MatchNote(chosen.isEmpty ? '还未录入海克斯' : '已选：$chosen'),
            ],
          ),
        ),
        TextButton(
          onPressed: () => _openPicker(_Page.champion),
          child: Text(quick ? '更换' : '换英雄'),
        ),
      ],
    );
  }

  List<Widget> _full(Champion champion) {
    final links = {
      for (final link in matchLinks(_bundle, champion.id)) link.augmentId: link,
    };
    return [
      _currentChampion(champion),
      const SizedBox(height: AppSpacing.s2),
      Wrap(
        spacing: AppSpacing.s2,
        runSpacing: AppSpacing.s1,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const ExampleBadge(),
          if (!widget.store.hasStorageWarning)
            _MatchNote(widget.store.storageMessage),
        ],
      ),
      const SizedBox(height: AppSpacing.s3),
      _MatchTabs(selected: _tab, onSelected: _showTab),
      const Divider(),
      const SizedBox(height: AppSpacing.s4),
      ...switch (_tab) {
        _Tab.play => _play(champion, links),
        _Tab.augments => _augments(links),
        _Tab.build => _buildRoute(),
      },
      const SizedBox(height: AppSpacing.s5),
      const Divider(),
      TextButton(onPressed: _end, child: const Text('结束本局，重新开始')),
    ];
  }

  List<Widget> _play(Champion champion, Map<String, ChampionAugment> links) => [
    const SectionHeading(title: '玩法要点'),
    const SizedBox(height: AppSpacing.s2),
    Text(champion.overview ?? '暂未整理这个英雄的玩法。'),
    const SizedBox(height: AppSpacing.s2),
    _MatchNote('技能优先级 · ${champion.skillPriority ?? '待整理'}'),
    if (champion.skillPriorityNote case final note?) _MatchNote(note),
    const SizedBox(height: AppSpacing.s5),
    SectionHeading(
      title: '本局海克斯',
      trailing: TextButton(
        onPressed: () => _openPicker(_Page.owned),
        child: Text(_record.owned.isEmpty ? '录入已选' : '编辑'),
      ),
    ),
    if (_record.owned.isEmpty) const _MatchNote('还没选强化？先看适合的方向。'),
    if (_record.owned.isNotEmpty)
      Wrap(
        spacing: AppSpacing.s2,
        runSpacing: AppSpacing.s1,
        children: [
          for (final id in _record.owned)
            if (_bundle.augmentById(id) case final augment?)
              InputChip(
                label: Text(augment.name),
                deleteButtonTooltipMessage: '移除${augment.name}',
                onDeleted: () => _save(
                  _record.editOwned(
                    _record.owned.where((x) => x != id).toList(),
                  ),
                ),
              ),
        ],
      ),
    for (final id in _record.owned)
      if (_bundle.augmentById(id) case final augment?)
        _augmentBrief(augment, links[id], owned: true),
    const SizedBox(height: AppSpacing.s4),
    const SectionHeading(title: '对局操作'),
    _MatchAction(
      title: '比较三选一',
      subtitle: '手动录入眼前的候选海克斯',
      onTap: () => _openPicker(_Page.candidates),
    ),
    _MatchAction(
      title: '查看出装',
      subtitle: '核心顺序与条件替换',
      onTap: () => _showTab(_Tab.build),
    ),
  ];

  List<Widget> _augments(Map<String, ChampionAugment> links) {
    final hasCandidates = _record.candidates.isNotEmpty;
    final ids = hasCandidates
        ? _record.candidates
        : links.keys.where((id) => !_record.owned.contains(id));
    final augments = ids.map(_bundle.augmentById).nonNulls.toList();
    return [
      SectionHeading(
        title: hasCandidates ? '眼前的候选' : '适合的强化方向',
        trailing: TextButton(
          onPressed: () => _openPicker(_Page.candidates),
          child: Text(hasCandidates ? '重录候选' : '录入三选一'),
        ),
      ),
      if (hasCandidates && _record.owned.isNotEmpty)
        _MatchNote('本局已选：${_names(_record.owned)}。已选与候选之间的联动尚未核对。'),
      if (augments.isEmpty) const _MatchNote('没有更多已整理的强化方向，可手动录入候选。'),
      for (final augment in augments)
        _augmentBrief(augment, links[augment.id], owned: false),
      const SizedBox(height: AppSpacing.s2),
      _MatchNote('最多记录 $matchOwnedLimit 次选择。是否出现及当前效果，以游戏内为准。'),
    ];
  }

  Widget _augmentBrief(
    Augment augment,
    ChampionAugment? link, {
    required bool owned,
  }) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.s3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        ObjectRow(
          iconPath: augment.iconPath,
          name: augment.name,
          subline:
              '${link?.reason != null ? '有人工搭配示例' : '联动资料待补'} · ${augment.rarityZh}',
          onTap: null,
        ),
        Text(
          link?.reason ??
              (owned ? '该英雄与此强化的联动尚未整理。' : augment.effectText ?? '强化效果尚未整理。'),
        ),
        const SizedBox(height: AppSpacing.s1),
        _MatchNote(link?.caution ?? augment.effectNote ?? '效果和触发条件请以游戏内为准。'),
        if (!owned)
          OutlinedButton(
            onPressed: _record.owned.length < matchOwnedLimit
                ? () => _take(augment)
                : null,
            child: const Text('本轮选它'),
          ),
      ],
    ),
  );

  List<Widget> _buildRoute() {
    final build = matchBuild(_bundle, _record);
    if (build == null) return [const _MatchNote('暂未整理出装。')];
    final chosen = _names(_record.owned);
    final alternative = build.appliedAlternative;
    final priority = build.priority;
    final focus = build.focus == MatchBuildFocus.critical
        ? '暴击续航'
        : '普攻触发与持续作战';
    return [
      _MatchNote(chosen.isEmpty ? '还没有已选海克斯' : '本局已选：$chosen'),
      SectionHeading(title: build.plan.name),
      if (build.plan.intent case final intent?) Text(intent),
      const SizedBox(height: AppSpacing.s3),
      _MatchNote(
        priority == null
            ? '保留英雄基础路线；当前没有已整理的专属装备方案。'
            : '示例搭配围绕$focus，常规路线优先展示${priority.name}。',
      ),
      if (build.needsConversionCheck)
        const _MatchNote('魔法转物理：需核对转化后的装备收益，不能直接照搬法强路线。'),
      const SizedBox(height: AppSpacing.s4),
      const SectionHeading(title: '核心顺序'),
      if (build.core.isEmpty) const _MatchNote('暂未整理核心装备。'),
      for (final (index, id) in build.core.indexed) _item(id, order: index + 1),
      if (build.hasDefenseAlternative)
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s1,
          children: [
            for (final (value, label) in const [
              (MatchPressure.normal, '常规输出'),
              (MatchPressure.defense, '看看防守替换'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _record.pressure == value,
                onSelected: (selected) {
                  if (selected) _save(_record.setPressure(value));
                },
              ),
          ],
        )
      else
        const _MatchNote('暂未整理防守替换。'),
      if (alternative != null)
        _MatchNote(
          '${alternative.condition ?? '防守示例'} · '
          '将${_bundle.itemById(alternative.replaceItemId)?.name}换为'
          '${_bundle.itemById(alternative.withItemId)?.name}。',
        ),
      const SizedBox(height: AppSpacing.s4),
      const SectionHeading(title: '鞋子'),
      if (build.plan.boots case final boots?)
        _item(boots.itemId, note: boots.condition)
      else
        const _MatchNote('暂未整理鞋子。'),
      const _MatchNote('不含金币、已购装备或敌方阵容判断。属性与效果以游戏内为准。'),
    ];
  }

  Widget _item(String id, {int? order, String? note}) {
    final item = _bundle.itemById(id);
    return ObjectRow(
      iconPath: item?.iconPath,
      name: item?.name ?? '装备资料未收录',
      subline: note,
      leading: order == null ? null : RankNumber(order: order),
      onTap: null,
    );
  }

  List<Widget> _championPicker({bool quick = false}) {
    final heroes = searchChampions(_bundle, _query);
    return [
      if (quick) const SectionHeading(title: '这局玩谁？'),
      const _MatchNote('从本机已收录的英雄中选择。玩法为人工示例，仅供参考。'),
      const SizedBox(height: AppSpacing.s3),
      _searchField('搜索英雄', '英雄名、别名或拼音'),
      if (heroes.isEmpty) const _MatchNote('未找到英雄，试试其他名称。'),
      for (final champion in quick ? heroes.take(3) : heroes)
        ObjectRow(
          key: ValueKey(champion.id),
          iconPath: champion.iconPath,
          name: champion.name,
          subline: champion.title,
          onTap: () => _selectChampion(champion),
        ),
      if (quick)
        TextButton(
          onPressed: () => _openPicker(_Page.champion),
          child: const Text('查看全部英雄'),
        ),
    ];
  }

  List<Widget> _recordMenu() => [
    _MatchAction(
      title: '眼前三选一',
      subtitle: '录入候选，比较人工搭配示例',
      onTap: () => _openPicker(_Page.candidates),
    ),
    _MatchAction(
      title: '已经拿到的海克斯',
      subtitle: '补充或修改本局已选',
      onTap: () => _openPicker(_Page.owned),
    ),
  ];

  List<Widget> _augmentPicker() {
    final owned = _page == _Page.owned;
    final max = owned ? matchOwnedLimit : matchCandidateLimit;
    final results = searchAugments(
      _bundle,
      _query,
    ).where((entry) => owned || !_record.owned.contains(entry.id)).toList();
    return [
      _MatchNote(owned ? '记录已经拿到的海克斯，最多 $max 个。' : '录入眼前的候选，最多 $max 个；不含本局已选。'),
      const SizedBox(height: AppSpacing.s3),
      _searchField('搜索海克斯', '海克斯名称或别名'),
      const SizedBox(height: AppSpacing.s2),
      if (results.isEmpty) const _MatchNote('本机已收录内容中没有可选的海克斯。'),
      for (final augment in results)
        Semantics(
          key: ValueKey(augment.id),
          selected: _draft.contains(augment.id),
          child: ObjectRow(
            iconPath: augment.iconPath,
            name: augment.name,
            subline: augment.rarityZh,
            showChevron: false,
            trailing: _draft.contains(augment.id)
                ? const PrototypeIcon(PrototypeGlyph.check)
                : null,
            onTap: () => setState(() {
              if (_draft.contains(augment.id)) {
                _draft.remove(augment.id);
              } else if (_draft.length < max) {
                _draft.add(augment.id);
              } else {
                _pickWarning = '最多选择 $max 个';
                return;
              }
              _pickWarning = null;
            }),
          ),
        ),
    ];
  }

  Widget _pickerFooter() {
    final owned = _page == _Page.owned;
    final max = owned ? matchOwnedLimit : matchCandidateLimit;
    final warning = _pickWarning;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s1,
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.s2,
            children: [
              Semantics(
                liveRegion: true,
                child: warning == null
                    ? Text('已选 ${_draft.length} / $max')
                    : _MatchNote(warning, warning: true),
              ),
              ElevatedButton(
                onPressed: _saving
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        final ids = _draft.toList();
                        _save(
                          owned
                              ? _record.editOwned(ids)
                              : _record.editCandidates(ids),
                          page: _Page.full,
                          tab: owned ? _Tab.play : _Tab.augments,
                        );
                      },
                child: const Text('确认录入'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchField(String label, String hint) => TextField(
    keyboardType: TextInputType.text,
    textInputAction: TextInputAction.search,
    onChanged: (value) => setState(() => _query = value),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: const Padding(
        padding: EdgeInsets.all(AppSpacing.s3),
        child: PrototypeIcon(PrototypeGlyph.search),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
    ),
  );
}

class _MatchNote extends StatelessWidget {
  const _MatchNote(this.text, {this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Text(
      text,
      style: AppTextStyles.meta.copyWith(
        color: warning ? palette.dangerForeground : palette.textSecondary,
      ),
    );
  }
}

class _MatchAction extends StatelessWidget {
  const _MatchAction({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.itemTitle),
                const SizedBox(height: AppSpacing.s1),
                _MatchNote(subtitle),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          const PrototypeIcon(PrototypeGlyph.next, size: 20),
        ],
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(this.title, this.icon, this.onTap);

  final String title;
  final PrototypeGlyph icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 72),
        padding: const EdgeInsets.all(AppSpacing.s2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrototypeIcon(icon, color: AppPalette.of(context).actionPrimary),
          const SizedBox(height: AppSpacing.s1),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _MatchTabs extends StatelessWidget {
  const _MatchTabs({required this.selected, required this.onSelected});

  final _Tab selected;
  final ValueChanged<_Tab> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Wrap(
      spacing: AppSpacing.s2,
      children: [
        for (final tab in _Tab.values)
          Semantics(
            selected: tab == selected,
            child: InkWell(
              onTap: () => onSelected(tab),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AppLayout.touchTarget,
                ),
                padding: const EdgeInsets.all(AppSpacing.s3),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: tab == selected
                          ? palette.textPrimary
                          : Colors.transparent,
                      width: AppStroke.selected,
                    ),
                  ),
                ),
                child: Text(
                  tab.title,
                  style: AppTextStyles.label.copyWith(
                    color: tab == selected
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
}
