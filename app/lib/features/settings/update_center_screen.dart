import 'package:material_ui/material_ui.dart';

import '../../core/data/content_repository.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/sections.dart';

class UpdateCenterScreen extends StatelessWidget {
  const UpdateCenterScreen({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) {
      final palette = AppPalette.of(context);
      final datasetVersion = state.bundle?.dataset.datasetVersion ?? '未加载';
      final source = switch (state.contentSource) {
        ContentSource.bundled => '应用内置',
        ContentSource.cache => '本地缓存',
        ContentSource.downloaded => '更新服务',
        null => '暂无',
      };
      final phase = state.updatePhase;
      final status = switch (phase) {
        ContentUpdatePhase.offline => '离线模式（未配置更新服务）',
        ContentUpdatePhase.idle => '尚未检查',
        ContentUpdatePhase.checking => '正在检查更新…',
        ContentUpdatePhase.upToDate => '已是最新版本',
        ContentUpdatePhase.updated => '已更新到当前版本',
        ContentUpdatePhase.failed => '更新失败，继续使用当前内容',
      };
      final error = state.loadError ?? state.updateError;
      return Scaffold(
        backgroundColor: palette.canvas,
        appBar: AppBar(title: const Text('更新中心')),
        body: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s4,
          ),
          children: [
            ContentGroup(
              padding: const EdgeInsets.all(AppSpacing.s6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    datasetVersion,
                    style: AppTextStyles.stat.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    '来源：$source',
                    style: AppTextStyles.meta.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Semantics(
                    liveRegion: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '状态：$status',
                          style: AppTextStyles.body.copyWith(
                            color: palette.textPrimary,
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: AppSpacing.s2),
                          Text(
                            error,
                            style: AppTextStyles.meta.copyWith(
                              color: palette.dangerForeground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  OutlinedButton(
                    onPressed:
                        phase == ContentUpdatePhase.offline ||
                            phase == ContentUpdatePhase.checking ||
                            state.phase != LoadPhase.ready
                        ? null
                        : () => state.checkForUpdate(),
                    child: const Text('检查更新'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
