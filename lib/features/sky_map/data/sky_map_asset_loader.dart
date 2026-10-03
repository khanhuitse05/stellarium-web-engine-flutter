import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:mlastro_skymap/sky_map_assets.dart';
import 'package:mlastro_skymap/utils/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies bundled sky-map assets to app support storage and extracts catalog data.
class SkyMapAssetLoader {
  SkyMapAssetLoader._();

  static const _assetPrefix = SkyMapAssets.prefix;
  static const _versionFile = '.installed_version';
  static const _version = '22';

  static const _bundledAssets = SkyMapAssets.bundled;

  static Future<String> ensureInstalled() async {
    try {
      final support = await getApplicationSupportDirectory();
      final root = Directory('${support.path}/sky_map');
      final marker = File('${root.path}/$_versionFile');
      final index = File('${root.path}/index.html');

      if (await marker.exists() && await index.exists()) {
        final v = await _readVersion(marker);
        if (v == _version && await _skyDataReady(root)) {
          xLog.d('SkyMap: using installed assets at ${root.path}');
          return root.path;
        }
        xLog.w(
          'SkyMap: reinstall needed (version=$v expected=$_version, '
          'skyDataReady=${await _skyDataReady(root)})',
        );
      }

      await _install(root);
      xLog.d('SkyMap: install complete at ${root.path}');
      return root.path;
    } catch (e, st) {
      xLog.e('SkyMap: ensureInstalled failed: $e\n$st');
      rethrow;
    }
  }

  static Future<String?> _readVersion(File marker) async {
    try {
      final bytes = await marker.readAsBytes();
      return String.fromCharCodes(
        bytes.where((b) => b >= 0x20 && b <= 0x7e),
      ).trim();
    } catch (e, st) {
      xLog.e('SkyMap: corrupt version marker at ${marker.path}: $e\n$st');
      return null;
    }
  }

  static Future<bool> _skyDataReady(Directory root) async {
    return File('${root.path}/stellarium/skydata/stars/properties').exists();
  }

  static Future<void> _install(Directory root) async {
    xLog.d('SkyMap: installing to ${root.path}');
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
    await root.create(recursive: true);

    for (final key in _bundledAssets) {
      final relative = key.substring(_assetPrefix.length);
      final out = File('${root.path}/$relative');
      await Directory(out.parent.path).create(recursive: true);
      try {
        final data = await rootBundle.load(key);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await out.writeAsBytes(bytes, flush: true);
        xLog.d('SkyMap: copied $key (${bytes.length} bytes)');
      } catch (e, st) {
        xLog.e('SkyMap: failed copying $key: $e\n$st');
        rethrow;
      }
    }

    await _extractSkyData(root);
    await File('${root.path}/$_versionFile').writeAsString(_version);
  }

  static Future<void> _extractSkyData(Directory root) async {
    final archiveFile = File('${root.path}/stellarium/skydata.tar.gz');
    final skyDataDir = Directory('${root.path}/stellarium/skydata');
    if (!await archiveFile.exists()) {
      throw StateError(
        'Missing ${archiveFile.path}. Run scripts/setup_stellarium_web_engine.sh',
      );
    }

    if (await skyDataDir.exists()) {
      await skyDataDir.delete(recursive: true);
    }
    await skyDataDir.create(recursive: true);

    final bytes = await archiveFile.readAsBytes();
    xLog.d(
      'SkyMap: skydata.tar.gz ${bytes.length} bytes, '
      'magic=${_hexPreview(bytes, 4)}',
    );

    if (bytes.length < 2 || bytes[0] != 0x1f || bytes[1] != 0x8b) {
      xLog.e(
        'SkyMap: invalid gzip header in ${archiveFile.path}, '
        'first bytes=${_hexPreview(bytes, 32)}',
      );
      throw StateError(
        'skydata.tar.gz is not valid gzip (${bytes.length} bytes)',
      );
    }

    List<int> tarBytes;
    try {
      tarBytes = GZipDecoder().decodeBytes(bytes);
      xLog.d('SkyMap: decompressed tar ${tarBytes.length} bytes');
    } catch (e, st) {
      xLog.e('SkyMap: gzip decode failed: $e\n$st');
      rethrow;
    }

    try {
      await _extractTarToDisk(tarBytes, skyDataDir);
      final props = File('${skyDataDir.path}/stars/properties');
      if (!await props.exists()) {
        throw StateError(
          'skydata extract finished but stars/properties is missing',
        );
      }
      xLog.d('SkyMap: skydata extracted to ${skyDataDir.path}');
    } catch (e, st) {
      xLog.e('SkyMap: tar extract failed: $e\n$st');
      rethrow;
    }
  }

  /// Extracts ustar tar bytes, skipping macOS metadata the archive package chokes on.
  static Future<void> _extractTarToDisk(
    List<int> tarBytes,
    Directory outputDir,
  ) async {
    var offset = 0;
    String? nextName;
    var filesWritten = 0;

    while (offset + 512 <= tarBytes.length) {
      final header = Uint8List.fromList(tarBytes.sublist(offset, offset + 512));
      offset += 512;

      if (header.every((b) => b == 0)) {
        break;
      }

      var name = _tarEntryName(header);
      final typeFlag = header[156];
      final size = _tarEntrySize(header);

      // GNU long name/link records.
      if (name == '././@LongLink' || typeFlag == 0x4c) {
        nextName = _readTarPayload(tarBytes, offset, size);
        offset += _tarPaddedSize(size);
        continue;
      }
      if (typeFlag == 0x4b) {
        offset += _tarPaddedSize(size);
        continue;
      }

      // PAX extended headers contain binary xattr data on macOS tar archives.
      if (typeFlag == 0x78 || typeFlag == 0x58 || typeFlag == 0x67) {
        xLog.d('SkyMap: skipping tar metadata $name');
        offset += _tarPaddedSize(size);
        continue;
      }

      if (nextName != null) {
        name = nextName;
        nextName = null;
      }

      if (_shouldSkipTarEntry(name)) {
        xLog.d('SkyMap: skipping tar entry $name');
        offset += _tarPaddedSize(size);
        continue;
      }

      final relative = _normalizeTarPath(name);
      if (relative.isEmpty || relative == '.') {
        offset += _tarPaddedSize(size);
        continue;
      }

      final outPath = p.join(outputDir.path, relative);
      final isDir = typeFlag == 0x35 || relative.endsWith('/');

      if (isDir) {
        await Directory(outPath).create(recursive: true);
      } else if (typeFlag == 0x30 || typeFlag == 0 || typeFlag == 0x20) {
        await Directory(p.dirname(outPath)).create(recursive: true);
        await File(outPath).writeAsBytes(
          tarBytes.sublist(offset, offset + size),
          flush: true,
        );
        filesWritten++;
      } else {
        xLog.d(
          'SkyMap: skipping tar type ${String.fromCharCode(typeFlag)} '
          'for $name',
        );
      }

      offset += _tarPaddedSize(size);
    }

    xLog.d('SkyMap: tar extract wrote $filesWritten files');
  }

  static String _readTarPayload(List<int> tarBytes, int offset, int size) {
    return String.fromCharCodes(tarBytes.sublist(offset, offset + size))
        .replaceAll('\x00', '')
        .trim();
  }

  static int _tarPaddedSize(int size) => ((size + 511) ~/ 512) * 512;

  static String _tarEntryName(Uint8List header) {
    final name = _tarField(header, 0, 100);
    final prefix = _tarField(header, 345, 155);
    if (prefix.isEmpty) return name;
    return '$prefix/$name';
  }

  static int _tarEntrySize(Uint8List header) => _parseOctal(_tarField(header, 124, 12));

  static String _tarField(Uint8List header, int offset, int length) {
    final end = offset + length;
    var i = offset;
    while (i < end && header[i] != 0) {
      i++;
    }
    return String.fromCharCodes(header.sublist(offset, i)).trim();
  }

  static int _parseOctal(String value) {
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return 0;
    return int.parse(digits, radix: 8);
  }

  static bool _shouldSkipTarEntry(String name) {
    if (name.contains('__MACOSX') || name.contains('PaxHeader')) {
      return true;
    }
    for (final part in name.split('/')) {
      if (part.startsWith('._')) return true;
    }
    return false;
  }

  static String _normalizeTarPath(String name) {
    var path = name;
    while (path.startsWith('./')) {
      path = path.substring(2);
    }
    return path.replaceAll('\\', '/');
  }

  static String _hexPreview(Uint8List bytes, int max) {
    if (bytes.isEmpty) return '(empty)';
    final n = bytes.length < max ? bytes.length : max;
    return bytes.sublist(0, n).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }
}
