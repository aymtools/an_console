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
