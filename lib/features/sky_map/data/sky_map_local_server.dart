import 'dart:async';
import 'dart:io';

import 'package:mlastro_skymap/utils/logger.dart';
import 'package:path/path.dart' as p;

/// Serves sky-map files over loopback HTTP so WebView can load WASM and catalogs.
class SkyMapLocalServer {
  HttpServer? _server;

  Future<String> start(String rootPath) async {
    await stop();
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw StateError('Sky map root not found: $rootPath');
    }

    final resolvedRoot = root.absolute.path;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = _server!.port;
    final url = 'http://127.0.0.1:$port/';
    xLog.d('SkyMap: HTTP server listening on $url');

    unawaited(_server!.forEach((request) => _handle(request, resolvedRoot)));

    return url;
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
  }

  Future<void> _handle(HttpRequest request, String rootPath) async {
    try {
      var path = Uri.decodeComponent(request.uri.path);
      if (path == '/' || path.isEmpty) {
        path = '/index.html';
      }
      if (path.startsWith('/')) path = path.substring(1);

      final file = File(p.join(rootPath, path));
      final canonicalRoot = p.normalize(p.absolute(rootPath));
      final canonicalFile = p.normalize(p.absolute(file.path));
      if (!canonicalFile.startsWith('$canonicalRoot${p.separator}')) {
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
        return;
      }

      if (!await file.exists()) {
        xLog.w('SkyMap: HTTP 404 $path');
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final bytes = await file.readAsBytes();
      request.response.headers.contentType = _contentTypeFor(file.path);
      request.response.contentLength = bytes.length;
      request.response.add(bytes);
      await request.response.close();
    } catch (e, st) {
      xLog.e('SkyMap: HTTP handler failed for ${request.uri.path}: $e\n$st');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }

  ContentType _contentTypeFor(String path) {
    if (path.endsWith('.html')) return ContentType.html;
    if (path.endsWith('.js')) return ContentType('application', 'javascript');
    if (path.endsWith('.wasm')) {
      return ContentType('application', 'wasm');
    }
    if (path.endsWith('.json')) return ContentType.json;
    if (path.endsWith('.webp')) return ContentType('image', 'webp');
    if (path.endsWith('.png')) return ContentType('image', 'png');
    if (path.endsWith('.css')) return ContentType('text', 'css');
    if (path.endsWith('properties') || path.endsWith('.txt')) {
      return ContentType('text', 'plain', charset: 'utf-8');
    }
    return ContentType.binary;
  }
}
