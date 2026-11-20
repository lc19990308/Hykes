import 'content_bundle.dart';

/// PRD §7.2 维护好的装备标签表（与原型 app-v1.js L44–46 同源；
/// 19 件成装的适用职业与属性标签，demo 数据资产化后由 items 快照字段替换）。
const Map<String, List<String>> kItemRoleTags = {
  '3031': ['射手', '刺客'],
  '3036': ['射手'],
  '3072': ['射手', '战士'],
  '3074': ['战士'],
  '3078': ['战士'],
  '3085': ['射手'],
  '3089': ['法师'],
  '3094': ['射手'],
  '3100': ['法师'],
  '3115': ['法师'],
  '3153': ['射手', '战士'],
  '3156': ['战士'],
  '3157': ['法师'],
  '4633': ['法师'],
  '6333': ['战士', '刺客'],
  '6610': ['战士', '坦克'],
  '6655': ['法师'],
  '6672': ['射手'],
  '6676': ['射手', '刺客'],
};

const Map<String, List<String>> kItemAttrTags = {
  '3031': ['攻击', '暴击'],
  '3036': ['暴击', '穿甲'],
  '3072': ['攻击', '吸血'],
  '3074': ['攻击', '吸血'],
  '3078': ['攻击', '攻速'],
  '3085': ['攻速', '暴击'],
  '3089': ['法强'],
  '3094': ['攻速', '暴击'],
  '3100': ['法强', '攻击'],
  '3115': ['攻速', '法强'],
  '3153': ['攻速', '吸血'],
  '3156': ['魔抗', '护盾'],
  '3157': ['法强', '护盾'],
  '4633': ['法强', '生命'],
  '6333': ['护甲', '减伤'],
  '6610': ['生命', '攻击'],
  '6655': ['法强', '法穿'],
  '6672': ['攻速', '攻击'],
  '6676': ['穿甲', '暴击'],
};

const List<String> kItemAttrs = [
  '攻击', '暴击', '攻速', '吸血', '法强', '法穿',
  '穿甲', '护甲', '魔抗', '生命', '护盾', '减伤',
];

/// 原型 app-v1.js 的「演示统计夹具」（L113–131 原样移植）。
///
/// 所有统计均为设计演示用的独立模拟记录，与内容数据分开；页面一律就近
/// 标注「模拟数据 · 不随分段切换」（PRD §12.3 / V22 口径）。
/// 公式数值与原型逐条同源，不引入任何真实或随机数据。
class DemoStat {
  DemoStat({
    required this.id,
    required this.rank,
    required this.wins,
    required this.games,
    required this.winRatePct,
    required this.selectionRatePct,
    required this.tier,
    this.stage,
    this.order,
    this.championId,
  });

  final String id;
  int rank;
  final int? wins;
  final int? games;
  final double? winRatePct;
  final double? selectionRatePct;
  final String? tier;
  final String? stage;
  final String? order;
  final String? championId;

  bool get isLowSample => games != null && games! < 200;

  /// 原型 fmt(games)：null→样本未知；else 千分位 + 「场」。
  String get gamesLabel =>
      games == null ? '样本未知' : '${_fmtThousands(games!)} 场';

  String get selectionLabel =>
      selectionRatePct == null ? '暂无统计' : '${selectionRatePct!.toStringAsFixed(1)}%';

  String get winLabel => winRatePct == null ? '暂无统计' : '${winRatePct!.toStringAsFixed(1)}%';
}

String _fmtThousands(int value) {
  final s = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    out.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) out.write(',');
  }
  return out.toString();
}

DemoStat _record(String id, int rank, int? wins, int? games, double? selection,
        String? tier) =>
    DemoStat(
      id: id,
      rank: rank,
      wins: wins,
      games: games,
      winRatePct: (games != null && games > 0) ? wins! * 100 / games : null,
      selectionRatePct: selection,
      tier: tier,
    );

// 原型 L115–118：overall（英雄 8 条 / 海克斯 12 条 / 装备由公式生成）。
final List<DemoStat> kDemoOverallChampion = [
  _record('887', 1, 573, 1000, 4.8, 'S'),
  _record('777', 2, 1112, 2000, 7.2, 'S'),
  _record('157', 3, 1090, 2000, 8.6, 'A'),
  _record('360', 4, 538, 1000, 5.1, 'A'),
  _record('114', 5, 1058, 2000, 3.6, 'A'),
  _record('22', 6, 1032, 2000, 6.4, 'B'),
  _record('51', 7, 102, 199, 4.2, 'B'),
  _record('4', 8, null, null, null, null),
];

final List<DemoStat> kDemoOverallAugment = [
  _record('1134', 1, 584, 1000, 1.4, 'S'),
  _record('3048', 2, 568, 1000, 2.5, 'S'),
  _record('1081', 3, 1114, 2000, 3.1, 'S'),
  _record('1058', 4, 552, 1000, 1.8, 'A'),
  _record('3078', 5, 1090, 2000, 2.1, 'A'),
  _record('1170', 6, 1076, 2000, 4.6, 'A'),
  _record('1077', 7, 1062, 2000, 3.2, 'A'),
  _record('2062', 8, 1048, 2000, 2.8, 'B'),
  _record('1004', 9, 104, 200, 1.1, 'B'),
  _record('1389', 10, 101, 199, 0.9, 'B'),
  _record('3075', 11, 50, 100, null, null),
  _record('1206', 12, null, null, null, null),
];

/// 装备总体（原型 L118 公式）：rankedItems 索引序；i==5 → 150 场；
/// 末条（i==length-1）无统计；tier i<4→S、<12→A、else B。
List<DemoStat> buildDemoOverallItems(List<Item> rankedItems) {
  final out = <DemoStat>[];
  for (final (i, item) in rankedItems.indexed) {
    if (i == rankedItems.length - 1) {
      out.add(_record(item.id, i + 1, null, null, null, null));
    } else {
      final games = i == 5 ? 150 : 2000;
      final wins = ((0.582 - i * 0.0037) * games).round();
      final selection = (0.6 > 12 - i * 0.4 ? 0.6 : 12 - i * 0.4).toDouble();
      final tier = i < 4 ? 'S' : i < 12 ? 'A' : 'B';
      out.add(_record(item.id, i + 1, wins, games, selection, tier));
    }
  }
  return out;
}

/// 海克斯阶段切片（原型 L120）：400 场公式；1206 的阶段 4 过滤；
/// 每阶段内按胜率降序重排名次（原型 L129）。
List<DemoStat> buildDemoStageRecords(ContentBundle bundle) {
  final out = <DemoStat>[];
  for (final (i, augment) in bundle.augments.indexed) {
    for (final n in augment.stages) {
      final wins = ((0.595 - i * 0.006 - n * 0.004) * 400).round();
      out.add(DemoStat(
        id: augment.id,
        rank: i + 1,
        wins: wins,
        games: 400,
        winRatePct: wins * 100 / 400,
        selectionRatePct: 1.2 + i * 0.15,
        tier: null,
        stage: '$n',
      ));
    }
  }
  final filtered = out
      .where((x) => !(x.id == '1206' && x.stage == '4'))
      .toList();
  for (final n in [1, 2, 3, 4]) {
    _rankByWinRate(filtered.where((x) => x.stage == '$n').toList());
  }
  return filtered;
}

/// 装备购买顺序切片（原型 L121）：300 场公式；6676 的第 6 件过滤；
/// 每顺序内按胜率降序重排名次（原型 L130）。
List<DemoStat> buildDemoOrderRecords(List<Item> rankedItems) {
  final out = <DemoStat>[];
  for (final (i, item) in rankedItems.indexed) {
    for (final n in [1, 2, 3, 4, 5, 6]) {
      final wins = ((0.50 + n * 0.009 - i * 0.002) * 300).round();
      out.add(DemoStat(
        id: item.id,
        rank: i + 1,
        wins: wins,
        games: 300,
        winRatePct: wins * 100 / 300,
        selectionRatePct: 0.5 > 8 - i * 0.2 ? 0.5 : 8 - i * 0.2,
        tier: null,
        order: '$n',
      ));
    }
  }
  final filtered = out
      .where((x) => !(x.id == '6676' && x.order == '6'))
      .toList();
  for (final n in [1, 2, 3, 4, 5, 6]) {
    _rankByWinRate(filtered.where((x) => x.order == '$n').toList());
  }
  return filtered;
}

/// 英雄×海克斯总体搭配（原型 L122）：从 championAugments 的模拟 stats 生成。
List<DemoStat> buildDemoChampionAugmentRecords(ContentBundle bundle) {
  var index = 0;
  final out = <DemoStat>[];
  for (final relation in bundle.championAugments) {
    final stats = relation.stats;
    if (stats == null ||
        stats.wins == null ||
        stats.games == null ||
        stats.games == 0) {
      continue;
    }
    out.add(DemoStat(
      id: relation.augmentId,
      rank: 0,
      wins: stats.wins,
      games: stats.games,
      winRatePct: stats.wins! * 100 / stats.games!,
      selectionRatePct: 2.5 + index * 0.2,
      tier: null,
      championId: relation.championId,
    ));
    index++;
  }
  return out;
}

/// 英雄×海克斯阶段搭配（原型 L124）：仅对已有总体搭配统计的关系生成。
List<DemoStat> buildDemoChampionAugmentStageRecords(
    ContentBundle bundle, List<DemoStat> overallRecords) {
  final out = <DemoStat>[];
  for (final record in overallRecords) {
    final games = (record.games ?? 0) < 200 ? record.games : 200;
    final augment = bundle.augmentById(record.id);
    if (augment == null || games == null || games <= 0) continue;
    final stages = augment.stages;
    for (final (k, n) in stages.indexed) {
      final wins =
          (games * (record.winRatePct! / 100 - 0.015 + k * 0.008)).round();
      out.add(DemoStat(
        id: record.id,
        rank: 0,
        wins: wins,
        games: games,
        winRatePct: wins * 100 / games,
        selectionRatePct: 1.2 + k * 0.2,
        tier: null,
        stage: '$n',
        championId: record.championId,
      ));
    }
  }
  // 原型 L131：按 champion×stage 分组重排。
  final champions = {for (final r in out) r.championId};
  for (final championId in champions) {
    for (final n in [1, 2, 3, 4]) {
      _rankByWinRate(out
          .where((x) => x.championId == championId && x.stage == '$n')
          .toList());
    }
  }
  return out;
}

/// 英雄×装备总体（原型 L125）：500 场。
List<DemoStat> buildDemoChampionItemRecords(ContentBundle bundle) {
  final out = <DemoStat>[];
  for (final (i, plan) in bundle.builds.indexed) {
    for (final (n, id) in plan.coreItemIds.indexed) {
      final wins = 280 + i * 2 + n * 3;
      out.add(DemoStat(
        id: id,
        rank: n + 1,
        wins: wins,
        games: 500,
        winRatePct: wins * 100 / 500,
        selectionRatePct: 10 + n * 4,
        tier: null,
        championId: plan.championId,
      ));
    }
  }
  final champions = {for (final r in out) r.championId};
  for (final championId in champions) {
    _rankByWinRate(out.where((x) => x.championId == championId).toList());
  }
  return out;
}

/// 英雄×装备购买顺序（原型 L126）：i==3 → 150 场。
List<DemoStat> buildDemoChampionItemOrderRecords(ContentBundle bundle) {
  final out = <DemoStat>[];
  for (final (i, plan) in bundle.builds.indexed) {
    for (final (n, id) in plan.coreItemIds.indexed) {
      final games = i == 3 ? 150 : 400;
      final wins = ((0.52 + n * 0.012) * games).round();
      out.add(DemoStat(
        id: id,
        rank: n + 1,
        wins: wins,
        games: games,
        winRatePct: wins * 100 / games,
        selectionRatePct: 6 + n * 3,
        tier: null,
        order: '${n + 1}',
        championId: plan.championId,
      ));
    }
  }
  final champions = {for (final r in out) r.championId};
  for (final championId in champions) {
    for (final n in [1, 2, 3, 4, 5, 6]) {
      _rankByWinRate(out
          .where((x) => x.championId == championId && x.order == '$n')
          .toList());
    }
  }
  return out;
}

/// 原型 rankByWinRate：胜率降序（null 置后），同值按 id 升序，rank=序号。
void _rankByWinRate(List<DemoStat> list) {
  final sorted = [...list]..sort((a, b) {
      final av = a.winRatePct ?? -1.0, bv = b.winRatePct ?? -1.0;
      final byRate = bv.compareTo(av);
      if (byRate != 0) return byRate;
      return a.id.compareTo(b.id);
    });
  for (final (i, stat) in sorted.indexed) {
    stat.rank = i + 1;
  }
}
