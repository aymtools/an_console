import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:an_console/src/console.dart';
import 'package:an_console/src/tools/logs_file.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

/// 转储文件的日期格式
final _fileLogDateFormat = DateFormat('MM-dd_HH_mm_ss_S');

extension AnConsoleLogFileSaver on AnConsole {
  /// 将指定类型的的日志内容写入到日志文件
  Future<String> saveLogToFile(String logType,
      {String? content,
      String? fileNamePrefix,
      Future<void> Function(LogWriter writer)? customWrite}) async {
    final logFiles = logFilesBasePath;
    assert(logFiles.isNotEmpty, 'logFilesBasePath must init');
    if (logFiles.isEmpty) {
      return '';
    }

    var logPath =
        '$logFiles/$logType/${fileNamePrefix == null ? '' : '$fileNamePrefix-'}${_fileLogDateFormat.format(DateTime.now())}.txt';
    logPath = join(logFiles, logType);
    if (fileNamePrefix?.isNotEmpty == true) {
      logPath = join(logPath,
          '$fileNamePrefix-${_fileLogDateFormat.format(DateTime.now())}.txt');
    } else {
      logPath =
          join(logPath, '${_fileLogDateFormat.format(DateTime.now())}.txt');
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
