import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/augment_snapshot.dart';
import '../data/content_bundle.dart';
import '../data/content_repository.dart';
import '../data/demo_stats.dart';
import '../data/search.dart';

/// 全局应用状态：内容包加载、收藏、最近查看、外观模式（PRD §2.2/§11/§20）。
///
/// 存储口径与 web 原型同构：
/// - `haidou.favorites.v1` / `haidou.recents.v1`：
///   `{schemaVersion:1, items:[{entityType, entityId, savedAt|viewedAt}]}`
/// - `haidou.theme.v1`：`{schemaVersion:1, mode:'day'|'night'|'system'}`
/// 损坏/未来格式集合独立降级：收藏/历史清空会话重建、外观回落跟随系统，
/// 不覆盖原值（PRD §11.3、§20.3）；写入失败保留会话操作并持续提示。
class AppState extends ChangeNotifier {
  AppState({ContentRepository? repository, this.prefs})
    : _repository = repository ?? ContentRepository() {
    _updatePhase = _repository.updatesEnabled
        ? ContentUpdatePhase.idle
        : ContentUpdatePhase.offline;
    unawaited(loadBundle());
  }

  final ContentRepository _repository;

  /// 平台等价物（web 原型 localStorage）；测试传 null 仅会话内生效。
  final SharedPreferences? prefs;

  // ---------------- 数据包（mock-约定 §5） ----------------
  ContentBundle? _bundle;
  ContentSource? _contentSource;
  LoadPhase _phase = LoadPhase.loading;
  String? _loadError;
  late ContentUpdatePhase _updatePhase;
  String? _updateError;
  Future<void>? _localLoad;
  Future<void>? _updateCheck;
  bool _disposed = false;

  /// 16.22 海克斯研究快照（原型 SNAP）；加载失败 → null = snapReady=false。
  AugmentSnapshot? _snapshot;

  /// 全局统计口径：全部分段 / 高分段（PRD §2.2/§19.2，所有页面同步）。
  String _segment = 'all';

  // 演示统计夹具（与 app-v1.js 同源，逐条由 bundle 派生）。
  List<DemoStat> _demoOverallItems = const [];
  List<DemoStat> _demoStageRecords = const [];
  List<DemoStat> _demoOrderRecords = const [];
  List<DemoStat> _demoChampionAugment = const [];
  List<DemoStat> _demoChampionAugmentStage = const [];
  List<DemoStat> _demoChampionItem = const [];
  List<DemoStat> _demoChampionItemOrder = const [];

  ContentBundle? get bundle => _bundle;
  LoadPhase get phase => _phase;
  String? get loadError => _loadError;
  ContentSource? get contentSource => _contentSource;
  ContentUpdatePhase get updatePhase => _updatePhase;
  String? get updateError => _updateError;
  AugmentSnapshot? get snapshot => _snapshot;
  bool get snapshotReady => _snapshot != null;
  String get segment => _segment;
  List<SnapshotSegment> get segmentOptions => _snapshot?.segments ?? const [];

  List<DemoStat> get demoOverallChampion => kDemoOverallChampion;
  List<DemoStat> get demoOverallAugment => kDemoOverallAugment;
  List<DemoStat> get demoOverallItems => _demoOverallItems;
  List<DemoStat> get demoStageRecords => _demoStageRecords;
  List<DemoStat> get demoOrderRecords => _demoOrderRecords;
  List<DemoStat> get demoChampionAugment => _demoChampionAugment;
  List<DemoStat> get demoChampionAugmentStage => _demoChampionAugmentStage;
  List<DemoStat> get demoChampionItem => _demoChampionItem;
  List<DemoStat> get demoChampionItemOrder => _demoChampionItemOrder;

  /// 原型 segmentLabel()。
  String get segmentLabel {
    for (final option in _snapshot?.segments ?? const <SnapshotSegment>[]) {
      if (option.segment == _segment) return option.labelZh;
    }
    return _segment;
  }

  void setSegment(String segment) {
    _segment = segment;
    notifyListeners();
  }

  /// 原型 stat(type, id, slice)：海克斯域走 16.22 快照，其余走演示夹具。
  DemoStat? stat(String type, String id, {String slice = 'all'}) {
    final data = _bundle;
    if (data == null) return null;
    if (type == 'augment' && _snapshot != null) {
      final snapStat = augmentSnapStat(
        _snapshot!,
        data,
        id,
        slice,
        segment: _segment,
      );
      if (snapStat != null) {
        return DemoStat(
          id: id,
          rank: snapStat.rank,
          wins: null,
          games: snapStat.sampleCount,
          winRatePct: snapStat.winRatePct,
          selectionRatePct: snapStat.pickRatePct,
          tier: snapStat.tier,
          stage: snapStat.stage == null ? 'all' : '${snapStat.stage}',
        );
      }
      return null;
    }
    final list = switch (type) {
      'champion' => slice == 'all' ? kDemoOverallChampion : null,
      'augment' => slice == 'all' ? kDemoOverallAugment : _demoStageRecords,
      _ => slice == 'all' ? _demoOverallItems : _demoOrderRecords,
    };
    if (list == null) return null;
    for (final record in list) {
      if (record.id != id) continue;
      if (slice != 'all') {
        final key = type == 'augment' ? record.stage : record.order;
        if (key != slice) continue;
      }
      return record;
    }
    return null;
  }

  /// 原型 homeStats(type)：快照驱动海克斯域总体前五，其余演示夹具前五。
  List<DemoStat> homeStats(String type) {
    if (type == 'augment' && snapshotReady) {
      final stats = <DemoStat>[];
      for (final augment in _bundle?.augments ?? const <Augment>[]) {
        final record = stat('augment', augment.id, slice: 'all');
        if (record != null) stats.add(record);
      }
      stats.sort((a, b) => a.rank.compareTo(b.rank));
      return stats.take(5).toList();
    }
    final overall = switch (type) {
      'champion' => kDemoOverallChampion,
      'augment' => kDemoOverallAugment,
      _ => _demoOverallItems,
    };
    return overall.take(5).toList();
  }

  Future<void> loadBundle() {
    if (_phase == LoadPhase.ready || _disposed) return Future<void>.value();
    return _localLoad ??= Future<void>.microtask(_loadLocal).whenComplete(() {
      _localLoad = null;
    });
  }

  Future<void> _loadLocal() async {
    if (_disposed) return;
    _phase = LoadPhase.loading;
    _loadError = null;
    notifyListeners();
    try {
      final local = await _repository.loadLocal();
      final snapshot =
          kDebugMode && const bool.fromEnvironment('LOCAL_RESEARCH_PREVIEW')
          ? await AugmentSnapshot.load()
          : null;
      if (_disposed) return;
      _bundle = local.bundle;
      _contentSource = local.source;
      _snapshot = snapshot;
      _deriveDemoStats();
      _segment = _defaultSegment();
      _phase = LoadPhase.ready;
    } catch (error) {
      if (_disposed) return;
      // PRD §14：本地加载失败才进入整页错误；在线失败不影响已加载的数据。
      _phase = LoadPhase.failed;
      _loadError = '本地数据加载失败';
      debugPrint('bundle load failed: $error');
    }
    notifyListeners();
    if (_phase == LoadPhase.ready) unawaited(checkForUpdate());
  }

  Future<void> checkForUpdate() {
    final current = _bundle;
    if (_disposed ||
        !_repository.updatesEnabled ||
        _phase != LoadPhase.ready ||
        current == null) {
      return Future<void>.value();
    }
    return _updateCheck ??=
        Future<void>.microtask(
          () => _checkForUpdate(current.dataset.datasetVersion),
        ).whenComplete(() {
          _updateCheck = null;
        });
  }

  Future<void> _checkForUpdate(String currentVersion) async {
    if (_disposed) return;
    _updatePhase = ContentUpdatePhase.checking;
    _updateError = null;
    notifyListeners();
    try {
      final update = await _repository.checkForUpdate(currentVersion);
      if (_disposed) return;
      if (update == null) {
        _updatePhase = ContentUpdatePhase.upToDate;
      } else {
        _bundle = update.bundle;
        _contentSource = update.source;
        _deriveDemoStats();
        _updatePhase = ContentUpdatePhase.updated;
      }
    } on ContentUpdateException catch (error) {
      _updatePhase = ContentUpdatePhase.failed;
      _updateError = error.message;
    } catch (error) {
      _updatePhase = ContentUpdatePhase.failed;
      _updateError = '暂时无法检查更新，请重试';
      debugPrint('content update failed: $error');
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  String _defaultSegment() {
    final snap = _snapshot;
    if (snap == null) return 'all';
    for (final option in snap.segments) {
      if (option.id == snap.defaultSnapshotId) return option.segment;
    }
    return 'all';
  }

  void _deriveDemoStats() {
    final data = _bundle;
    if (data == null) return;
    final rankedItems = data.items
        .where((item) => !kDemoExcludedItemIds.contains(item.id))
        .toList();
    _demoOverallItems = buildDemoOverallItems(rankedItems);
    _demoStageRecords = buildDemoStageRecords(data);
    _demoOrderRecords = buildDemoOrderRecords(rankedItems);
    _demoChampionAugment = buildDemoChampionAugmentRecords(data);
    _demoChampionAugmentStage = buildDemoChampionAugmentStageRecords(
      data,
      _demoChampionAugment,
    );
    _demoChampionItem = buildDemoChampionItemRecords(data);
    _demoChampionItemOrder = buildDemoChampionItemOrderRecords(data);
  }

  // ---------------- 收藏（PRD §11.1） ----------------
  final List<FavoriteRecord> _favorites = [];

  List<FavoriteRecord> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(EntityType type, String id) =>
      _favorites.any((r) => r.type == type && r.id == id);

  /// 收藏即时切换，无删除确认；重新收藏使用新时间。
  void toggleFavorite(EntityType type, String id) {
    if (isFavorite(type, id)) {
      _favorites.removeWhere((r) => r.type == type && r.id == id);
    } else {
      _favorites.insert(
        0,
        FavoriteRecord(type: type, id: id, savedAt: DateTime.now().toUtc()),
      );
    }
    _saveFavorites();
    notifyListeners();
  }

  void removeFavorite(EntityType type, String id) {
    _favorites.removeWhere((r) => r.type == type && r.id == id);
    _saveFavorites();
    notifyListeners();
  }

  // ---------------- 最近查看（PRD §11.2） ----------------
  static const int _recentsCap = 20;
  final List<RecentRecord> _recents = [];

  List<RecentRecord> get recents => List.unmodifiable(_recents);

  /// 成功解析并展示详情后写入；重复键前移；上限 20，超限删最旧。
  void recordView(EntityType type, String id) {
    _recents.removeWhere((r) => r.type == type && r.id == id);
    _recents.insert(
      0,
      RecentRecord(type: type, id: id, viewedAt: DateTime.now().toUtc()),
    );
    if (_recents.length > _recentsCap) {
      _recents.removeRange(_recentsCap, _recents.length);
    }
    _saveRecents();
    notifyListeners();
  }

  void removeRecent(EntityType type, String id) {
    _recents.removeWhere((r) => r.type == type && r.id == id);
    _saveRecents();
    notifyListeners();
  }

  void clearRecents() {
    _recents.clear();
    _saveRecents();
    notifyListeners();
  }

  // ---------------- 外观（PRD §20） ----------------
  ThemeMode _themeMode = ThemeMode.system;
  bool _storageWarning = false;

  ThemeMode get themeMode => _themeMode;
  bool get storageWarning => _storageWarning;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveTheme();
    notifyListeners();
  }

  // ---------------- 对象定位（详情页与失效记录共用） ----------------

  /// 当前数据范围内解析对象；失效返回 null（PRD §11.1「当前数据范围不可用」）。
  ({String name, String? iconPath, String subline})? describe(
    EntityType type,
    String id,
  ) {
    final data = _bundle;
    if (data == null) return null;
    switch (type) {
      case EntityType.champion:
        final champion = data.championById(id);
        if (champion == null) return null;
        return (
          name: champion.name,
          iconPath: champion.iconPath,
          subline: champion.title ?? champion.roles.join(' / '),
        );
      case EntityType.augment:
        final augment = data.augmentById(id);
        if (augment == null) return null;
        return (
          name: augment.name,
          iconPath: augment.iconPath,
          subline: augment.rarityZh,
        );
      case EntityType.item:
        final item = data.itemById(id);
        if (item == null) return null;
        return (name: item.name, iconPath: item.iconPath, subline: '装备');
    }
  }

  // ---------------- 持久化（PRD §11.3：损坏独立降级，不覆盖原值） ----------------

  void restoreLocalState() {
    _restoreFavorites();
    _restoreRecents();
    _restoreTheme();
    notifyListeners();
  }

  void _restoreFavorites() {
    final items = _readCollection(
      'haidou.favorites.v1',
      allowedTypes: const [EntityType.champion, EntityType.augment],
    );
    _favorites
      ..clear()
      ..addAll([
        for (final entry in items)
          FavoriteRecord(type: entry.type, id: entry.id, savedAt: entry.time),
      ]);
  }

  void _restoreRecents() {
    final items = _readCollection(
      'haidou.recents.v1',
      allowedTypes: EntityType.values,
    );
    _recents
      ..clear()
      ..addAll([
        for (final entry in items)
          RecentRecord(type: entry.type, id: entry.id, viewedAt: entry.time),
      ]);
    // 上限 20（PRD §11.2：超限删除最旧项）。
    if (_recents.length > _recentsCap) {
      _recents.removeRange(_recentsCap, _recents.length);
    }
  }

  void _restoreTheme() {
    final raw = prefs?.getString('haidou.theme.v1');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> &&
          decoded['schemaVersion'] == 1 &&
          decoded['mode'] is String) {
        final mode = decoded['mode'] as String;
        _themeMode = switch (mode) {
          'day' => ThemeMode.light,
          'night' => ThemeMode.dark,
          'system' => ThemeMode.system,
          _ => ThemeMode.system, // 未知值降级跟随系统，不覆盖原值
        };
      }
    } catch (_) {
      // 损坏降级为跟随系统（PRD §20.3），不报错、不阻塞。
      _themeMode = ThemeMode.system;
    }
  }

  // Matches 原型图/data/legacy-id-remap.json for records saved by the old fixture.
  static const _legacyAugmentIds = {
    '1337': '3048',
    '2054': '2062',
    '1103': '3075',
    '1205': '1206',
  };

  List<({EntityType type, String id, DateTime time})> _readCollection(
    String key, {
    required List<EntityType> allowedTypes,
  }) {
    final raw = prefs?.getString(key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
        return const [];
      }
      final items = decoded['items'];
      if (items is! List) return const [];
      final parsed = <({EntityType type, String id, DateTime time})>[];
      for (final entry in items) {
        if (entry is! Map<String, dynamic>) continue;
        final type = _parseEntityType(entry['entityType']);
        final id = entry['entityId'];
        final timeRaw = entry['savedAt'] ?? entry['viewedAt'];
        final time = timeRaw is String ? DateTime.tryParse(timeRaw) : null;
        if (type == null ||
            !allowedTypes.contains(type) ||
            id is! String ||
            id.isEmpty ||
            id.length > 100 ||
            time == null) {
          continue; // 单条非法跳过；集合级损坏走 catch 清空
        }
        final resolvedId = type == EntityType.augment
            ? _legacyAugmentIds[id] ?? id
            : id;
        parsed.add((type: type, id: resolvedId, time: time));
      }
      parsed.sort((a, b) => b.time.compareTo(a.time));
      final seen = <(EntityType, String)>{};
      return [
        for (final entry in parsed)
          if (seen.add((entry.type, entry.id))) entry,
      ];
    } catch (_) {
      return const []; // 集合损坏只恢复该集合为空并提示（PRD §11.3）
    }
  }

  void _saveFavorites() {
    _writeCollection('haidou.favorites.v1', [
      for (final record in _favorites)
        {
          'entityType': record.type.storageName,
          'entityId': record.id,
          'savedAt': record.savedAt.toIso8601String(),
        },
    ]);
  }

  void _saveRecents() {
    _writeCollection('haidou.recents.v1', [
      for (final record in _recents)
        {
          'entityType': record.type.storageName,
          'entityId': record.id,
          'viewedAt': record.viewedAt.toIso8601String(),
        },
    ]);
  }

  void _writeCollection(String key, List<Map<String, String>> items) {
    final store = prefs;
    if (store == null) return; // 测试环境无持久化，仅会话内生效
    try {
      store.setString(key, jsonEncode({'schemaVersion': 1, 'items': items}));
      _storageWarning = false;
    } catch (_) {
      // 写入失败继续会话操作，持续提示（PRD §11.3）。
      _storageWarning = true;
    }
  }

  void _saveTheme() {
    final store = prefs;
    if (store == null) return;
    final mode = switch (_themeMode) {
      ThemeMode.light => 'day',
      ThemeMode.dark => 'night',
      ThemeMode.system => 'system',
    };
    try {
      store.setString(
        'haidou.theme.v1',
        jsonEncode({'schemaVersion': 1, 'mode': mode}),
      );
    } catch (_) {
      // 外观存储异常只降级外观保存，不影响其他功能（PRD §20.3）。
    }
  }
}

enum LoadPhase { loading, ready, failed }

enum ContentUpdatePhase { offline, idle, checking, upToDate, updated, failed }

/// 收藏/历史对象类型（PRD §11：champion / augment；历史另有 item）。
enum EntityType {
  champion('champion', '英雄'),
  augment('augment', '海克斯'),
  item('item', '装备');

  const EntityType(this.storageName, this.labelZh);

  /// 存储字段原样值（与 web 原型记录同构）。
  final String storageName;
  final String labelZh;

  static EntityType? fromStorageName(String? value) => switch (value) {
    'champion' => champion,
    'augment' => augment,
    'item' => item,
    _ => null,
  };
}

EntityType? _parseEntityType(Object? value) =>
    value is String ? EntityType.fromStorageName(value) : null;

class FavoriteRecord {
  const FavoriteRecord({
    required this.type,
    required this.id,
    required this.savedAt,
  });

  final EntityType type;
  final String id;
  final DateTime savedAt;
}

class RecentRecord {
  const RecentRecord({
    required this.type,
    required this.id,
    required this.viewedAt,
  });

  final EntityType type;
  final String id;
  final DateTime viewedAt;
}
