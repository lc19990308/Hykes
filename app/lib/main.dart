import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/data/content_repository.dart';
import 'core/state/app_state.dart';

/// 首帧使用本地外观和内容；在线更新不阻塞渲染。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final state = AppState(
    prefs: prefs,
    repository: ContentRepository(
      apiBaseUrl: const String.fromEnvironment('HAIDOU_API_BASE_URL'),
      cacheDirectory: getApplicationSupportDirectory,
    ),
  );
  state.restoreLocalState();
  await state.loadBundle();
  runApp(HykesApp(state: state));
}
