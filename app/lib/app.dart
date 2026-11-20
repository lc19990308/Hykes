import 'package:material_ui/material_ui.dart';

import 'app_shell.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';

/// 海斗宝典 App 根组件。
///
/// 外观（PRD v1.2 R19）：白天 / 晚上 / 跟随系统三态，默认跟随系统；
/// 首帧不闪烁——持久化值在 runApp 前解析（main.dart），不先白天后夜间。
/// 白天模式视觉与 v0.2 浅色基线零变化；夜间为深墨蓝系夜间 Token。
class HykesApp extends StatelessWidget {
  const HykesApp({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => MaterialApp(
        title: '海斗宝典',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: state.themeMode,
        home: AppShell(state: state),
      ),
    );
  }
}
