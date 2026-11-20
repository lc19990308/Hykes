import 'package:material_ui/material_ui.dart';

import '../../core/data/content_bundle.dart';
import '../../core/data/search.dart';
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
import '../items/item_detail_screen.dart';

/// 快捷搜索（C15）：空查询显示分类内的历史与建议，输入后即时匹配本地数据。
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    required this.state,
    required this.initialType,
    super.key,
  });

  final AppState state;
  final EntityType initialType;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

typedef _SearchMatch = ({
  String id,
  String name,
  String? iconPath,
  String? extra,
  int? score,
});

class _SearchScreenState extends State<SearchScreen> {
  static const int _maxLength = 50;
  static final _whitespace = RegExp(r'\s+');

  late EntityType _type = widget.initialType;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openDetail(EntityType type, String id) {
    final detail = switch (type) {
      EntityType.champion => ChampionDetailScreen(
        state: widget.state,
        championId: id,
      ),
      EntityType.augment => AugmentDetailScreen(
        state: widget.state,
        augmentId: id,
      ),
      EntityType.item => ItemDetailScreen(state: widget.state, itemId: id),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => detail));
  }

  void _refreshResults() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() {});
  }

  void _clearSearch() {
    _controller.clear();
    _refreshResults();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final bundle = widget.state.bundle;
    final query = _controller.text.trim();
    final pageInset = MediaQuery.sizeOf(context).width <= 374
        ? AppLayout.pagePaddingCompact
        : AppLayout.pagePadding;
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: const Text('搜索'),
        toolbarHeight: AppLayout.topBarMinHeight,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('取消'),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(AppStroke.defaultWidth),
          child: Divider(),
        ),
      ),
      body: bundle == null
          ? const SizedBox.shrink()
          : SafeArea(
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  pageInset,
                  AppSpacing.s5,
                  pageInset,
                  AppSpacing.s6,
                ),
                children: [
                  _inputField(palette),
                  const SizedBox(height: AppSpacing.s4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: FilterChipRow<EntityType>(
                      options: [
                        for (final type in EntityType.values)
                          (type, type.labelZh),
                      ],
                      selected: _type,
                      allowWrap: false,
                      onSelected: (value) {
                        if (value == null) return;
                        _type = value;
                        _refreshResults();
                      },
                    ),
                  ),
                  if (query.isEmpty)
                    ..._emptyQuery(bundle, palette)
                  else
                    ..._results(bundle, palette, query),
                ],
              ),
            ),
    );
  }

  Widget _inputField(AppPalette palette) {
    final label = '搜索${_type.labelZh}';
    final radius = BorderRadius.circular(AppRadius.control);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(color: palette.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Semantics(
          label: label,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            autocorrect: false,
            maxLength: _maxLength,
            textInputAction: TextInputAction.search,
            onChanged: (_) => _refreshResults(),
            decoration: InputDecoration(
              hintText: _type == EntityType.champion ? '名称、称号、别名或拼音' : '名称或别名',
              hintStyle: AppTextStyles.label.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w400,
              ),
              counterText: '',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(AppSpacing.s3),
                child: PrototypeIcon(
                  PrototypeGlyph.search,
                  color: palette.textSecondary,
                ),
              ),
              suffixIcon: IconButton(
                tooltip: '清空搜索',
                onPressed: _clearSearch,
                icon: PrototypeIcon(
                  PrototypeGlyph.close,
                  color: palette.textMuted,
                ),
              ),
              filled: true,
              fillColor: palette.surface,
              border: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(
                  color: palette.actionPrimary,
                  width: AppFocusRing.width,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _emptyQuery(ContentBundle bundle, AppPalette palette) {
    final suggestions = switch (_type) {
      EntityType.champion => bundle.champions.take(4).map((c) => c.name),
      EntityType.augment => bundle.augments.take(4).map((a) => a.name),
      EntityType.item => bundle.items.take(4).map((i) => i.name),
    };
    return [
      const SizedBox(height: AppSpacing.s6),
      const SectionHeading(title: '最近查看'),
      ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          final rows = [
            for (final record in widget.state.recents)
              if (record.type == _type)
                if (widget.state.describe(record.type, record.id)
                    case final info?)
                  MiniLink(
                    name: info.name,
                    iconPath: info.iconPath,
                    onTap: () => _openDetail(record.type, record.id),
                  ),
          ];
          if (rows.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s2),
              child: Text(
                '还没有记录，输入名称开始搜索。',
                style: AppTextStyles.meta.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            );
          }
          return Column(children: rows.take(5).toList());
        },
      ),
      const SizedBox(height: AppSpacing.s6),
      const SectionHeading(title: '试试这些'),
      const SizedBox(height: AppSpacing.s2),
      FilterChipRow<String>(
        options: [for (final name in suggestions) (name, name)],
        selected: null,
        onSelected: (value) {
          if (value == null) return;
          _controller.text = value;
          _refreshResults();
        },
      ),
    ];
  }

  int? _championScore(Champion champion, String query) {
    final nameScore = matchScore(
      query: query,
      name: champion.name,
      title: champion.title,
      aliases: champion.aliases,
    );
    final pinyinScore = matchScore(
      query: query.replaceAll(_whitespace, ''),
      pinyin: champion.pinyin?.replaceAll(_whitespace, ''),
      initials: champion.initials?.replaceAll(_whitespace, ''),
    );
    if (pinyinScore == null || (nameScore != null && nameScore < pinyinScore)) {
      return nameScore;
    }
    return pinyinScore;
  }

  List<Widget> _results(
    ContentBundle bundle,
    AppPalette palette,
    String query,
  ) {
    final List<_SearchMatch> candidates = switch (_type) {
      EntityType.champion => [
        for (final champion in bundle.champions)
          (
            id: champion.id,
            name: champion.name,
            iconPath: champion.iconPath,
            extra: champion.title,
            score: _championScore(champion, query),
          ),
      ],
      EntityType.augment => [
        for (final augment in bundle.augments)
          (
            id: augment.id,
            name: augment.name,
            iconPath: augment.iconPath,
            extra: augment.rarityZh,
            score: matchScore(
              query: query,
              name: augment.name,
              aliases: augment.aliases,
            ),
          ),
      ],
      EntityType.item => [
        for (final item in bundle.items)
          (
            id: item.id,
            name: item.name,
            iconPath: item.iconPath,
            extra: '装备',
            score: matchScore(query: query, name: item.name),
          ),
      ],
    };
    final rows = candidates.where((row) => row.score != null).toList()
      ..sort((a, b) {
        final match = a.score!.compareTo(b.score!);
        return match == 0 ? a.id.compareTo(b.id) : match;
      });
    final type = _type;
    return [
      const SizedBox(height: AppSpacing.s4),
      Semantics(
        liveRegion: true,
        child: Text(
          '找到 ${rows.length} 项${type == EntityType.champion ? ' · 支持名称、别名和拼音' : ''}',
          style: AppTextStyles.meta.copyWith(color: palette.textMuted),
        ),
      ),
      if (rows.isEmpty)
        const EmptyBlock(title: '没有找到相关内容', body: '试试其他名称或别名。')
      else ...[
        for (final row in rows)
          MiniLink(
            name: row.name,
            iconPath: row.iconPath,
            extra: row.extra,
            onTap: () => _openDetail(type, row.id),
          ),
        const SizedBox(height: AppSpacing.s4),
      ],
      ElevatedButton(onPressed: _clearSearch, child: const Text('清除关键词')),
    ];
  }
}
