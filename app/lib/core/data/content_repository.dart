import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import 'content_api.dart';
import 'content_bundle.dart';

export 'content_api.dart' show ContentUpdateException;

enum ContentSource { bundled, cache, downloaded }

typedef LoadedContent = ({ContentBundle bundle, ContentSource source});

/// Local content is always loaded independently from the optional update API.
class ContentRepository {
  ContentRepository({
    this.assetPath = 'assets/data/demo-0.1.json',
    this.loader,
    String apiBaseUrl = '',
    this.cacheDirectory,
  }) : _api = apiBaseUrl.trim().isEmpty ? null : ContentApi(apiBaseUrl.trim());

  final String assetPath;
  final Future<String> Function()? loader;
  final Future<Directory> Function()? cacheDirectory;
  final ContentApi? _api;

  bool get updatesEnabled => _api != null;

  /// Existing callers can read just the data without the provenance.
  Future<ContentBundle> load() async => (await loadLocal()).bundle;

  Future<LoadedContent> loadLocal() async {
    final cached = await _readCache();
    if (cached != null) return (bundle: cached, source: ContentSource.cache);

    final custom = loader;
    final ContentBundle bundle;
    if (custom != null) {
      bundle = ContentBundle.parse(await custom());
    } else {
      final data = await rootBundle.load(assetPath);
      bundle = parseDemoBundle(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }
    return (bundle: bundle, source: ContentSource.bundled);
  }

  /// Only return the replacement once its original verified bytes are saved.
  Future<LoadedContent?> checkForUpdate(String currentVersion) async {
    final update = await _api?.downloadLatest(currentVersion);
    if (update == null) return null;
    try {
      final file = await _cacheFile();
      if (file == null) throw StateError('No content cache configured');
      await file.parent.create(recursive: true);
      final staging = await file.parent.createTemp('.haidou-content-');
      try {
        final pending = File.fromUri(staging.uri.resolve('pending.json'));
        // One entry keeps bytes and checksum together across an atomic rename.
        await pending.writeAsString(
          jsonEncode({
            'checksum': update.checksum,
            'size': update.bytes.length,
            'bytes': base64Encode(update.bytes),
          }),
          flush: true,
        );
        await pending.rename(file.path);
      } finally {
        try {
          await staging.delete(recursive: true);
        } on FileSystemException {
          // Cleanup cannot turn a successfully committed update into a failure.
        }
      }
    } catch (_) {
      throw const ContentUpdateException('无法保存更新数据');
    }
    return (bundle: update.bundle, source: ContentSource.downloaded);
  }

  Future<ContentBundle?> _readCache() async {
    try {
      final file = await _cacheFile();
      if (file == null || !await file.exists()) return null;
      if (await file.length() > maxDemoBytes * 2) return null;
      final Object? json = jsonDecode(await file.readAsString());
      if (json is! Map<String, Object?>) return null;
      final encoded = json['bytes'];
      final size = json['size'];
      if (encoded is! String ||
          size is! int ||
          size < 1 ||
          size > maxDemoBytes) {
        return null;
      }
      final bytes = base64Decode(encoded);
      if (bytes.length != size || contentChecksum(bytes) != json['checksum']) {
        return null;
      }
      return parseDemoBundle(bytes);
    } catch (_) {
      // Missing or damaged cache is not a reason to hide the bundled data.
      return null;
    }
  }

  Future<File?> _cacheFile() async {
    final directory = await cacheDirectory?.call();
    return directory == null
        ? null
        : File.fromUri(directory.uri.resolve('haidou-content-v1.json'));
  }
}
