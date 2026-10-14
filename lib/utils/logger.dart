import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

File? _logFile;
bool _logDisabled = false;

void _writeToLogFile(String text) {
  if (_logDisabled || kIsWeb) return;
  try {
    _logFile ??= File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}mlastro_app.log',
    );
    _logFile!.writeAsStringSync(
      '${DateTime.now().toIso8601String()} [skymap] $text\n',
      mode: FileMode.append,
      flush: true,
    );
  } catch (_) {
    _logDisabled = true;
  }
}

class _SkyMapLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => kDebugMode || event.level >= Level.info;
}

class _SkyMapLogOutput extends LogOutput {
  static final _ansi = RegExp(r'\x1B\[[0-9;]*m');

  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      _writeToLogFile(line.replaceAll(_ansi, ''));
    }
    final stack = event.origin.stackTrace;
    if (stack != null && event.level >= Level.warning) {
      _writeToLogFile(stack.toString());
    }
  }
}

final Logger xLog = Logger(
  filter: _SkyMapLogFilter(),
  printer: SimplePrinter(colors: true),
  output: MultiOutput([ConsoleOutput(), _SkyMapLogOutput()]),
);
