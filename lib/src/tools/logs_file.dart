import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:an_console/src/console.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'events.dart';

String _logFiles = '';
final fileLogDateFormat = DateFormat('MM-dd_HH_mm_ss_S');

extension AnConsoleLogFileSaver on AnConsole {
  set logFilesBasePath(String logFiles) {
    _logFiles = logFiles;
  }

  Future<bool> saveLogToFile(String logType,
      {String? content,
      Future<void> Function(LogWriter writer)? customWrite}) async {
    assert(_logFiles.isNotEmpty, 'logFilesBasePath must init');
    if (_logFiles.isEmpty) {
      return false;
    }

    final logPath =
        '$_logFiles/$logType/${fileLogDateFormat.format(DateTime.now())}.txt';
    File file = File(logPath);

    Future<void> makeParentDir(Directory parent) async {
      if (!await parent.parent.exists()) {
        await makeParentDir(parent.parent);
      }
      await parent.create();
    }

    if (!await file.parent.exists()) {
      await makeParentDir(file.parent);
    }
    if (!(await file.exists())) {
      await file.create();
    }
    final writer = await file.open(mode: FileMode.write);
    if (content != null) {
      await writer.writeString(content);
      writer.flush();
    }
    if (customWrite != null) {
      LogWriter w = _LogWriter(writer);
      await customWrite(w);
      await w.flush();
    }
    await writer.close();
    return true;
  }
}

abstract class LogWriter {
  void writeByte(int value);

  void writeBytes(List<int> buffer, [int start = 0, int? end]);

  void writeString(String string, {Encoding encoding = utf8});

  Future<void> flush();
}

class _LogWriter extends LogWriter {
  final RandomAccessFile writer;

  _LogWriter(this.writer);

  Future _future = SynchronousFuture('');

  @override
  Future<void> flush() {
    return _future = _future.then((_) => writer.flush());
  }

  @override
  void writeByte(int value) async {
    _future = _future.then((_) => writer.writeByte(value));
  }

  @override
  void writeBytes(List<int> buffer, [int start = 0, int? end]) async {
    _future = _future.then((_) => writer.writeFrom(buffer, start, end));
  }

  @override
  void writeString(String string, {Encoding encoding = utf8}) async {
    _future = _future.then((_) => writer.writeString(string, encoding: utf8));
  }
}

extension EventManagerSaveToFileExt<T> on EventManager<T> {
  void saveEventsToFile(
      {String? logFile, FutureOr<String> Function(T event)? convert}) {
    final events = buffers;
    convert ??= (log) => log.toString();
    AnConsole.instance.saveLogToFile(
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
