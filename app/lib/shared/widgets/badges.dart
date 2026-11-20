import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';

/// C10 非交互中性徽标：13/22、内边距 4/8、圆角 8，语义完全由文字承担，
/// 不用颜色编码；夜间按夜间 Token 成对换色，文字不变。
class NeutralBadge extends StatelessWidget {
  const NeutralBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s2, vertical: AppSpacing.s1),
      decoration: BoxDecoration(
        color: palette.neutralBadgeBackground,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption
            .copyWith(color: palette.neutralBadgeForeground),
      ),
    );
  }
}

/// 常用口径徽标（PRD §12 / C10 放置规则）。
class SimulatedBadge extends NeutralBadge {
  const SimulatedBadge({super.key}) : super('模拟数据');
}

class ExampleBadge extends NeutralBadge {
  const ExampleBadge({super.key}) : super('示例内容');
}

class PendingBadge extends NeutralBadge {
  const PendingBadge({super.key}) : super('待核对');
}

class LowSampleBadge extends NeutralBadge {
  const LowSampleBadge({super.key}) : super('样本较少');
}

class StaleBadge extends NeutralBadge {
  const StaleBadge({super.key}) : super('内容可能过期');
}
