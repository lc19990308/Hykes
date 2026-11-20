import 'package:material_ui/material_ui.dart';

import '../../core/state/app_state.dart';
import '../ranking/ranking_page.dart';
import 'champion_detail_screen.dart';

class ChampionListScreen extends StatelessWidget {
  const ChampionListScreen({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) => RankingPage(
    state: state,
    type: EntityType.champion,
    onOpen: (context, id, slice) => Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChampionDetailScreen(state: state, championId: id),
      ),
    ),
  );
}
