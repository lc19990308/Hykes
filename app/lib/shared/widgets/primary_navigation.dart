import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import 'prototype_icon.dart';

/// C09 bottom navigation. The device inset is separate from the tab height.
class PrimaryNavigation extends StatelessWidget {
  const PrimaryNavigation({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _destinations = [
    (label: '首页', icon: PrototypeGlyph.home),
    (label: '英雄', icon: PrototypeGlyph.swords),
    (label: '海克斯', icon: PrototypeGlyph.gem),
    (label: '装备', icon: PrototypeGlyph.shield),
    (label: '收藏', icon: PrototypeGlyph.bookmark),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.canvas,
        border: Border(
          top: BorderSide(
            color: palette.borderPlain,
            width: AppStroke.defaultWidth,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Material(
          type: MaterialType.transparency,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < _destinations.length; index++)
                  Expanded(child: _buildTab(palette, index)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(AppPalette palette, int index) {
    final destination = _destinations[index];
    final selected = index == selectedIndex;
    final color = selected ? palette.actionPrimary : palette.textMuted;
    void onTap() => onSelected(index);

    return Semantics(
      button: true,
      selected: selected,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        excludeFromSemantics: true,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return palette.focus.withValues(alpha: .16);
          }
          if (states.contains(WidgetState.hovered)) return palette.surface;
          return Colors.transparent;
        }),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppLayout.bottomNavMinHeight,
          ),
          padding: const EdgeInsets.all(AppSpacing.s2),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: selected ? palette.actionPrimary : Colors.transparent,
                width: AppStroke.selected,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PrototypeIcon(destination.icon, color: color),
              const SizedBox(height: AppSpacing.s1),
              Text(
                destination.label,
                textAlign: TextAlign.center,
                style: AppTextStyles.navLabel.copyWith(
                  inherit: false,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
