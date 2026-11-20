import 'dart:convert';

/// demo-0.1.json 数据包的对象模型（后端技术方案 §4.1 字段一一对应）。
///
/// 口径（PRD §13）：对象 ID 统一为字符串；缺失即 null / 空集合，
/// 不猜测补齐；统计只透传原始计数（wins/games/isSimulated），不算胜率。
/// 本文件不依赖 Flutter SDK（纯 Dart），供页面与测试共用。

/// 数据包整体（mock-约定 §4：唯一 mock 包 = demo-0.1.json 原样字节）。
class ContentBundle {
  const ContentBundle({
    required this.schemaVersion,
    required this.dataset,
    required this.contentPolicy,
    required this.champions,
    required this.augments,
    required this.items,
    required this.summonerSpells,
    required this.championAugments,
    required this.builds,
    required this.sources,
  });

  final int schemaVersion;
  final DatasetMeta dataset;
  final ContentPolicy contentPolicy;
  final List<Champion> champions;
  final List<Augment> augments;
  final List<Item> items;
  final List<SummonerSpell> summonerSpells;
  final List<ChampionAugment> championAugments;
  final List<BuildPlan> builds;
  final List<SourceEntry> sources;

  static ContentBundle fromJson(Map<String, dynamic> json) {
    return ContentBundle(
      schemaVersion: _readInt(json['schemaVersion']) ?? 1,
      dataset: DatasetMeta.fromJson(_readMap(json['dataset'])),
      contentPolicy:
          ContentPolicy.fromJson(_readMap(json['contentPolicy'])),
      champions: _readList(json['champions'], Champion.fromJson),
      augments: _readList(json['augments'], Augment.fromJson),
      items: _readList(json['items'], Item.fromJson),
      summonerSpells:
          _readList(json['summonerSpells'], SummonerSpell.fromJson),
      championAugments:
          _readList(json['championAugments'], ChampionAugment.fromJson),
      builds: _readList(json['builds'], BuildPlan.fromJson),
      sources: _readList(json['sources'], SourceEntry.fromJson),
    );
  }

  static ContentBundle parse(String raw) =>
      ContentBundle.fromJson(_asMap(jsonDecode(raw)));

  Champion? championById(String id) =>
      champions.where((c) => c.id == id).firstOrNull;

  Augment? augmentById(String id) =>
      augments.where((a) => a.id == id).firstOrNull;

  Item? itemById(String id) => items.where((i) => i.id == id).firstOrNull;

  SummonerSpell? summonerSpellById(String id) =>
      summonerSpells.where((s) => s.id == id).firstOrNull;

  /// PRD §13.3 引用闭合由数据侧保证；此处仅防御性过滤。
  List<ChampionAugment> augmentsForChampion(String championId) =>
      championAugments.where((c) => c.championId == championId).toList();

  List<ChampionAugment> championsForAugment(String augmentId) =>
      championAugments.where((c) => c.augmentId == augmentId).toList();

  List<BuildPlan> buildsForChampion(String championId) =>
      builds.where((b) => b.championId == championId).toList();

  /// 引用该装备的全部出装方案（出门/鞋子/核心/替换任一位置命中）。
  List<BuildPlan> buildsUsingItem(String itemId) => builds
      .where((b) => b.referencesItem(itemId))
      .toList(growable: false);
}

/// 数据集元信息（demo-0.1 的 dataset 块原样透传）。
///
/// 与后端契约（mock-约定 §3.2）同构：未来远程 latest 元信息仅追加
/// 服务端生成字段（publishedAt/contentChecksum/fileSizeBytes/…），
/// 本地包直接从包内字段派生 `dataMode`。
class DatasetMeta {
  const DatasetMeta({
    required this.datasetVersion,
    required this.mode,
    required this.compiledAt,
    required this.sourceIds,
    required this.gamePatch,
  });

  final String datasetVersion;

  /// demo-0.1 原样字段（mode=demo）；快照包无此字段时为 null。
  final String? mode;
  final String? compiledAt;
  final List<String> sourceIds;
  final String? gamePatch;

  /// PRD 13.1 dataMode：demo→simulated 映射由后端契约提出（待产品确认 #8）。
  String get dataMode => mode == 'demo' ? 'simulated' : 'source-snapshot';

  static DatasetMeta fromJson(Map<String, dynamic> json) {
    return DatasetMeta(
      datasetVersion: _readString(json['datasetVersion']) ?? '',
      mode: _readString(json['mode']),
      compiledAt: _readString(json['compiledAt']),
      sourceIds: _readStringList(json['sourceIds']),
      gamePatch: _readString(json['gamePatch']),
    );
  }
}

/// contentPolicy 原样透传（客户端「数据说明」页文案与低样本阈值来源）。
class ContentPolicy {
  const ContentPolicy({
    required this.verifiedMeaning,
    required this.pendingMeaning,
    required this.stats,
    required this.recommendations,
    required this.imagePathBase,
    required this.lowSampleThreshold,
  });

  final String? verifiedMeaning;
  final String? pendingMeaning;
  final String? stats;
  final String? recommendations;
  final String? imagePathBase;
  final int lowSampleThreshold;

  static ContentPolicy fromJson(Map<String, dynamic> json) {
    return ContentPolicy(
      verifiedMeaning: _readString(json['verifiedMeaning']),
      pendingMeaning: _readString(json['pendingMeaning']),
      stats: _readString(json['stats']),
      recommendations: _readString(json['recommendations']),
      imagePathBase: _readString(json['imagePathBase']),
      lowSampleThreshold: _readInt(json['lowSampleThreshold']) ?? 200,
    );
  }
}

class Champion {
  const Champion({
    required this.id,
    required this.name,
    required this.title,
    required this.roles,
    required this.aliases,
    required this.pinyin,
    required this.initials,
    required this.displayOrder,
    required this.iconPath,
    required this.summonerSpells,
    required this.overview,
    required this.overviewIsExample,
    required this.balanceNote,
    required this.balanceStatus,
    required this.skillPriority,
    required this.skillPriorityIsExample,
    required this.skillPriorityNote,
    required this.summonerSpellNote,
    required this.summonerSpellsIsExample,
    required this.stats,
    required this.isStale,
    required this.sourceIds,
  });

  final String id;
  final String name;

  /// 称号（如「疾风剑豪」）；注意来源字段位：name=常用名、title=称号。
  final String? title;
  final List<String> roles;
  final List<String> aliases;
  final String? pinyin;
  final String? initials;

  /// 示例排名（demo 阶段唯一排序依据，PRD §4.2：模拟数据用「示例排名」）。
  final int? displayOrder;
  final String? iconPath;

  /// 召唤师技能 id 引用（闭合于同包 summonerSpells 清单）。
  final List<String> summonerSpells;
  final String? overview;
  final bool overviewIsExample;
  final String? balanceNote;
  final String? balanceStatus;
  final String? skillPriority;
  final bool skillPriorityIsExample;
  final String? skillPriorityNote;
  final String? summonerSpellNote;
  final bool summonerSpellsIsExample;
  final SimStats? stats;
  final bool isStale;
  final List<String> sourceIds;

  static Champion fromJson(Map<String, dynamic> json) {
    return Champion(
      id: _readString(json['id']) ?? '',
      name: _readString(json['name']) ?? '',
      title: _readString(json['title']),
      roles: _readStringList(json['roles']),
      aliases: _readStringList(json['aliases']),
      pinyin: _readString(json['pinyin']),
      initials: _readString(json['initials']),
      displayOrder: _readInt(json['displayOrder']),
      iconPath: _readString(json['iconPath']),
      summonerSpells: _readStringList(json['summonerSpells']),
      overview: _readString(json['overview']),
      overviewIsExample: json['overviewIsExample'] == true,
      balanceNote: _readString(json['balanceNote']),
      balanceStatus: _readString(json['balanceStatus']),
      skillPriority: _readString(json['skillPriority']),
      skillPriorityIsExample: json['skillPriorityIsExample'] == true,
      skillPriorityNote: _readString(json['skillPriorityNote']),
      summonerSpellNote: _readString(json['summonerSpellNote']),
      summonerSpellsIsExample: json['summonerSpellsIsExample'] == true,
      stats: json['stats'] == null
          ? null
          : SimStats.fromJson(_readMap(json['stats'])),
      isStale: json['isStale'] == true,
      sourceIds: _readStringList(json['sourceIds']),
    );
  }
}

class Augment {
  const Augment({
    required this.id,
    required this.name,
    required this.aliases,
    required this.rarity,
    required this.effectText,
    required this.effectStatus,
    required this.effectNote,
    required this.stages,
    required this.stageStatus,
    required this.displayOrder,
    required this.iconPath,
    required this.stats,
    required this.isStale,
    required this.sourceIds,
  });

  final String id;
  final String name;
  final List<String> aliases;

  /// prismatic / gold / silver / unknown（待核对）。
  final String? rarity;
  final String? effectText;

  /// verified / pending / unknown。
  final String? effectStatus;
  final String? effectNote;

  /// 可出现阶段（1–4；PRD §6 阶段筛选依据）。
  final List<int> stages;

  /// demo 口径 source-page-only；PRD 13.1 三态由快照包提供，demo 不改写。
  final String? stageStatus;
  final int? displayOrder;
  final String? iconPath;
  final SimStats? stats;
  final bool isStale;
  final List<String> sourceIds;

  static Augment fromJson(Map<String, dynamic> json) {
    return Augment(
      id: _readString(json['id']) ?? '',
      name: _readString(json['name']) ?? '',
      aliases: _readStringList(json['aliases']),
      rarity: _readString(json['rarity']),
      effectText: _readString(json['effectText']),
      effectStatus: _readString(json['effectStatus']),
      effectNote: _readString(json['effectNote']),
      stages: _readIntList(json['stages']),
      stageStatus: _readString(json['stageStatus']),
      displayOrder: _readInt(json['displayOrder']),
      iconPath: _readString(json['iconPath']),
      stats: json['stats'] == null
          ? null
          : SimStats.fromJson(_readMap(json['stats'])),
      isStale: json['isStale'] == true,
      sourceIds: _readStringList(json['sourceIds']),
    );
  }

  /// 稀有度中文（C10：必须写出名称，不能仅凭颜色识别）。
  String get rarityZh => switch (rarity) {
        'prismatic' => '棱彩',
        'gold' => '金色',
        'silver' => '银色',
        _ => '待核对',
      };
}

class Item {
  const Item({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.sourceIds,
  });

  final String id;
  final String name;
  final String? iconPath;
  final List<String> sourceIds;

  static Item fromJson(Map<String, dynamic> json) {
    return Item(
      id: _readString(json['id']) ?? '',
      name: _readString(json['name']) ?? '',
      iconPath: _readString(json['iconPath']),
      sourceIds: _readStringList(json['sourceIds']),
    );
  }
}

class SummonerSpell {
  const SummonerSpell({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.sourceIds,
  });

  final String id;
  final String name;
  final String? iconPath;
  final List<String> sourceIds;

  static SummonerSpell fromJson(Map<String, dynamic> json) {
    return SummonerSpell(
      id: _readString(json['id']) ?? '',
      name: _readString(json['name']) ?? '',
      iconPath: _readString(json['iconPath']),
      sourceIds: _readStringList(json['sourceIds']),
    );
  }
}

/// 英雄×海克斯人工关联（推荐理由为示例，统计为模拟）。
class ChampionAugment {
  const ChampionAugment({
    required this.championId,
    required this.augmentId,
    required this.reason,
    required this.caution,
    required this.recommendationOrder,
    required this.isExample,
    required this.stats,
    required this.sourceIds,
  });

  final String championId;
  final String augmentId;
  final String? reason;
  final String? caution;
  final int? recommendationOrder;
  final bool isExample;
  final SimStats? stats;
  final List<String> sourceIds;

  static ChampionAugment fromJson(Map<String, dynamic> json) {
    return ChampionAugment(
      championId: _readString(json['championId']) ?? '',
      augmentId: _readString(json['augmentId']) ?? '',
      reason: _readString(json['reason']),
      caution: _readString(json['caution']),
      recommendationOrder: _readInt(json['recommendationOrder']),
      isExample: json['isExample'] == true,
      stats: json['stats'] == null
          ? null
          : SimStats.fromJson(_readMap(json['stats'])),
      sourceIds: _readStringList(json['sourceIds']),
    );
  }
}

/// 模拟统计（PRD §12.1：wins/games 有效才计算胜率，其余原样）。
class SimStats {
  const SimStats({
    required this.wins,
    required this.games,
    required this.isSimulated,
    required this.gamePatch,
    required this.segment,
  });

  final int? wins;
  final int? games;
  final bool isSimulated;
  final String? gamePatch;
  final String? segment;

  /// 有效计数（games > 0 且 0 ≤ wins ≤ games）才算胜率；否则 null。
  double? get winRatePct {
    final w = wins, g = games;
    if (w == null || g == null || g <= 0 || w < 0 || w > g) return null;
    return w * 100 / g;
  }

  /// 低样本（PRD §12.1：games < 200 标「样本较少」；未知不判断）。
  bool get isLowSample => games != null && games! < 200;

  static SimStats fromJson(Map<String, dynamic> json) {
    return SimStats(
      wins: _readInt(json['wins']),
      games: _readInt(json['games']),
      isSimulated: json['isSimulated'] == true,
      gamePatch: _readString(json['gamePatch']),
      segment: _readString(json['segment']),
    );
  }
}

/// 一套出装方案（人工示例）。
class BuildPlan {
  const BuildPlan({
    required this.id,
    required this.championId,
    required this.name,
    required this.intent,
    required this.startingItems,
    required this.boots,
    required this.coreItemIds,
    required this.alternatives,
    required this.isExample,
    required this.note,
    required this.sourceIds,
  });

  final String id;
  final String championId;
  final String name;
  final String? intent;
  final List<StartingItem> startingItems;
  final BootsRef? boots;
  final List<String> coreItemIds;
  final List<ItemAlternative> alternatives;
  final bool isExample;
  final String? note;
  final List<String> sourceIds;

  bool referencesItem(String itemId) {
    return startingItems.any((s) => s.itemId == itemId) ||
        boots?.itemId == itemId ||
        coreItemIds.contains(itemId) ||
        alternatives.any(
            (a) => a.replaceItemId == itemId || a.withItemId == itemId);
  }

  static BuildPlan fromJson(Map<String, dynamic> json) {
    final bootsJson = json['boots'];
    return BuildPlan(
      id: _readString(json['id']) ?? '',
      championId: _readString(json['championId']) ?? '',
      name: _readString(json['name']) ?? '',
      intent: _readString(json['intent']),
      startingItems:
          _readList(json['startingItems'], StartingItem.fromJson),
      boots: bootsJson == null ? null : BootsRef.fromJson(_readMap(bootsJson)),
      coreItemIds: _readStringList(json['coreItemIds']),
      alternatives:
          _readList(json['alternatives'], ItemAlternative.fromJson),
      isExample: json['isExample'] == true,
      note: _readString(json['note']),
      sourceIds: _readStringList(json['sourceIds']),
    );
  }
}

class StartingItem {
  const StartingItem({required this.itemId, required this.quantity});

  final String itemId;
  final int quantity;

  static StartingItem fromJson(Map<String, dynamic> json) {
    return StartingItem(
      itemId: _readString(json['itemId']) ?? '',
      quantity: _readInt(json['quantity']) ?? 1,
    );
  }
}

class BootsRef {
  const BootsRef({required this.itemId, required this.condition});

  final String itemId;
  final String? condition;

  static BootsRef fromJson(Map<String, dynamic> json) {
    return BootsRef(
      itemId: _readString(json['itemId']) ?? '',
      condition: _readString(json['condition']),
    );
  }
}

class ItemAlternative {
  const ItemAlternative({
    required this.replaceItemId,
    required this.withItemId,
    required this.condition,
  });

  final String replaceItemId;
  final String withItemId;
  final String? condition;

  static ItemAlternative fromJson(Map<String, dynamic> json) {
    return ItemAlternative(
      replaceItemId: _readString(json['replaceItemId']) ?? '',
      withItemId: _readString(json['withItemId']) ?? '',
      condition: _readString(json['condition']),
    );
  }
}

class SourceEntry {
  const SourceEntry({
    required this.id,
    required this.title,
    required this.url,
    required this.accessedAt,
    required this.contentType,
    required this.licenseNote,
  });

  final String id;
  final String? title;
  final String? url;
  final String? accessedAt;
  final String? contentType;
  final String? licenseNote;

  static SourceEntry fromJson(Map<String, dynamic> json) {
    return SourceEntry(
      id: _readString(json['id']) ?? '',
      title: _readString(json['title']),
      url: _readString(json['url']),
      accessedAt: _readString(json['accessedAt']),
      contentType: _readString(json['contentType']),
      licenseNote: _readString(json['licenseNote']),
    );
  }
}

// ---------- JSON 读取辅助（外部输入按 unknown 收窄，不裸用 dynamic） ----------

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const FormatException('数据包根结构应为 JSON 对象');
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  return const {};
}

List<T> _readList<T>(Object? value, T Function(Map<String, dynamic>) fromJson) {
  if (value is! List) return const [];
  return [
    for (final entry in value)
      if (entry != null) fromJson(_readMap(entry)),
  ];
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final entry in value)
      if (entry is String) entry,
  ];
}

List<int> _readIntList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final entry in value)
      if (entry is num) entry.toInt(),
  ];
}

String? _readString(Object? value) => value is String ? value : null;

int? _readInt(Object? value) => value is num ? value.toInt() : null;
