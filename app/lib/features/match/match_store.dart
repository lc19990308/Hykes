import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/content_bundle.dart';

const matchOwnedLimit = 4;
const matchCandidateLimit = 3;

enum MatchPressure { normal, defense }

class MatchRecord {
  const MatchRecord.empty()
    : championId = null,
      owned = const [],
      candidates = const [],
      pressure = MatchPressure.normal;

  MatchRecord._({
    required this.championId,
    required Iterable<String> owned,
    required Iterable<String> candidates,
    required this.pressure,
  }) : owned = List.unmodifiable(owned),
       candidates = List.unmodifiable(candidates);

  final String? championId;
  final List<String> owned;
  final List<String> candidates;
  final MatchPressure pressure;

  MatchRecord selectChampion(String id) =>
      championId == id ? this : const MatchRecord.empty()._copy(championId: id);

  MatchRecord editOwned(List<String> ids) => _copy(
    owned: ids,
    candidates: candidates.where((id) => !ids.contains(id)),
  );

  MatchRecord editCandidates(List<String> ids) => _copy(candidates: ids);

  MatchRecord take(String id) =>
      _copy(owned: [...owned, id], candidates: const []);

  MatchRecord setPressure(MatchPressure value) => _copy(pressure: value);

  MatchRecord _copy({
    String? championId,
    Iterable<String>? owned,
    Iterable<String>? candidates,
    MatchPressure? pressure,
  }) => MatchRecord._(
    championId: championId ?? this.championId,
    owned: owned ?? this.owned,
    candidates: candidates ?? this.candidates,
    pressure: pressure ?? this.pressure,
  );

  Map<String, Object?> _encode() => {
    'championId': championId,
    'augments': owned,
    'candidates': candidates,
    'pressure': pressure.name,
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
  };
}

/// Only the current local match is stored here, independently of AppState.
class MatchStore {
  MatchStore(this.bundle, this._prefs) {
    _restore();
  }

  static const storageKey = 'haidou.match.v1';
  static const _schemaVersion = 1;

  final ContentBundle bundle;
  final SharedPreferences? _prefs;
  MatchRecord _record = const MatchRecord.empty();
  _StorageStatus _status = _StorageStatus.ready;

  MatchRecord get record => _record;

  String get storageMessage => switch (_status) {
    _StorageStatus.ready => '本机自动保存',
    _StorageStatus.unavailable => '本机存储不可用，记录仅在本次会话内保留。',
    _StorageStatus.unsupported => '本局记录格式不受支持，原记录已保留；修改仅在本次会话内保留。',
    _StorageStatus.invalid => '本局记录无法读取，已从空白开始；收藏和最近查看不受影响。',
    _StorageStatus.writeFailed => '本局保存失败，本次会话仍可继续；重启后可能丢失。',
  };

  bool get hasStorageWarning => _status != _StorageStatus.ready;

  Future<void> save(MatchRecord next) async {
    final prefs = _prefs;
    _record = next;
    if (prefs == null || _status == _StorageStatus.unsupported) return;
    try {
      final saved = await prefs.setString(
        storageKey,
        jsonEncode({'schemaVersion': _schemaVersion, 'match': next._encode()}),
      );
      _status = saved ? _StorageStatus.ready : _StorageStatus.writeFailed;
    } catch (_) {
      _status = _StorageStatus.writeFailed;
    }
  }

  void _restore() {
    final prefs = _prefs;
    if (prefs == null) {
      _status = _StorageStatus.unavailable;
      return;
    }
    try {
      final raw = prefs.get(storageKey);
      if (raw == null) return;
      if (raw is! String) throw const FormatException();
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      final version = decoded['schemaVersion'];
      if (version is! int) throw const FormatException();
      if (version != _schemaVersion) {
        _status = _StorageStatus.unsupported;
        return;
      }
      final data = decoded['match'];
      if (data is! Map<String, Object?> || !data.containsKey('championId')) {
        throw const FormatException();
      }
      final championId = data['championId'];
      if (championId != null &&
          (championId is! String || bundle.championById(championId) == null)) {
        throw const FormatException();
      }
      final owned = _readAugments(data['augments'], matchOwnedLimit);
      final candidates = _readAugments(data['candidates'], matchCandidateLimit);
      final pressure = switch (data['pressure']) {
        'normal' => MatchPressure.normal,
        'defense' => MatchPressure.defense,
        _ => throw const FormatException(),
      };
      if (candidates.any(owned.contains) ||
          (championId == null &&
              (owned.isNotEmpty ||
                  candidates.isNotEmpty ||
                  pressure != MatchPressure.normal))) {
        throw const FormatException();
      }
      _record = MatchRecord._(
        championId: championId as String?,
        owned: owned,
        candidates: candidates,
        pressure: pressure,
      );
    } catch (_) {
      _status = _StorageStatus.invalid;
    }
  }

  List<String> _readAugments(Object? value, int limit) {
    if (value is! List<Object?> || value.length > limit) {
      throw const FormatException();
    }
    final ids = <String>{};
    for (final id in value) {
      if (id is! String || bundle.augmentById(id) == null || !ids.add(id)) {
        throw const FormatException();
      }
    }
    return ids.toList();
  }
}

enum _StorageStatus { ready, unavailable, unsupported, invalid, writeFailed }
