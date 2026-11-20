import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'content_bundle.dart';

List<T> _readList<T>(Object? value, T Function(Map<String, Object?>) parse) => [
  if (value is List<Object?>)
    for (final row in value)
      if (row is Map<String, Object?>) parse(row),
];

/// 海克斯 16.22 研究快照模型（原型 app-v1.js 的 SNAP，dataMode source-snapshot）。
///
/// 口径与原型一致：
/// - 仅驱动海克斯域总体与阶段统计；英雄与装备域仍为模拟数据；
/// - games=sampleCount、selectionRatePct=pickRatePct，来源精度原样保留，未做再计算；
/// - demo id → 快照 id 精确对位（diff 修正后一致），名称匹配保留为兜底。
class AugmentSnapshot {
  const AugmentSnapshot({
    required this.gamePatch,
    required this.sourceUpdatedAt,
    required this.datasetVersion,
    required this.defaultSnapshotId,
    required this.coverageIncluded,
    required this.coverageRanked,
    required this.segments,
    required this.augments,
    required this.stats,
  });

  final String gamePatch;
  final String? sourceUpdatedAt;
  final String datasetVersion;
  final String defaultSnapshotId;
  final int coverageIncluded;
  final int coverageRanked;

  /// [{id, segment, segmentNote, allMatches}]，顺序即原型 segmentOptions。
  final List<SnapshotSegment> segments;

  /// [{id, name, rarity, iconLocalPath}]。
  final List<SnapshotAugment> augments;

  /// 总体（augment-overall）与阶段（augment-stage）统计记录。
  final List<SnapshotStat> stats;

  static AugmentSnapshot? _cache;

  /// 加载 assets/data/augments-16.22-snapshot.json（与 web 原型内嵌同一份字节）。
  /// 解析失败返回 null（原型同样 try/catch 降级为 snapReady=false）。
  static Future<AugmentSnapshot?> load() async {
    if (_cache != null) return _cache;
    try {
      final raw = await rootBundle.loadString(
        'assets/data/augments-16.22-snapshot.json',
      );
      final doc = jsonDecode(raw);
      if (doc is! Map<String, dynamic>) return null;
      return _cache = AugmentSnapshot._fromJson(doc);
    } catch (_) {
      return null;
    }
  }

  static AugmentSnapshot? get cached => _cache;

  factory AugmentSnapshot._fromJson(Map<String, dynamic> doc) {
    final dataset = doc['dataset'];
    final coverage = doc['coverage'];
    return AugmentSnapshot(
      gamePatch: (dataset is Map && dataset['gamePatch'] is String)
          ? dataset['gamePatch'] as String
          : '',
      sourceUpdatedAt: dataset is Map && dataset['sourceUpdatedAt'] is String
          ? dataset['sourceUpdatedAt'] as String
          : null,
      datasetVersion: dataset is Map && dataset['datasetVersion'] is String
          ? dataset['datasetVersion'] as String
          : '',
      defaultSnapshotId:
          dataset is Map && dataset['defaultSnapshotId'] is String
          ? dataset['defaultSnapshotId'] as String
          : '',
      coverageIncluded: coverage is Map && coverage['includedCount'] is num
          ? (coverage['includedCount'] as num).toInt()
          : 0,
      coverageRanked: coverage is Map && coverage['rankedCount'] is num
          ? (coverage['rankedCount'] as num).toInt()
          : 0,
      segments: _readList(doc['snapshots'], SnapshotSegment.fromJson),
      augments: _readList(doc['augments'], SnapshotAugment.fromJson),
      stats: _readList(doc['stats'], SnapshotStat.fromJson),
    );
  }

  /// 原型 snapshotIdOf(segment)：分段 → 快照 id。
  String? snapshotIdOf(String segment) =>
      segments.where((s) => s.segment == segment).map((s) => s.id).firstOrNull;

  /// demo id → 快照对象（ID 精确；名称兜底由调用方补充）。
  SnapshotAugment? byId(String id) =>
      augments.where((a) => a.id == id).firstOrNull;

  SnapshotAugment? byName(String name) =>
      augments.where((a) => a.name == name).firstOrNull;
}

class SnapshotSegment {
  const SnapshotSegment({
    required this.id,
    required this.segment,
    required this.segmentNote,
  });

  final String id;

  /// all / high。
  final String segment;
  final String segmentNote;

  /// 原型 segmentOptions 标签：all→全部分段，high→高分段，其余 segmentNote。
  String get labelZh => switch (segment) {
    'all' => '全部分段',
    'high' => '高分段',
    _ => segmentNote,
  };

  static SnapshotSegment fromJson(Map<String, dynamic> json) => SnapshotSegment(
    id: json['id'] is String ? json['id'] as String : '',
    segment: json['segment'] is String ? json['segment'] as String : '',
    segmentNote: json['segmentNote'] is String
        ? json['segmentNote'] as String
        : '',
  );
}

class SnapshotAugment {
  const SnapshotAugment({
    required this.id,
    required this.name,
    required this.rarity,
    required this.iconLocalPath,
  });

  final String id;
  final String name;
  final String? rarity;
  final String? iconLocalPath;

  static SnapshotAugment fromJson(Map<String, dynamic> json) => SnapshotAugment(
    id: json['id'] is String ? json['id'] as String : '',
    name: json['name'] is String ? json['name'] as String : '',
    rarity: json['rarity'] is String ? json['rarity'] as String : null,
    iconLocalPath: json['iconLocalPath'] is String
        ? json['iconLocalPath'] as String
        : null,
  );
}

class SnapshotStat {
  const SnapshotStat({
    required this.augmentId,
    required this.snapshotId,
    required this.scopeType,
    required this.stage,
    required this.rank,
    required this.tier,
    required this.sampleCount,
    required this.winRatePct,
    required this.pickRatePct,
    required this.blueWinRatePct,
    required this.redWinRatePct,
  });

  final String augmentId;

  /// aramkit-16.22-all / aramkit-16.22-high。
  final String snapshotId;

  /// augment-overall / augment-stage。
  final String scopeType;

  /// 总体为 null；阶段 1–4。
  final int? stage;
  final int rank;
  final String? tier;

  /// 原型归一口径：games=sampleCount。
  final int? sampleCount;
  final double? winRatePct;
  final double? pickRatePct;
  final double? blueWinRatePct;
  final double? redWinRatePct;

  static SnapshotStat fromJson(Map<String, dynamic> json) {
    final stage = json['stage'];
    return SnapshotStat(
      augmentId: json['augmentId'] is String
          ? json['augmentId'] as String
          : json['augmentId']?.toString() ?? '',
      snapshotId: json['snapshotId'] is String
          ? json['snapshotId'] as String
          : '',
      scopeType: json['scopeType'] is String ? json['scopeType'] as String : '',
      stage: stage is num ? stage.toInt() : null,
      rank: json['rank'] is num ? (json['rank'] as num).toInt() : 0,
      tier: json['tier'] is String ? json['tier'] as String : null,
      sampleCount: json['sampleCount'] is num
          ? (json['sampleCount'] as num).toInt()
          : null,
      winRatePct: json['winRatePct'] is num
          ? (json['winRatePct'] as num).toDouble()
          : null,
      pickRatePct: json['pickRatePct'] is num
          ? (json['pickRatePct'] as num).toDouble()
          : null,
      blueWinRatePct: json['blueWinRatePct'] is num
          ? (json['blueWinRatePct'] as num).toDouble()
          : null,
      redWinRatePct: json['redWinRatePct'] is num
          ? (json['redWinRatePct'] as num).toDouble()
          : null,
    );
  }
}

/// 原型 stat('augment', id, slice)：demo id → 快照统计（含名称兜底）。
SnapshotStat? augmentSnapStat(
  AugmentSnapshot snap,
  ContentBundle bundle,
  String demoId,
  String slice, {
  required String segment,
}) {
  final demo = bundle.augmentById(demoId);
  final snapAugment =
      snap.byId(demoId) ?? (demo == null ? null : snap.byName(demo.name));
  if (snapAugment == null) return null;
  final snapshotId = snap.snapshotIdOf(segment);
  if (snapshotId == null) return null;
  final scope = slice == 'all' ? 'augment-overall' : 'augment-stage';
  for (final stat in snap.stats) {
    if (stat.augmentId == snapAugment.id &&
        stat.snapshotId == snapshotId &&
        stat.scopeType == scope &&
        (slice == 'all'
            ? stat.stage == null
            : stat.stage?.toString() == slice)) {
      return stat;
    }
  }
  return null;
}
