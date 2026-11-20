import 'package:material_ui/material_ui.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/sections.dart';
import '../data_info/data_info_screen.dart';
import '../favorites/favorites_screen.dart';
import '../recents/recents_screen.dart';
import 'update_center_screen.dart';

/// 设置（C18/R19）：版本与内容 / 外观三态 / 本机记录。
/// 外观行即选择（无二级页），当前模式以勾选标记表达；
/// 跟随系统随系统即时变化，显式选择后不再随系统（PRD §20.2）。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final systemDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s6),
        children: [
          const SizedBox(height: AppSpacing.s4),
          _group(
            context,
            title: '版本与内容',
            children: [
              _settingRow(
                context,
                title: '更新中心',
                meta:
                    '应用 1.0.0 · 数据 ${state.bundle?.dataset.datasetVersion ?? '未加载'}',
                onTap: () => _push(context, UpdateCenterScreen(state: state)),
              ),
              _settingRow(
                context,
                title: '数据说明',
                meta: '统计口径、覆盖范围与素材说明',
                onTap: () => _push(context, DataInfoScreen(state: state)),
              ),
            ],
          ),
          _group(
            context,
            title: '外观',
            children: [
              for (final (mode, title, meta) in [
                (ThemeMode.light, '白天', '浅色配色'),
                (ThemeMode.dark, '晚上', '深墨蓝夜间配色'),
                (ThemeMode.system, '跟随系统', systemDark ? '当前系统深色' : '当前系统浅色'),
              ])
                _settingRow(
                  context,
                  title: title,
                  meta: meta,
                  trailing: state.themeMode == mode
                      ? Icon(
                          Icons.check,
                          size: 20,
                          color: palette.actionPrimary,
                        )
                      : null,
                  onTap: () => state.setThemeMode(mode),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s2,
                  AppSpacing.s4,
                  0,
                ),
                child: Text(
                  '选择仅保存在本机。跟随系统时，系统切换深浅色即时生效。',
                  style: AppTextStyles.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ),
            ],
          ),
          _group(
            context,
            title: '本机记录',
            children: [
              _settingRow(
                context,
                title: '我的收藏',
                meta: '${state.favorites.length} 项',
                onTap: () => _push(context, FavoritesScreen(state: state)),
              ),
              _settingRow(
                context,
                title: '最近查看',
                meta: '${state.recents.length} 项',
                onTap: () => _push(context, RecentsScreen(state: state)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
            child: Text(
              '无需登录。本机记录保存在当前设备，暂不支持跨设备同步。',
              style: AppTextStyles.caption.copyWith(color: palette.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s2,
        AppSpacing.s5,
        AppSpacing.s2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(title: title),
          const SizedBox(height: AppSpacing.s2),
          ContentGroup(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  /// C18 设置行：整行按钮最小高 72，标题 16/600 + meta + 右侧 chevron/勾选。
  Widget _settingRow(
    BuildContext context, {
    required String title,
    required String meta,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final palette = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.itemTitle.copyWith(
                      color: palette.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: AppTextStyles.meta.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(Icons.chevron_right, size: 20, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

void _push(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}
