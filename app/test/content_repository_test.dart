import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/core/data/content_api.dart' show contentChecksum;
import 'package:app/core/data/content_repository.dart';
import 'package:app/core/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

const _latest = '/api/v1/datasets/latest';
const _timestamp = '2026-11-20T00:00:00Z';
const _originalVersion = 'demo-0.1';
const _newVersion = 'demo-0.2';
const _nextVersion = 'demo-0.3';
String _download(String version) => '/api/v1/datasets/$version/download';

Map<String, Object?> _envelope(Object? data, {int code = 0}) => {
  'code': code,
  'message': 'fixture message is not used for branching',
  'data': data,
  'timestamp': _timestamp,
};

Map<String, Object?> _metadata(String version, List<int> bytes) => {
  'datasetVersion': version,
  'schemaVersion': 1,
  'minClientSchemaVersion': 1,
  'dataMode': 'simulated',
  'mode': 'demo',
  'contentChecksum': contentChecksum(bytes),
  'fileSizeBytes': bytes.length,
  'downloadUrl': _download(version),
};

List<int> _bundleFor(
  String original,
  String version, {
  int schema = 1,
  String mode = 'demo',
}) => utf8.encode(
  original
      .replaceFirst('"schemaVersion": 1', '"schemaVersion": $schema')
      .replaceFirst('"mode": "demo"', '"mode": "$mode"')
      .replaceFirst(
        '"datasetVersion": "$_originalVersion"',
        '"datasetVersion": "$version"',
      ),
);

void main() {
  late String original;
  late Directory cache;
  late HttpServer server;
  late List<String> requests;
  late List<int> downloadBytes;
  late Map<String, Object?> metadata;
  late ({int status, int code}) latestResult;
  late ({int status, int code}) downloadResult;
  late Completer<void>? waitForLatest;
  late Completer<void> latestStarted;

  setUp(() async {
    original = await File('assets/data/demo-0.1.json').readAsString();
    cache = await Directory.systemTemp.createTemp('haidou-content-test-');
    addTearDown(() => cache.delete(recursive: true));
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    requests = [];
    downloadBytes = _bundleFor(original, _newVersion);
    metadata = _metadata(_newVersion, downloadBytes);
    latestResult = (status: HttpStatus.ok, code: 0);
    downloadResult = (status: HttpStatus.ok, code: 0);
    waitForLatest = null;
    latestStarted = Completer<void>();
    server.listen((request) async {
      requests.add(request.uri.path);
      final response = request.response..headers.contentType = ContentType.json;
      if (request.uri.path == _latest) {
        if (!latestStarted.isCompleted) latestStarted.complete();
        await waitForLatest?.future;
        response.statusCode = latestResult.status;
        response.write(
          jsonEncode(
            _envelope(
              latestResult.code == 0 ? metadata : null,
              code: latestResult.code,
            ),
          ),
        );
      } else {
        response.statusCode = downloadResult.status;
        if (downloadResult.status == HttpStatus.ok) {
          response.add(downloadBytes);
        } else if (downloadResult.status == HttpStatus.found) {
          response.headers.set(HttpHeaders.locationHeader, '/redirect-target');
        } else if (downloadResult.status != HttpStatus.notModified) {
          response.write(
            jsonEncode(_envelope(null, code: downloadResult.code)),
          );
        }
      }
      await response.close();
    });
  });

  ContentRepository repository({
    String? base,
    Future<Directory> Function()? storage,
  }) => ContentRepository(
    loader: () async => original,
    apiBaseUrl: base ?? 'http://127.0.0.1:${server.port}',
    cacheDirectory: storage ?? () async => cache,
  );

  test('未配置 URL 的首次启动使用内置真实字节、不检查网络', () async {
    final repo = repository(base: '');
    final state = AppState(repository: repo);
    addTearDown(state.dispose);
    await state.loadBundle();
    await state.checkForUpdate();
    expect(state.phase, LoadPhase.ready);
    expect(state.updatePhase, ContentUpdatePhase.offline);
    expect(state.contentSource, ContentSource.bundled);
    expect(state.bundle!.dataset.datasetVersion, _originalVersion);
    expect(state.bundle!.champions, hasLength(8));
    expect(requests, isEmpty);
  });

  test('启动先展示本地数据，并发手动检查复用请求，下载后可离线读取原样缓存', () async {
    waitForLatest = Completer<void>();
    addTearDown(() {
      if (!waitForLatest!.isCompleted) waitForLatest!.complete();
    });
    final repo = repository(base: 'http://127.0.0.1:${server.port}/api/v1/');
    final state = AppState(repository: repo);
    addTearDown(state.dispose);
    await state.loadBundle();
    await latestStarted.future.timeout(const Duration(seconds: 6));
    expect(state.phase, LoadPhase.ready);
    expect(state.updatePhase, ContentUpdatePhase.checking);
    expect(state.bundle!.dataset.datasetVersion, _originalVersion);
    expect(state.contentSource, ContentSource.bundled);
    final first = state.checkForUpdate();
    expect(state.checkForUpdate(), same(first));
    waitForLatest!.complete();
    await first;
    expect(requests, [_latest, _download(_newVersion)]);
    expect(state.phase, LoadPhase.ready);
    expect(state.updatePhase, ContentUpdatePhase.updated);
    expect(state.contentSource, ContentSource.downloaded);
    expect(state.bundle!.dataset.datasetVersion, _newVersion);

    final saved = File.fromUri(cache.uri.resolve('haidou-content-v1.json'));
    final stored =
        jsonDecode(await saved.readAsString()) as Map<String, Object?>;
    expect(
      base64Decode(stored['bytes'] as String),
      orderedEquals(downloadBytes),
    );
    final restarted = await repository(base: '').loadLocal();
    expect(restarted.source, ContentSource.cache);
    expect(restarted.bundle.dataset.datasetVersion, _newVersion);
    await state.checkForUpdate();
    expect(state.updatePhase, ContentUpdatePhase.upToDate);
    expect(requests, [_latest, _download(_newVersion), _latest]);
  });

  test('在线失败后保留缓存，手动重试成功才替换，随后损坏缓存回退内置', () async {
    final repo = repository();
    await repo.checkForUpdate(_originalVersion);
    final file = File.fromUri(cache.uri.resolve('haidou-content-v1.json'));
    final previous = await file.readAsString();
    downloadBytes = _bundleFor(original, _nextVersion);
    metadata = _metadata(_nextVersion, downloadBytes)
      ..['contentChecksum'] = contentChecksum(utf8.encode('wrong body'));
    final state = AppState(repository: repo);
    addTearDown(state.dispose);
    await state.loadBundle();
    await state.checkForUpdate();
    expect(state.phase, LoadPhase.ready);
    expect(state.updatePhase, ContentUpdatePhase.failed);
    expect(state.updateError, contains('SHA-256'));
    expect(state.contentSource, ContentSource.cache);
    expect(state.bundle!.dataset.datasetVersion, _newVersion);
    expect(await file.readAsString(), previous);

    metadata = _metadata(_nextVersion, downloadBytes);
    await state.checkForUpdate();
    expect(state.updatePhase, ContentUpdatePhase.updated);
    expect(state.bundle!.dataset.datasetVersion, _nextVersion);
    expect(state.updateError, isNull);
    await file.writeAsString('corrupt cache');
    final fallback = await repository(base: '').loadLocal();
    expect(fallback.source, ContentSource.bundled);
    expect(fallback.bundle.dataset.datasetVersion, _originalVersion);
  });

  final errors = <String, (void Function(Map<String, Object?>), String)>{
    'min client schema': ((meta) => meta['minClientSchemaVersion'] = 2, '不兼容'),
    'metadata schema': ((meta) => meta['schemaVersion'] = 2, '不兼容'),
    'snapshot metadata': (
      (meta) => meta['dataMode'] = 'source-snapshot',
      '仅支持模拟',
    ),
    'cross-origin URL': (
      (meta) =>
          meta['downloadUrl'] = 'http://127.0.0.1:1${_download(_newVersion)}',
      '不同源',
    ),
    'different version URL': (
      (meta) => meta['downloadUrl'] = _download(_nextVersion),
      '地址无效',
    ),
  };
  for (final scenario in errors.entries) {
    test('latest 拒绝 ${scenario.key} 且不下载', () async {
      final (change, message) = scenario.value;
      change(metadata);
      await expectLater(
        repository().checkForUpdate(_originalVersion),
        throwsA(
          isA<ContentUpdateException>().having(
            (error) => error.message,
            'message',
            contains(message),
          ),
        ),
      );
      expect(requests, [_latest]);
    });
  }

  final statuses = <({int status, int code, bool onlyLatest, String message})>[
    (status: 200, code: 40401, onlyLatest: true, message: '格式无效'),
    (status: 404, code: 40401, onlyLatest: true, message: '暂无可用'),
    (status: 500, code: 50000, onlyLatest: true, message: '稍后重试'),
    (status: 500, code: 50001, onlyLatest: false, message: '服务端数据包校验'),
    (status: 302, code: 0, onlyLatest: false, message: 'HTTP 302'),
    (status: 304, code: 0, onlyLatest: false, message: 'HTTP 304'),
  ];
  for (final scenario in statuses) {
    test(
      '${scenario.onlyLatest ? 'latest' : 'download'} 拒绝 ${scenario.status}/${scenario.code}',
      () async {
        final result = (status: scenario.status, code: scenario.code);
        if (scenario.onlyLatest) {
          latestResult = result;
        } else {
          downloadResult = result;
        }
        await expectLater(
          repository().checkForUpdate(_originalVersion),
          throwsA(
            isA<ContentUpdateException>().having(
              (error) => error.message,
              'message',
              contains(scenario.message),
            ),
          ),
        );
        expect(requests, [
          _latest,
          if (!scenario.onlyLatest) _download(_newVersion),
        ]);
        expect(await cache.list().toList(), isEmpty);
      },
    );
  }

  const invalidBodies = <(String, int, String, int)>[
    (_newVersion, 1, 'demo', 1),
    (_newVersion, 1, 'demo', -1),
    (_newVersion, 2, 'demo', 0),
    (_newVersion, 1, 'source-snapshot', 0),
    (_nextVersion, 1, 'demo', 0),
  ];
  for (final (version, schema, mode, byteDelta) in invalidBodies) {
    test(
      '下载拒绝异常体：版本 $version，schema $schema，模式 $mode，字节偏差 $byteDelta',
      () async {
        downloadBytes = _bundleFor(
          original,
          version,
          schema: schema,
          mode: mode,
        );
        metadata = _metadata(_newVersion, downloadBytes)
          ..['fileSizeBytes'] = downloadBytes.length + byteDelta;
        await expectLater(
          repository().checkForUpdate(_originalVersion),
          throwsA(isA<ContentUpdateException>()),
        );
        expect(requests, [_latest, _download(_newVersion)]);
        expect(await cache.list().toList(), isEmpty);
      },
    );
  }

  test('无连接时仍保留内置数据，失败可见', () async {
    final repo = repository();
    await server.close(force: true);
    final state = AppState(repository: repo);
    addTearDown(state.dispose);
    await state.loadBundle();
    await state.checkForUpdate();
    expect(state.phase, LoadPhase.ready);
    expect(state.contentSource, ContentSource.bundled);
    expect(state.updatePhase, ContentUpdatePhase.failed);
    expect(state.updateError, contains('网络'));
  });

  test('有效下载无法保存时不启用新内容', () async {
    final state = AppState(
      repository: repository(
        storage: () async {
          throw const FileSystemException('fixture cache unavailable');
        },
      ),
    );
    addTearDown(state.dispose);
    await state.loadBundle();
    await state.checkForUpdate();
    expect(state.updatePhase, ContentUpdatePhase.failed);
    expect(state.updateError, '无法保存更新数据');
    expect(state.bundle!.dataset.datasetVersion, _originalVersion);
  });
}
