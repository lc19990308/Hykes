import 'package:material_ui/material_ui.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/object_row.dart';
import '../../shared/widgets/panels.dart';
import '../augments/augment_detail_screen.dart';
import '../champions/champion_detail_screen.dart';
import '../items/item_detail_screen.dart';

/// 最近查看（R08 §11.2）：三类对象共用最多 20 项，viewedAt 降序；
/// 清空需确认（C12），取消为默认焦点。
class RecentsScreen extends StatelessWidget {
  const RecentsScreen({required this.state, super.key});

  final AppState state;

  void _openDetail(BuildContext context, EntityType type, String id) {
    switch (type) {
      case EntityType.champion:
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChampionDetailScreen(state: state, championId: id)));
      case EntityType.augment:
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AugmentDetailScreen(state: state, augmentId: id)));
      case EntityType.item:
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ItemDetailScreen(state: state, itemId: id)));
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    // C12 清空确认：初始焦点取消；遮罩/系统返回取消；确认只清历史。
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).extension<AppPalette>()!.raised,
        title: const Text('清空最近查看？'),
        content: const Text('收藏不受影响。'),
        actions: [
          OutlinedButton(
            autofocus: true,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(dialogContext).extension<AppPalette>()!.dangerBackground,
              foregroundColor:
                  Theme.of(dialogContext).extension<AppPalette>()!.dangerForeground,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed == true) state.clearRecents();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final list = state.recents;
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: const Text('最近查看'),
        actions: [
          if (list.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context),
              child: const Text('清空'),
            ),
        ],
      ),
      body: list.isEmpty
          ? const Center(
              child: EmptyPanel(
                title: '还没有最近查看',
                description: '打开英雄、海克斯或装备详情后，记录会显示在这里（最多 20 项）。',
              ),
            )
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final record = list[index];
                final info = state.describe(record.type, record.id);
                if (info == null) {
                  // 失效记录：保留条目与移除入口（PRD §14）。
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s5, vertical: AppSpacing.s3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('当前数据范围不可用',
                            style: AppTextStyles.meta
                                .copyWith(color: palette.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          '对象 ID：${record.id}（${record.type.labelZh}）',
                          style: AppTextStyles.meta
                              .copyWith(color: palette.textMuted),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () =>
                                state.removeRecent(record.type, record.id),
                            child: const Text('移除记录'),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ObjectRow(
                  iconPath: info.iconPath,
                  name: info.name,
                  subline: info.subline,
                  trailing: Text(
                    '${record.viewedAt.month}/${record.viewedAt.day} 查看',
                    style:
                        AppTextStyles.caption.copyWith(color: palette.textMuted),
                  ),
                  onTap: () => _openDetail(context, record.type, record.id),
                );
              },
            ),
    );
  }
}
