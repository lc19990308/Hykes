import 'dart:async';

import 'package:app/core/data/content_repository.dart';
import 'package:app/core/state/app_state.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/settings/update_center_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _UpdateRepository extends ContentRepository {
  _UpdateRepository()
    : super(
        loader: () async => '''
    {"schemaVersion":1, "dataset":{"datasetVersion":"demo-0.1","mode":"demo"}}
  ''',
      );

  final checks = <Completer<LoadedContent?>>[];

  @override
  bool get updatesEnabled => true;

  @override
  Future<LoadedContent?> checkForUpdate(String currentVersion) {
    final pending = Completer<LoadedContent?>();
    checks.add(pending);
    return pending.future;
  }
}

Widget _screen(AppState state) => MaterialApp(
  theme: AppTheme.light(),
  home: UpdateCenterScreen(state: state),
);

void main() {
  testWidgets('未配置更新地址时显示内置来源，禁用检查按钮', (tester) async {
    final state = AppState();
    addTearDown(state.dispose);
    await tester.runAsync(state.loadBundle);
    await tester.pumpWidget(_screen(state));
    await tester.pumpAndSettle();
    expect(find.text('demo-0.1'), findsOneWidget);
    expect(find.text('来源：应用内置'), findsOneWidget);
    expect(find.textContaining('离线模式'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
  });

  testWidgets('在线检查失败保持版本及来源，按钮可重试并显示结果', (tester) async {
    final repo = _UpdateRepository();
    final state = AppState(repository: repo);
    addTearDown(state.dispose);
    await tester.pumpWidget(_screen(state));
    await tester.pumpAndSettle();
    expect(repo.checks, hasLength(1));
    expect(find.text('demo-0.1'), findsOneWidget);
    expect(find.text('来源：应用内置'), findsOneWidget);
    expect(find.textContaining('正在检查更新'), findsOneWidget);
    repo.checks.single.completeError(
      const ContentUpdateException('下载的 SHA-256 校验未通过'),
    );
    await tester.pumpAndSettle();
    expect(find.text('demo-0.1'), findsOneWidget);
    expect(find.textContaining('继续使用当前内容'), findsOneWidget);
    expect(find.textContaining('SHA-256 校验未通过'), findsOneWidget);
    await tester.tap(find.text('检查更新'));
    await tester.pumpAndSettle();
    expect(repo.checks, hasLength(2));
    repo.checks.last.complete(null);
    await tester.pumpAndSettle();
    expect(find.textContaining('已是最新版本'), findsOneWidget);
    expect(find.textContaining('SHA-256 校验未通过'), findsNothing);
  });
}
