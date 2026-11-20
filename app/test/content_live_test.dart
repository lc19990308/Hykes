import 'dart:io';

import 'package:app/core/data/content_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _base = String.fromEnvironment('HAIDOU_API_BASE_URL');

void main() {
  test('Spring Boot live: latest → 下载真实 demo → 无网络读取缓存', () async {
    final cache = await Directory.systemTemp.createTemp('haidou-content-live-');
    addTearDown(() => cache.delete(recursive: true));
    final repo = ContentRepository(
      apiBaseUrl: _base,
      cacheDirectory: () async => cache,
    );
    // The installed app matches the current server version and would skip the
    // download. Model an older client here to exercise the full live path.
    final updated = await repo.checkForUpdate('demo-0.0');
    expect(updated?.source, ContentSource.downloaded);
    final bundle = updated!.bundle;
    expect(bundle.dataset.datasetVersion, 'demo-0.1');
    expect(bundle.dataset.dataMode, 'simulated');
    expect(bundle.champions, hasLength(8));
    expect(await repo.checkForUpdate(bundle.dataset.datasetVersion), isNull);
    final offline = ContentRepository(cacheDirectory: () async => cache);
    final restored = await offline.loadLocal();
    expect(restored.source, ContentSource.cache);
    expect(restored.bundle.dataset.datasetVersion, 'demo-0.1');
  }, skip: _base.trim().isEmpty ? '提供 HAIDOU_API_BASE_URL 启用 live 测试' : false);
}
