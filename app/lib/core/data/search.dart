import 'content_bundle.dart';

/// 搜索与排序规则（PRD §4）。
///
/// 匹配优先级（英雄五级，海克斯/装备两级）：
/// 名称完全 → 称号/别名完全 → 拼音/首字母完全 → 名称/称号/别名包含 → 拼音/首字母前缀。
/// 无相应字段的类别跳过该级；无关键词时直接按用户排序；最后以稳定 ID 升序收尾。

/// 匹配得分：值越小越靠前；null 表示不命中。
int? matchScore({required String query, String? name, String? title,
    List<String> aliases = const [], String? pinyin, String? initials}) {
  final q = _normalizeLatin(query.trim());
  if (q.isEmpty) return 0; // 纯空白视为空查询

  final normalizedName = _normalizeLatin(name ?? '');
  if (normalizedName == q) return 1;

  if (title != null && _normalizeLatin(title) == q) return 2;
  for (final alias in aliases) {
    if (_normalizeLatin(alias) == q) return 2;
  }

  // 仅拼音/首字母比较时忽略空格（PRD §4.1）。
  final normalizedPinyin = _stripSpaces(pinyin);
  final normalizedInitials = _stripSpaces(initials);
  if (normalizedPinyin == q || normalizedInitials == q) return 3;

  if (normalizedName.contains(q)) return 4;
  if (title != null && _normalizeLatin(title).contains(q)) return 4;
  for (final alias in aliases) {
    if (_normalizeLatin(alias).contains(q)) return 4;
  }

  if (normalizedPinyin?.startsWith(q) ?? false) return 5;
  if (normalizedInitials?.startsWith(q) ?? false) return 5;

  return null;
}

/// 拉丁字母大小写不敏感（中文原样比较）。
String _normalizeLatin(String value) => value.toLowerCase();

String? _stripSpaces(String? value) => value?.replaceAll(' ', '');

/// 英雄搜索（name/title/aliases/pinyin/initials）。
List<Champion> searchChampions(ContentBundle bundle, String query,
    {String? role}) {
  final results = <(int, Champion)>[];
  for (final champion in bundle.champions) {
    if (role != null && !_championHasRole(champion, role)) continue;
    final score = matchScore(
      query: query,
      name: champion.name,
      title: champion.title,
      aliases: champion.aliases,
      pinyin: champion.pinyin,
      initials: champion.initials,
    );
    if (score != null) results.add((score, champion));
  }
  results.sort(_compareScoredChampion);
  return [for (final entry in results) entry.$2];
}

/// 海克斯/装备搜索（name/aliases；PRD：不凭空支持拼音）。
List<Augment> searchAugments(ContentBundle bundle, String query,
    {String? rarity, int? stage}) {
  final results = <(int, Augment)>[];
  for (final augment in bundle.augments) {
    if (rarity != null && augment.rarity != rarity) continue;

    /// 阶段筛选（PRD §6）：「全部」读取总体记录；选阶段后限确认可出现者，
    /// 出现阶段未知者不纳入。demo 口径 stageStatus=source-page-only，
    /// stages 非空即视为已确认可在该阶段出现。
    if (stage != null && !augment.stages.contains(stage)) continue;
    final score = matchScore(
      query: query,
      name: augment.name,
      aliases: augment.aliases,
    );
    if (score != null) results.add((score, augment));
  }
  results.sort((a, b) {
    final byScore = a.$1.compareTo(b.$1);
    if (byScore != 0) return byScore;
    return _compareAugment(a.$2, b.$2);
  });
  return [for (final entry in results) entry.$2];
}

List<Item> searchItems(ContentBundle bundle, String query,
    {required bool completedOnly}) {
  final pool = completedOnly
      ? bundle.items.where((i) => !kDemoExcludedItemIds.contains(i.id))
      : bundle.items;
  final results = <(int, Item)>[];
  for (final item in pool) {
    final score = matchScore(query: query, name: item.name);
    if (score != null) results.add((score, item));
  }
  results.sort((a, b) {
    final byScore = a.$1.compareTo(b.$1);
    if (byScore != 0) return byScore;
    return a.$2.id.compareTo(b.$2.id);
  });
  return [for (final entry in results) entry.$2];
}

/// demo-0.1 未提供 itemType 字段（缺口盘点 §2.5）；成装榜沿用 web 原型的
/// 排除清单口径（app-v1.js EXCLUDED_ITEM_IDS 8/8 吻合）。
/// TODO(demo-0.2): itemType 数据化后删除本清单，改按字段过滤。
const Set<String> kDemoExcludedItemIds = {
  '2003', // 生命药水
  '3006', // 狂战士胫甲
  '3020', // 法师之靴
  '3047', // 铁板靴
  '3111', // 水银之靴
  '3112', // 明朗之靴
  '3177', // 守护者战锤
  '3184', // 守护者弓
};

/// 英雄默认排序：示例排名（displayOrder）升序，缺失置后按 ID（PRD §4.2）。
int _compareScoredChampion((int, Champion) a, (int, Champion) b) {
  final byScore = a.$1.compareTo(b.$1);
  if (byScore != 0) return byScore;
  return _compareChampion(a.$2, b.$2);
}

int _compareChampion(Champion a, Champion b) {
  final byOrder = (a.displayOrder ?? _kLarge).compareTo(b.displayOrder ?? _kLarge);
  if (byOrder != 0) return byOrder;
  return a.id.compareTo(b.id);
}

int _compareAugment(Augment a, Augment b) {
  final byOrder =
      (a.displayOrder ?? _kLarge).compareTo(b.displayOrder ?? _kLarge);
  if (byOrder != 0) return byOrder;
  return a.id.compareTo(b.id);
}

bool _championHasRole(Champion champion, String role) {
  // 多定位英雄命中任一即可（PRD §5）。
  return champion.roles.contains(role);
}

const int _kLarge = 1 << 30;
