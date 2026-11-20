import 'package:material_ui/material_ui.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/panels.dart';
import '../../shared/widgets/proto.dart';
import '../../shared/widgets/prototype_icon.dart';
import '../../shared/widgets/sections.dart';
import '../augments/augment_detail_screen.dart';
import '../champions/champion_detail_screen.dart';
import '../champions/champion_list_screen.dart';
import '../recents/recents_screen.dart';
import '../settings/settings_screen.dart';

/// 收藏（R08 §11.1）：支持分类筛选；失效收藏保留并可移除。
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({required this.state, this.onSwitchTab, super.key});

  final AppState state;

  /// 根页签入口传入切换回调；从设置进入时打开独立英雄页。
  final ValueChanged<int>? onSwitchTab;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const _all = 'all';
  static const List<(String, String)> _filters = [
    (_all, '全部'),
    ('champion', '英雄'),
    ('augment', '海克斯'),
  ];

  String _filter = _all;

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _openDetail(EntityType type, String id) {
    switch (type) {
      case EntityType.champion:
        _push(ChampionDetailScreen(state: widget.state, championId: id));
      case EntityType.augment:
        _push(AugmentDetailScreen(state: widget.state, augmentId: id));
      case EntityType.item:
        break; // 收藏仅支持英雄与海克斯。
    }
  }

  void _browseChampions() {
    final switchTab = widget.onSwitchTab;
    if (switchTab != null) {
      switchTab(1);
    } else {
      _push(ChampionListScreen(state: widget.state));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isRoot = ModalRoute.of(context)?.isFirst ?? true;
    final pageInset = MediaQuery.sizeOf(context).width <= 374
        ? AppLayout.pagePaddingCompact
        : AppLayout.pagePadding;
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: Text('我的收藏', style: isRoot ? AppTextStyles.pageTitle : null),
        titleSpacing: pageInset,
        toolbarHeight: isRoot
            ? AppLayout.rootTopBarMinHeight
            : AppLayout.topBarMinHeight,
        actions: [
          if (isRoot)
            IconButton(
              tooltip: '设置',
              onPressed: () => _push(SettingsScreen(state: widget.state)),
              icon: const PrototypeIcon(PrototypeGlyph.settings),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(AppStroke.defaultWidth),
          child: Divider(),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.state,
          builder: (context, _) {
            final list = widget.state.favorites
                .where(
                  (record) =>
                      _filter == _all || record.type.storageName == _filter,
                )
                .toList();
            return ListView(
              padding: EdgeInsets.fromLTRB(
                pageInset,
                AppSpacing.s5,
                pageInset,
                AppSpacing.s6,
              ),
              children: [
                Text(
                  '收藏英雄和海克斯，下一局继续参考。',
                  style: AppTextStyles.body.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: FilterChipRow<String>(
                    options: _filters,
                    selected: _filter,
                    allowWrap: false,
                    onSelected: (value) {
                      if (value != null) setState(() => _filter = value);
                    },
                  ),
                ),
                _historyLink(palette),
                const SizedBox(height: AppSpacing.s4),
                SectionHeading(
                  title: '我的收藏',
                  trailing: Semantics(
                    liveRegion: true,
                    child: Text(
                      '${list.length} 项',
                      style: AppTextStyles.meta.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                const Divider(),
                if (list.isEmpty) ...[
                  const EmptyBlock(title: '这里还没有收藏', body: '在英雄或海克斯详情中点击收藏。'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: _browseChampions,
                      child: const Text('浏览英雄'),
                    ),
                  ),
                ] else
                  for (final record in list) _row(palette, record),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _historyLink(AppPalette palette) {
    return InkWell(
      onTap: () => _push(RecentsScreen(state: widget.state)),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppLayout.iconTarget),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.borderSubtle)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '最近查看',
                style: AppTextStyles.label.copyWith(color: palette.textPrimary),
              ),
            ),
            PrototypeIcon(
              PrototypeGlyph.next,
              size: 20,
              color: palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(AppPalette palette, FavoriteRecord record) {
    final info = widget.state.describe(record.type, record.id);
    if (info == null) {
      // 失效收藏保留对象 ID 与移除入口，不允许进入详情。
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前数据范围不可用',
              style: AppTextStyles.meta.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              '对象 ID：${record.id}（${record.type.labelZh}）',
              style: AppTextStyles.meta.copyWith(color: palette.textMuted),
            ),
            TextButton(
              onPressed: () =>
                  widget.state.removeFavorite(record.type, record.id),
              child: const Text('移除记录'),
            ),
            const Divider(),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: MiniLink(
            name: info.name,
            iconPath: info.iconPath,
            onTap: () => _openDetail(record.type, record.id),
          ),
        ),
        IconButton(
          tooltip: '移除收藏',
          onPressed: () => widget.state.removeFavorite(record.type, record.id),
          icon: Icon(Icons.bookmark, size: 20, color: palette.actionPrimary),
        ),
      ],
    );
  }
}
