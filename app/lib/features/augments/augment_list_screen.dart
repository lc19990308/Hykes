import 'package:material_ui/material_ui.dart';

import '../../core/state/app_state.dart';
import '../ranking/ranking_page.dart';
import 'augment_detail_screen.dart';

class AugmentListScreen extends StatelessWidget {
  const AugmentListScreen({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) => RankingPage(
    state: state,
    type: EntityType.augment,
    onOpen: (context, id, slice) => Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AugmentDetailScreen(
          state: state,
          augmentId: id,
          initialStage: slice?.toString() ?? 'all',
        ),
      ),
    ),
  );
}
