import 'package:material_ui/material_ui.dart';

import '../../core/data/search.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/sections.dart';

/// 数据说明（R09）：指标、来源、覆盖、时效与使用限制。
/// 文案与 web 原型口径一致，按 mock 阶段如实标注（部分示例、模拟统计）。
class DataInfoScreen extends StatelessWidget {
  const DataInfoScreen({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final bundle = state.bundle;
    final completed = bundle == null
        ? 0
        : bundle.items.where((i) => !kDemoExcludedItemIds.contains(i.id)).length;
    final excluded = bundle == null ? 0 : kDemoExcludedItemIds.length;
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(title: const Text('数据说明')),
      body: bundle == null
          ? Center(
              child: Text('数据未加载',
                  style: AppTextStyles.meta.copyWith(color: palette.textMuted)))
          : ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s5, vertical: AppSpacing.s4),
              children: [
                _section(context, '当前覆盖',
                    '收录 ${bundle.champions.length} 名英雄、${bundle.augments.length} 个海克斯、$completed 件成装（另有 $excluded 件出门装、药水与鞋子仅在英雄出装中展示）和 ${bundle.builds.length} 套人工出装。仅为部分示例，不是完整游戏数据。'),
                _section(context, '统计范围',
                    state.snapshotReady
                         ? '海克斯榜使用采集快照；英雄、装备及搭配统计是演示值。'
                         : '当前使用 ${bundle.dataset.datasetVersion}。胜率、选取率、名次和场次为演示值，不是采集结果。'),
                _section(context, '胜率与选取率',
                    '胜率按胜场 ÷ 场次计算，保留一位小数。模拟选取率为该统计上下文中选择该对象的比例；仅用于界面展示，未提供可独立复算的分母。'),
                _section(context, '独立统计条件',
                    '总体、海克斯阶段、英雄搭配、装备购买顺序使用独立记录。缺少条件数据时显示暂无统计，不套用总体值，不平均多个百分比。'),
                _section(context, '样本与排序',
                    '少于 200 场标为样本较少，200 场不标低样本。未知样本不能判断可靠程度。缺失数值排在末尾。示例排名为人工编排的演示序号，不来自来源，不得标为「来源排名」。'),
                _section(context, '推荐与机制',
                    '玩法、加点、强化理由和出装为人工练习示例。来源页已核对不代表当前版本核验。未收录为可出现的阶段也需要在当前客户端确认。'),
                _section(context, '本机保存',
                    '收藏仅支持英雄和海克斯；最近查看支持三类对象。内容保存在当前设备，最多保留 20 条历史。保存失败时保留会话内操作，未来格式的旧记录不会被覆盖。'),
                _section(context, '素材说明',
                    '使用项目已有游戏图标和 Lucide 线性图标。游戏素材来源保留在本地索引；公开可访问不等于已取得再分发或商用许可。'),
                const SizedBox(height: AppSpacing.s4),
                _section(context, '来源记录',
                    '共 ${bundle.sources.length} 条来源记录（研究参考与实际数据来源分开标记）；授权边界随来源记录逐条保留。'),
              ],
            ),
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(title: title),
          const SizedBox(height: AppSpacing.s2),
          Text(
            body,
            style: AppTextStyles.body.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}
