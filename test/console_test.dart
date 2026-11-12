import 'package:an_console/an_console.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnConsole Core Unit Tests', () {
    // 测试 AnConsole 全局单例模式
    test('AnConsole.instance returns singleton instance', () {
      final instance1 = AnConsole.instance;
      final instance2 = AnConsole.instance;
      expect(instance1, equals(instance2));
    });

    // 测试 isEnable 属性及 floatingMode 模式设置
    test('floatingMode updates isEnable state correctly', () {
      final console = AnConsole.instance;

      // 强制启用模式 (floatingMode = 1)
      console.floatingMode = 1;
      expect(console.isEnable, isTrue);

      // 强制禁用模式 (floatingMode = 2)
      console.floatingMode = 2;
      expect(console.isEnable, isFalse);

      // 恢复为模式 1 以备后续测试
      console.floatingMode = 1;
      expect(console.isEnable, isTrue);
    });

    // 测试 addConsole 添加自定义控制台页面
    test('addConsole registers custom console tab', () {
      final console = AnConsole.instance;
      console.addConsole('Test Tab', const Text('Tab Content'));
      // 成功调用不应抛出异常
      expect(console.isEnable, isTrue);
    });

    // 测试 logFilesBasePath setter 和 getter
    test('logFilesBasePath getter and setter', () {
      final console = AnConsole.instance;
      const testPath = '/tmp/an_console_logs';

      console.logFilesBasePath = testPath;
      expect(console.logFilesBasePath, equals(testPath));
    });
  });
}
