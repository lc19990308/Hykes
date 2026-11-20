import 'dart:io';

import 'package:app/app.dart';
import 'package:app/core/data/content_bundle.dart';
import 'package:app/core/data/content_repository.dart';
import 'package:app/core/state/app_state.dart';
import 'package:app/features/match/match_content.dart';
import 'package:app/features/match/match_screen.dart';
import 'package:app/features/match/match_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _favoritesKey = 'haidou.favorites.v1';
const _recentsKey = 'haidou.recents.v1';
const _themeKey = 'haidou.theme.v1';
const _favorites =
    '{"schemaVersion":1,"items":[{"entityType":"champion",'
    '"entityId":"22","savedAt":"2026-11-20T00:00:00Z"}]}';
const _recents =
    '{"schemaVersion":1,"items":[{"entityType":"item",'
    '"entityId":"3031","viewedAt":"2026-11-20T00:00:00Z"}]}';
const _theme = '{"schemaVersion":1,"mode":"night"}';

late String _asset;
late ContentBundle _bundle;

Future<SharedPreferences> _prefs([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<AppState> _pumpApp(WidgetTester tester, SharedPreferences prefs) async {
  final state = AppState(
    prefs: prefs,
    repository: ContentRepository(loader: () async => _asset),
  );
  state.restoreLocalState();
  await tester.pumpWidget(HykesApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

String _sheetContents(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Text),
      ),
    )
    .map((text) => text.data)
    .join(' | ');

Finder _panelText(String text) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

Future<void> _open(WidgetTester tester) async {
  final entry = find.descendant(
    of: find.byType(MatchEntry),
    matching: find.text('对局助手'),
  );
  await tester.scrollUntilVisible(
    entry,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(entry);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  if (target.hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(target);
  }
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) async {
  await tester.tap(find.byTooltip('关闭对局助手'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    _asset = File('assets/data/demo-0.1.json').readAsStringSync();
    _bundle = ContentBundle.parse(_asset);
  });

  testWidgets('首页离线流程：选英雄、手录、比较、出装、重启、确认结束', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final prefs = await _prefs({
      _favoritesKey: _favorites,
      _recentsKey: _recents,
      _themeKey: _theme,
    });
    final first = await _pumpApp(tester, prefs);
    await _open(tester);
    expect(_panelText('这局玩谁？'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'yasuo');
    await tester.pumpAndSettle();
    final yasuo = _panelText('亚索');
    expect(yasuo, findsOneWidget);
    await _tap(tester, yasuo);
    await _tap(tester, _panelText('玩法要点'));
    expect(
      _panelText('技能优先级 · ${_bundle.championById('157')!.skillPriority}'),
      findsOneWidget,
    );

    await _tap(tester, _panelText('录入已选'));
    await _tap(tester, _panelText('弹跳蜜蜂'));
    expect(
      _panelText('已选 1 / 4'),
      findsOneWidget,
      reason: _sheetContents(tester),
    );
    expect(MatchStore(_bundle, prefs).record.owned, isEmpty);
    await _tap(tester, _panelText('确认录入'));
    expect(_panelText('技能接普攻的节奏便于练习弹跳触发。'), findsOneWidget);
    expect(MatchStore(_bundle, prefs).record.owned, ['3048']);

    await _tap(tester, _panelText('比较三选一'));
    expect(_panelText('弹跳蜜蜂'), findsNothing);
    await tester.enterText(find.byType(TextField), '魔法转物理');
    await tester.pumpAndSettle();
    await _tap(tester, _panelText('魔法转物理').last);
    expect(_panelText('已选 1 / 3'), findsOneWidget);
    await _tap(tester, _panelText('确认录入'));
    expect(_panelText('眼前的候选'), findsOneWidget);
    expect(_panelText('演示将法强来源转换为攻击力的路线。'), findsOneWidget);
    expect(_panelText('本局已选：弹跳蜜蜂。已选与候选之间的联动尚未核对。'), findsOneWidget);
    await _tap(tester, _panelText('本轮选它'));
    await _tap(tester, find.text('取消'));
    expect(MatchStore(_bundle, prefs).record.candidates, ['1206']);
    await _tap(tester, _panelText('本轮选它'));
    await _tap(tester, find.text('确认录入'));
    final taken = MatchStore(_bundle, prefs).record;
    expect(taken.owned, ['3048', '1206']);
    expect(taken.candidates, isEmpty);

    await _tap(tester, _panelText('怎么出装'));
    expect(_panelText('核心顺序'), findsOneWidget);
    expect(_panelText('魔法转物理：需核对转化后的装备收益，不能直接照搬法强路线。'), findsOneWidget);
    await _tap(tester, _panelText('看看防守替换'));
    expect(_panelText('死亡之舞'), findsOneWidget);
    await _tap(tester, _panelText('换英雄'));
    await _tap(tester, _panelText('艾希'));
    expect(find.text('确认更换英雄？'), findsOneWidget);
    await _tap(tester, find.text('取消'));
    expect(MatchStore(_bundle, prefs).record.championId, '157');
    await _close(tester);

    // Recreate the app, including its match entry/store, after reloading prefs.
    await tester.pumpWidget(const SizedBox.shrink());
    first.dispose();
    await prefs.reload();
    final second = await _pumpApp(tester, prefs);
    await _open(tester);
    expect(_panelText('已选：弹跳蜜蜂、魔法转物理'), findsOneWidget);
    await _tap(tester, _panelText('查出装'));
    expect(_panelText('死亡之舞'), findsOneWidget);
    await tester.scrollUntilVisible(
      _panelText('结束本局，重新开始'),
      200,
      scrollable: find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      ),
    );
    await _tap(tester, _panelText('结束本局，重新开始'));
    await _tap(tester, find.text('取消'));
    expect(MatchStore(_bundle, prefs).record.championId, '157');
    await _tap(tester, _panelText('结束本局，重新开始'));
    await _tap(tester, find.text('结束本局'));
    expect(_panelText('这局玩谁？'), findsOneWidget);
    await prefs.reload();
    final ended = MatchStore(_bundle, prefs).record;
    expect(ended.championId, isNull);
    expect(ended.owned, isEmpty);
    expect(ended.candidates, isEmpty);
    expect(ended.pressure, MatchPressure.normal);
    expect(prefs.getString(_favoritesKey), _favorites);
    expect(prefs.getString(_recentsKey), _recents);
    expect(prefs.getString(_themeKey), _theme);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    second.dispose();
  });

  test('存储独立：未来格式不覆盖，损坏格式明确回空白', () async {
    const future = '{"schemaVersion":8,"match":{}}';
    var prefs = await _prefs({MatchStore.storageKey: future});
    var store = MatchStore(_bundle, prefs);
    expect(store.storageMessage, contains('原记录已保留'));
    await store.save(store.record.selectChampion('157'));
    expect(store.record.championId, '157');
    await prefs.reload();
    expect(prefs.getString(MatchStore.storageKey), future);

    const broken =
        '{"schemaVersion":1,"match":{"championId":"157",'
        '"augments":["3048"],"candidates":["3048"],"pressure":"normal"}}';
    prefs = await _prefs({MatchStore.storageKey: broken});
    store = MatchStore(_bundle, prefs);
    expect(store.storageMessage, contains('无法读取'));
    expect(store.record.championId, isNull);
    expect(prefs.getString(MatchStore.storageKey), broken);
    await store.save(store.record.selectChampion('22'));
    expect(MatchStore(_bundle, prefs).record.championId, '22');
  });

  test('存储恢复候选、防守选择；同英雄保留，更换清空', () async {
    final prefs = await _prefs();
    final store = MatchStore(_bundle, prefs);
    await store.save(
      store.record
          .selectChampion('157')
          .editOwned(['3048'])
          .editCandidates(['1058', '1206'])
          .setPressure(MatchPressure.defense),
    );
    await prefs.reload();
    final restored = MatchStore(_bundle, prefs).record;
    expect(restored.selectChampion('157'), same(restored));
    expect(restored.pressure, MatchPressure.defense);
    expect(restored.candidates, ['1058', '1206']);
    expect(restored.editOwned(['3048', '1206']).candidates, ['1058']);
    final changed = restored.selectChampion('22');
    expect(changed.owned, isEmpty);
    expect(changed.candidates, isEmpty);
    expect(changed.pressure, MatchPressure.normal);
  });

  test('出装仅应用明确的人工示例，候选不算已选；缺失方案时返回空', () {
    final yasuo = const MatchRecord.empty().selectChampion('157');
    final unselected = matchBuild(_bundle, yasuo.editCandidates(['1077']))!;
    expect(unselected.priority, isNull);
    expect(unselected.core, ['3153', '3031', '3072']);
    final critical = matchBuild(
      _bundle,
      yasuo.editOwned(['3048', '1077', '1206']),
    )!;
    expect(critical.focus, MatchBuildFocus.critical);
    expect(critical.core, ['3031', '3153', '3072']);
    expect(critical.needsConversionCheck, isTrue);
    final defense = matchBuild(
      _bundle,
      yasuo.editOwned(['3048']).setPressure(MatchPressure.defense),
    )!;
    expect(defense.focus, MatchBuildFocus.onHit);
    expect(defense.core, ['3153', '3031', '6333']);
    expect(matchBuild(_bundle, const MatchRecord.empty()), isNull);
    expect(matchBuild(_bundle, yasuo.selectChampion('not-in-bundle')), isNull);
  });
}
