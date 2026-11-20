import 'package:material_ui/material_ui.dart';

/// Transparent 4× exports of the local Lucide and prototype icon paths.
/// The active theme controls the tint; no SVG runtime is needed.
enum PrototypeGlyph {
  home('home'),
  swords('swords'),
  gem('gem'),
  shield('shield'),
  bookmark('bookmark'),
  search('search'),
  info('info'),
  check('check'),
  close('x'),
  previous('chevron-left'),
  next('chevron-right'),
  settings('settings'),
  filters('sliders');

  const PrototypeGlyph(this.assetName);
  final String assetName;
}

class PrototypeIcon extends StatelessWidget {
  const PrototypeIcon(this.glyph, {this.size = 24, this.color, super.key});

  final PrototypeGlyph glyph;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/icons/lucide/proto-${glyph.assetName}.png',
    width: size,
    height: size,
    color: color ?? IconTheme.of(context).color,
    colorBlendMode: BlendMode.srcIn,
    excludeFromSemantics: true,
    filterQuality: FilterQuality.medium,
  );
}
