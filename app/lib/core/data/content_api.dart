import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'content_bundle.dart';

const _apiPath = '/api/v1';
const _schemaVersion = 1;
const _demoMode = 'demo';
const _simulatedMode = 'simulated';
// v1.0 only carries demo JSON, not multi-megabyte snapshot packages.
const maxDemoBytes = 8 * 1024 * 1024;
final _versionPattern = RegExp(r'^[a-z0-9]+-[0-9]+\.[0-9]+$');
final _checksumPattern = RegExp(r'^sha256:[0-9a-f]{64}$');

class ContentUpdateException implements Exception {
  const ContentUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ContentApi {
  ContentApi(this.baseUrl);

  final String baseUrl;

  Future<({ContentBundle bundle, Uint8List bytes, String checksum})?>
  downloadLatest(String currentVersion) async {
    final base = _parseBase();
    final latest = await _get(
      base.resolve('datasets/latest'),
      timeout: const Duration(seconds: 5),
      maxBytes: 64 * 1024,
    );
    final envelope = _parseObject(latest.bytes);
    if (latest.status != HttpStatus.ok ||
        envelope?['code'] is! int ||
        envelope?['code'] != 0) {
      throw _responseError(latest.status, envelope?['code']);
    }
    final data = envelope?['data'];
    if (data is! Map<String, Object?>) {
      throw const ContentUpdateException('更新元信息格式无效');
    }

    final schema = data['schemaVersion'];
    final minSchema = data['minClientSchemaVersion'];
    if (schema is! int ||
        schema != _schemaVersion ||
        minSchema is! int ||
        minSchema < 1 ||
        minSchema > _schemaVersion) {
      throw const ContentUpdateException('数据格式与当前应用版本不兼容');
    }
    if (data['mode'] != _demoMode || data['dataMode'] != _simulatedMode) {
      throw const ContentUpdateException('当前应用仅支持模拟数据包');
    }
    final version = data['datasetVersion'];
    final checksum = data['contentChecksum'];
    final size = data['fileSizeBytes'];
    final url = data['downloadUrl'];
    if (version is! String ||
        !_versionPattern.hasMatch(version) ||
        checksum is! String ||
        !_checksumPattern.hasMatch(checksum) ||
        size is! int ||
        size <= 0 ||
        size > maxDemoBytes ||
        url is! String) {
      throw const ContentUpdateException('更新元信息格式无效');
    }
    final download = _downloadUri(base, version, url);
    if (version == currentVersion) return null;

    final response = await _get(
      download,
      timeout: const Duration(seconds: 30),
      maxBytes: size,
    );
    if (response.status != HttpStatus.ok) {
      throw _responseError(
        response.status,
        _parseObject(response.bytes)?['code'],
      );
    }
    if (response.bytes.length != size) {
      throw const ContentUpdateException('下载的字节数与发布信息不一致');
    }
    if (contentChecksum(response.bytes) != checksum) {
      throw const ContentUpdateException('下载的 SHA-256 校验未通过');
    }
    final bundle = parseDemoBundle(response.bytes);
    if (bundle.dataset.datasetVersion != version) {
      throw const ContentUpdateException('数据包版本与发布信息不一致');
    }
    return (bundle: bundle, bytes: response.bytes, checksum: checksum);
  }

  Uri _parseBase() {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null ||
        !_isHttp(uri) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const ContentUpdateException('更新服务地址无效');
    }
    if (Platform.isAndroid && !kDebugMode && uri.scheme != 'https') {
      throw const ContentUpdateException('此版本仅支持通过 HTTPS 更新');
    }
    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (path.isNotEmpty && path != _apiPath) {
      throw const ContentUpdateException('更新服务地址无效');
    }
    return uri.replace(path: '$_apiPath/');
  }

  Uri _downloadUri(Uri base, String version, String reference) {
    final uri = base.resolveUri(Uri.tryParse(reference) ?? Uri());
    if (!_isHttp(uri) ||
        uri.host.isEmpty ||
        uri.origin != base.origin ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.path != '$_apiPath/datasets/$version/download') {
      throw const ContentUpdateException('数据包下载地址无效或与更新服务不同源');
    }
    return uri;
  }

  Future<({int status, Uint8List bytes})> _get(
    Uri uri, {
    required Duration timeout,
    required int maxBytes,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await (() async {
        final request = await client.getUrl(uri);
        // A same-origin URL is not permission to follow a redirect.
        request.followRedirects = false;
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close();
        final bytes = BytesBuilder(copy: false);
        final isSuccess = response.statusCode == HttpStatus.ok;
        final limit = isSuccess ? maxBytes : 64 * 1024;
        await for (final chunk in response) {
          if (bytes.length + chunk.length > limit) {
            if (!isSuccess) {
              return (status: response.statusCode, bytes: Uint8List(0));
            }
            throw const ContentUpdateException('响应字节数超出预期');
          }
          bytes.add(chunk);
        }
        return (status: response.statusCode, bytes: bytes.takeBytes());
      })().timeout(timeout);
    } on TimeoutException {
      throw const ContentUpdateException('连接更新服务超时，请重试');
    } on IOException {
      throw const ContentUpdateException('无法读取更新服务响应，请检查网络后重试');
    } finally {
      client.close(force: true);
    }
  }
}

bool _isHttp(Uri uri) => uri.scheme == 'https' || uri.scheme == 'http';

ContentUpdateException _responseError(int status, Object? code) =>
    ContentUpdateException(switch ((status, code)) {
      (400, 40001) => '数据包版本参数无效',
      (404, 40401) => '更新服务暂无可用的数据包',
      (500, 50001) => '服务端数据包校验未通过',
      (500, 50000) => '更新服务异常，请稍后重试',
      (200, _) => '更新元信息响应格式无效',
      _ => '更新服务返回异常状态（HTTP $status）',
    });

Map<String, Object?>? _parseObject(List<int> bytes) {
  try {
    final Object? value = jsonDecode(utf8.decode(bytes));
    return value is Map<String, Object?> ? value : null;
  } on FormatException {
    return null;
  }
}

String contentChecksum(List<int> bytes) => 'sha256:${sha256.convert(bytes)}';

ContentBundle parseDemoBundle(List<int> bytes) {
  final json = _parseObject(bytes);
  final dataset = json?['dataset'];
  if (json == null ||
      json['schemaVersion'] is! int ||
      json['schemaVersion'] != _schemaVersion ||
      dataset is! Map<String, Object?> ||
      dataset['mode'] != _demoMode) {
    throw const ContentUpdateException('数据包格式或模拟模式无效');
  }
  final version = dataset['datasetVersion'];
  if (version is! String ||
      !_versionPattern.hasMatch(version) ||
      json['contentPolicy'] is! Map<String, Object?>) {
    throw const ContentUpdateException('数据包格式或版本无效');
  }

  // ContentBundle's bundled parser is lenient; don't publish a partial package.
  for (final key in [
    'champions',
    'augments',
    'items',
    'summonerSpells',
    'championAugments',
    'builds',
    'sources',
  ]) {
    final entries = json[key];
    final requiredEntities =
        key == 'champions' || key == 'augments' || key == 'items';
    if (entries is! List<Object?> || (requiredEntities && entries.isEmpty)) {
      throw const ContentUpdateException('数据包内容不完整');
    }
    for (final entry in entries) {
      if (entry is! Map<String, Object?> ||
          (requiredEntities &&
              (entry['id'] is! String ||
                  entry['id'] == '' ||
                  entry['name'] is! String ||
                  entry['name'] == ''))) {
        throw const ContentUpdateException('数据包条目格式无效');
      }
      final stats = entry['stats'];
      if (stats != null &&
          (stats is! Map<String, Object?> || stats['isSimulated'] != true)) {
        throw const ContentUpdateException('数据包包含非模拟统计');
      }
    }
  }
  return ContentBundle.fromJson(json);
}
