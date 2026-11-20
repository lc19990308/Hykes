import '../../core/data/content_bundle.dart';
import 'match_store.dart';

List<ChampionAugment> matchLinks(ContentBundle bundle, String championId) =>
    bundle.augmentsForChampion(championId)..sort((a, b) {
      final order = (a.recommendationOrder ?? 1 << 30).compareTo(
        b.recommendationOrder ?? 1 << 30,
      );
      return order != 0 ? order : a.augmentId.compareTo(b.augmentId);
    });

enum MatchBuildFocus { critical, onHit }

typedef MatchBuild = ({
  BuildPlan plan,
  List<String> core,
  MatchBuildFocus? focus,
  Item? priority,
  ItemAlternative? appliedAlternative,
  bool hasDefenseAlternative,
  bool needsConversionCheck,
});

// Narrow editorial rules from app-v1.js matchBuild; not a scoring engine.
const _critAugment = '1077';
const _critItem = '3031';
const _onHitAugments = {'1058', '1081', '3048'};
const _onHitItems = {'3153', '3115', '3078', '6672'};
const _conversionAugment = '1206';

MatchBuild? matchBuild(ContentBundle bundle, MatchRecord record) {
  final championId = record.championId;
  if (championId == null) return null;
  final plan = bundle.buildsForChampion(championId).firstOrNull;
  if (plan == null) return null;

  final baseCore = plan.coreItemIds;
  String? priorityId;
  MatchBuildFocus? focus;
  if (record.owned.contains(_critAugment) &&
      baseCore.contains(_critItem) &&
      bundle.itemById(_critItem) != null) {
    priorityId = _critItem;
    focus = MatchBuildFocus.critical;
  } else if (record.owned.any(_onHitAugments.contains)) {
    priorityId = baseCore
        .where((id) => _onHitItems.contains(id) && bundle.itemById(id) != null)
        .firstOrNull;
    if (priorityId != null) focus = MatchBuildFocus.onHit;
  }

  final alternative = plan.alternatives.where((alt) {
    return baseCore.contains(alt.replaceItemId) &&
        alt.replaceItemId != alt.withItemId &&
        bundle.itemById(alt.replaceItemId) != null &&
        bundle.itemById(alt.withItemId) != null;
  }).firstOrNull;
  final applied = record.pressure == MatchPressure.defense ? alternative : null;
  final orderedCore = [
    ?priorityId,
    ...baseCore.where((id) => id != priorityId),
  ];
  return (
    plan: plan,
    core: [
      for (final id in orderedCore)
        if (applied != null && id == applied.replaceItemId)
          applied.withItemId
        else
          id,
    ],
    focus: focus,
    priority: priorityId == null ? null : bundle.itemById(priorityId),
    appliedAlternative: applied,
    hasDefenseAlternative: alternative != null,
    needsConversionCheck: record.owned.contains(_conversionAugment),
  );
}
