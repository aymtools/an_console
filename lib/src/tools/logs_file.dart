import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:an_console/src/console.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

import 'events.dart';

String _logFiles = '';

/// 转储文件的日期格式
final fileLogDateFormat = DateFormat('MM-dd_HH_mm_ss_S');

extension AnConsoleLogFileSaver on AnConsole {
  /// 设置默认的日志文件存储目录
  set logFilesBasePath(String logFiles) {
    _logFiles = logFiles;
  }

  String get logFilesBasePath => _logFiles;

  /// 将指定类型的的日志内容写入到日志文件
  Future<String> saveLogToFile(String logType,
      {String? content,
      String? fileNamePrefix,
      Future<void> Function(LogWriter writer)? customWrite}) async {
    assert(_logFiles.isNotEmpty, 'logFilesBasePath must init');
    if (_logFiles.isEmpty) {
      return '';
    }

    var logPath =
        '$_logFiles/$logType/${fileNamePrefix == null ? '' : '$fileNamePrefix-'}${fileLogDateFormat.format(DateTime.now())}.txt';
    logPath = join(_logFiles, logType);
    if (fileNamePrefix?.isNotEmpty == true) {
      logPath = join(logPath,
          '$fileNamePrefix-${fileLogDateFormat.format(DateTime.now())}.txt');
    } else {
      logPath =
          join(logPath, '${fileLogDateFormat.format(DateTime.now())}.txt');
    }
    File file = File(logPath);

    if (!(await file.exists())) {
      await file.create(recursive: true);
    }
    final writer = await file.open(mode: FileMode.write);
    if (content != null) {
      await writer.writeString(content);
      await writer.flush();
    }
    if (customWrite != null) {
      _LogWriter w = _LogWriter(writer);
      await customWrite(w);
      w.flush();
      await w._future;
    }
    await writer.close();
    return logPath;
  }
}

// 日志 Writer
abstract class LogWriter {
  void writeByte(int value);

  void writeBytes(List<int> buffer, [int start = 0, int? end]);

  void writeString(String string, {Encoding encoding = utf8});

  void flush();
}

class _LogWriter extends LogWriter {
  final RandomAccessFile writer;

  _LogWriter(this.writer);

  Future _future = SynchronousFuture('');

  @override
  void flush() {
    _future = _future.then((_) => writer.flush());
  }

  @override
  void writeByte(int value) {
    _future = _future.then((_) => writer.writeByte(value));
  }

  @override
  void writeBytes(List<int> buffer, [int start = 0, int? end]) {
    _future = _future.then((_) => writer.writeFrom(buffer, start, end));
  }

  @override
  void writeString(String string, {Encoding encoding = utf8}) {
    _future = _future.then((_) => writer.writeString(string, encoding: utf8));
  }
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
