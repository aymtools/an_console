import 'dart:async';
import 'dart:convert';

import 'package:an_console/src/console.dart';

import 'events.dart';
import 'logfile/logs_file.dart'
    if (dart.library.html) 'logfile/logs_file_web.dart'
    if (dart.library.io) 'logfile/logs_file_io.dart';

export 'logfile/logs_file.dart'
    if (dart.library.html) 'logfile/logs_file_web.dart'
    if (dart.library.io) 'logfile/logs_file_io.dart';

String _logFiles = '';

extension AnConsoleLogFileSaver on AnConsole {
  /// 设置默认的日志文件存储目录
  set logFilesBasePath(String logFiles) {
    _logFiles = logFiles;
  }

  String get logFilesBasePath => _logFiles;
}

// 日志 Writer
abstract class LogWriter {
  void writeByte(int value);

  void writeBytes(List<int> buffer, [int start = 0, int? end]);

  void writeString(String string, {Encoding encoding = utf8});

  void flush();
}

extension EventManagerSaveToFileExt<T> on EventManager<T> {
  /// 将当前管理的信息保存到文件
  Future<String> saveEventsToFile(
      {String? logFile, FutureOr<String> Function(T event)? convert}) {
    final events = buffers;
    convert ??= (log) => log.toString();
    return AnConsole.instance.saveLogToFile(
      logFile ?? T.toString(),
      customWrite: (writer) async {
        for (var log in events) {
          final lx = await convert!(log);
          if (lx.isEmpty) continue;
          writer.writeString(lx);
          writer.writeString('\n\n');
        }
      },
    );
  }
}
