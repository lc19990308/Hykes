import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/app.dart';
import 'package:app/core/data/content_bundle.dart';
import 'package:app/core/data/content_repository.dart';
import 'package:app/core/data/search.dart';
import 'package:app/core/state/app_state.dart';
import 'package:app/features/home/home_screen.dart';

/// 最小 fixture：结构与 demo-0.1.json 同构（含拼音/别名/关联/出装引用）。
const String kFixtureJson = '''
{
  "schemaVersion": 1,
  "dataset": {
    "datasetVersion": "demo-0.1",
    "mode": "demo",
    "compiledAt": "2026-11-17T04:28:18.010843+00:00",
    "sourceIds": ["editorial"],
    "gamePatch": null
  },
  "contentPolicy": {
    "stats": "仅人工模拟；无数据保存为 null，不使用站方统计。",
    "lowSampleThreshold": 200
  },
  "champions": [
    {
      "id": "157", "name": "亚索", "title": "疾风剑豪",
      "roles": ["战士", "刺客"], "aliases": ["风男"],
      "pinyin": "yasuo", "initials": "ys", "displayOrder": 1,
      "overview": "示例概览", "overviewIsExample": true,
      "balanceNote": "待核对", "balanceStatus": "pending",
      "skillPriority": "Q > E > W", "skillPriorityIsExample": true,
      "summonerSpells": ["4"], "summonerSpellsIsExample": true,
      "stats": null, "isStale": false, "sourceIds": ["editorial"]
    },
    {
      "id": "22", "name": "艾希", "title": "寒冰射手",
      "roles": ["射手"], "aliases": [],
      "pinyin": "aixi", "initials": "ax", "displayOrder": 2,
      "overview": "示例", "overviewIsExample": true,
      "summonerSpells": [], "stats": null, "isStale": false,
      "sourceIds": ["editorial"]
    }
  ],
  "augments": [
    {
      "id": "3048", "name": "弹跳蜜蜂", "aliases": [],
      "rarity": "prismatic", "effectText": "示例效果",
      "effectStatus": "pending", "stages": [1, 2, 3],
      "stageStatus": "source-page-only", "displayOrder": 1,
      "stats": null, "isStale": false, "sourceIds": ["editorial"]
    }
  ],
  "items": [
    { "id": "3031", "name": "无尽之刃", "sourceIds": ["asset-index"] },
    { "id": "2003", "name": "生命药水", "sourceIds": ["asset-index"] }
  ],
  "summonerSpells": [
    { "id": "4", "name": "闪现", "sourceIds": ["asset-index"] }
  ],
  "championAugments": [
    {
      "championId": "157", "augmentId": "3048",
      "reason": "示例理由", "recommendationOrder": 1, "isExample": true,
      "stats": { "wins": 260, "games": 500, "isSimulated": true,
                 "gamePatch": null, "segment": "练习样本" },
      "sourceIds": ["editorial"]
    }
  ],
  "builds": [
    {
      "id": "build-157-01", "championId": "157", "name": "示例出装",
      "startingItems": [{ "itemId": "2003", "quantity": 1 }],
      "boots": { "itemId": "3006", "condition": "示例" },
      "coreItemIds": ["3031"], "alternatives": [], "isExample": true,
      "sourceIds": ["editorial"]
    }
  ],
  "sources": [
    { "id": "editorial", "title": "人工整理", "licenseNote": "研究参考" }
  ]
}
''';

AppState _fixtureState() => AppState(
  repository: ContentRepository(loader: () async => kFixtureJson),
  prefs: null,
);

Future<void> _pumpApp(WidgetTester tester, AppState state) async {
  await tester.pumpWidget(HykesApp(state: state));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('根页渲染五项主导航（V01）', (tester) async {
    await _pumpApp(tester, _fixtureState());
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('英雄'), findsWidgets);
    expect(find.text('海克斯'), findsWidgets);
    expect(find.text('装备'), findsWidgets);
    expect(find.text('收藏'), findsWidgets);
  });

  testWidgets('首页对齐固定顶栏，摘要使用明确标记的模拟统计', (tester) async {
    await _pumpApp(tester, _fixtureState());
    expect(find.text('海斗宝典'), findsOneWidget);
    expect(find.text('海克斯大乱斗'), findsOneWidget);
    expect(find.text('榜单为演示值'), findsOneWidget);
    final home = find.byType(HomeScreen);
    final scrollable = find.descendant(
      of: home,
      matching: find.byType(Scrollable),
    );
    for (final label in ['亚索', '弹跳蜜蜂', '无尽之刃']) {
      await tester.scrollUntilVisible(
        find.descendant(of: home, matching: find.text(label)),
        220,
        scrollable: scrollable,
      );
      expect(find.text('海斗宝典').hitTestable(), findsOneWidget);
    }
    expect(find.text('生命药水'), findsNothing);
  });

  testWidgets('英雄榜快捷定位过滤并保留原模拟名次', (tester) async {
    await _pumpApp(tester, _fixtureState());
    await tester.tap(find.text('英雄').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('2 项 · 总体 · 演示'), findsOneWidget);
    await tester.tap(find.text('射手').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text('1 项 · 总体 · 演示'), findsOneWidget);
    expect(find.text('艾希').hitTestable(), findsOneWidget);
    expect(find.text('51.6%').hitTestable(), findsOneWidget);
  });

  testWidgets('海克斯榜筛选草稿应用后，详情继承阶段', (tester) async {
    await _pumpApp(tester, _fixtureState());
    await tester.tap(find.text('海克斯').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('筛选选项').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('阶段 2').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看结果').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('1 项 · 阶段 2 · 演示'), findsOneWidget);
    await tester.tap(find.text('弹跳蜜蜂').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('海克斯详情'), findsOneWidget);
    expect(find.text('阶段 2').hitTestable(), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('打开英雄详情写入最近查看并可收藏（V27 冒烟）', (tester) async {
    final state = _fixtureState();
    await _pumpApp(tester, state);
    final home = find.byType(HomeScreen);
    final target = find.descendant(of: home, matching: find.text('亚索'));
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.descendant(of: home, matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(find.text('英雄详情'), findsOneWidget);
    expect(find.text('玩法概览'), findsOneWidget);
    // 成功展示详情后写入最近查看。
    expect(state.recents.single.type, EntityType.champion);
    expect(state.recents.single.id, '157');
    // 收藏即时生效。
    await tester.tap(find.text('收藏').last);
    await tester.pumpAndSettle();
    expect(state.isFavorite(EntityType.champion, '157'), isTrue);
  });

  test('英雄搜索匹配优先级（PRD V05：名称/称号/别名/拼音/大小写）', () {
    final bundle = ContentBundle.parse(kFixtureJson);
    expect(searchChampions(bundle, '亚索').single.id, '157');
    expect(searchChampions(bundle, '疾风剑豪').single.id, '157');
    expect(searchChampions(bundle, 'YASUO').single.id, '157');
    expect(searchChampions(bundle, 'ys').single.id, '157');
    expect(searchChampions(bundle, '寒冰').single.id, '22');
    expect(searchChampions(bundle, '  ').length, 2); // 纯空白视为空查询
    expect(searchChampions(bundle, '不存在'), isEmpty);
  });

  test('模拟统计口径（PRD §12：有效计数才算胜率、低样本标注）', () {
    final bundle = ContentBundle.parse(kFixtureJson);
    final stats = bundle.championAugments.single.stats!;
    expect(stats.winRatePct, closeTo(52.0, 0.001));
    expect(stats.isLowSample, isFalse);
    final low = SimStats(
      wins: 39,
      games: 75,
      isSimulated: true,
      gamePatch: null,
      segment: null,
    );
    expect(low.winRatePct, closeTo(52.0, 0.001));
    expect(low.isLowSample, isTrue);
    final invalid = SimStats(
      wins: 80,
      games: 75,
      isSimulated: true,
      gamePatch: null,
      segment: null,
    );
    expect(invalid.winRatePct, isNull); // wins > games 不计算，不伪造 0%
  });

  test('内置 mock 包加载冒烟（mock-约定 §4：demo-0.1 原样字节可解析）', () async {
    final bundle = await ContentRepository().load();
    expect(bundle.dataset.datasetVersion, 'demo-0.1');
    expect(bundle.dataset.dataMode, 'simulated');
    expect(bundle.champions, hasLength(8));
    expect(bundle.augments, hasLength(12));
    expect(bundle.items, hasLength(27));
    expect(bundle.championAugments, hasLength(24));
    expect(bundle.builds, hasLength(8));
    // 全部英雄 stats 为 null → 「暂无统计」口径（PRD V21）。
    expect(bundle.champions.every((c) => c.stats == null), isTrue);
  });

  test('装备成装榜排除清单口径（demo 无 itemType 的近似）', () {
    final bundle = ContentBundle.parse(kFixtureJson);
    final list = searchItems(bundle, '', completedOnly: true);
    expect(list.single.id, '3031');
    expect(searchItems(bundle, '', completedOnly: false).length, 2);
  });
}
