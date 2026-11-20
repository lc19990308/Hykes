import 'package:material_ui/material_ui.dart';

import '../../core/state/app_state.dart';
import '../ranking/ranking_page.dart';
import 'item_detail_screen.dart';

class ItemListScreen extends StatelessWidget {
  const ItemListScreen({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) => RankingPage(
    state: state,
    type: EntityType.item,
    onOpen: (context, id, slice) => Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(
          state: state,
          itemId: id,
          initialOrder: slice?.toString() ?? 'all',
        ),
      ),
    ),
  );
}
