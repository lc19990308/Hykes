import 'package:material_ui/material_ui.dart';

import 'core/state/app_state.dart';
import 'features/augments/augment_list_screen.dart';
import 'features/champions/champion_list_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/home/home_screen.dart';
import 'features/items/item_list_screen.dart';
import 'shared/widgets/primary_navigation.dart';

/// 根页导航壳：首页 / 英雄 / 海克斯 / 装备 / 收藏（设计体系 C09，PRD §2.1）。
///
/// - 五项等宽、全部带标签；选中为主色文字 + 600 字重 + 主色顶部标记。
/// - IndexedStack 保持各页签的滚动位置与筛选状态（PRD F08 会话内保留）。
/// - 当前页签再次点击不创建新导航栈（C09）。
class AppShell extends StatefulWidget {
  const AppShell({required this.state, super.key});

  final AppState state;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _switchTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // 每次 build 重新构造页签实例：AppState 通知（数据包加载完成等）
    // 传导到各页 re-read phase；element 复用保证各页签滚动位置与
    // 筛选状态保留（PRD F08）。缓存旧实例会让子树跳过 rebuild，
    // 页面停留在首次构建时的 loading 态。
    final tabs = [
      HomeScreen(state: widget.state, onSwitchTab: _switchTab),
      ChampionListScreen(state: widget.state),
      AugmentListScreen(state: widget.state),
      ItemListScreen(state: widget.state),
      FavoritesScreen(state: widget.state, onSwitchTab: _switchTab),
    ];
    return Scaffold(
      // IndexedStack 保持各页签的滚动位置与内部状态（PRD §2.1 会话内保留）。
      body: IndexedStack(index: _selectedIndex, children: tabs),
      bottomNavigationBar: PrimaryNavigation(
        selectedIndex: _selectedIndex,
        onSelected: _onTabSelected,
      ),
    );
  }

  void _onTabSelected(int index) {
    if (index == _selectedIndex) {
      // 当前页签再次点击：不创建新导航栈（C09）。
      return;
    }
    setState(() => _selectedIndex = index);
  }
}
