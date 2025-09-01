import 'dart:async';
import 'dart:convert';

import 'package:an_console/src/console.dart';
import 'package:an_console/src/tools/logs_file.dart';

extension AnConsoleLogFileSaver on AnConsole {
  /// 将指定类型的的日志内容写入到日志文件
  Future<String> saveLogToFile(String logType,
      {String? content,
      String? fileNamePrefix,
      Future<void> Function(LogWriter writer)? customWrite}) async {
    return '';
  }
}

// WebLogWriter 实现：处理 Web 中的文件操作
class WebLogWriter implements LogWriter {
  final List<int> _buffer = []; // 使用 List<int> 存储所有写入的字节

  @override
  void writeByte(int value) {
    _buffer.add(value); // 将字节值添加到缓冲区
  }

  @override
  void writeBytes(List<int> buffer, [int start = 0, int? end]) {
    end ??= buffer.length;
    _buffer.addAll(buffer.sublist(start, end)); // 添加字节数组的一部分到缓冲区
  }

  @override
  void writeString(String string, {Encoding encoding = utf8}) {
    List<int> encodedBytes = encoding.encode(string); // 使用编码将字符串转换为字节
    _buffer.addAll(encodedBytes); // 将字节添加到缓冲区
  }

  @override
  void flush() {
    // // 将缓冲区内容保存到文件
    // final blob = Blob([Uint8List.fromList(_buffer)]); // 将缓冲区的字节数据转为 Blob
    // final url = html.Url.createObjectUrlFromBlob(blob);
    //
    // // 创建下载链接
    // final anchor = html.AnchorElement(href: url)
    //   ..target = 'blank'
    //   ..download = 'log.dat'; // 默认文件名是 log.dat
    //
    // // 模拟点击下载文件
    // anchor.click();
    //
    // // 清理 URL
    // html.Url.revokeObjectUrl(url);
    //
    // // 清空缓冲区
    // _buffer.clear();
  }
}
