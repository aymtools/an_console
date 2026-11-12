import 'dart:io';

import 'package:an_console/an_console.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventManager Unit Tests', () {
    // 测试初始化默认缓冲区大小以及自定义缓冲区大小
    test('initialization with default and custom buffer sizes', () {
      // 默认 EventManager 缓冲区大小应为 500
      final defaultManager = EventManager<String>();
      expect(defaultManager.buffers, isEmpty);

      // 指定自定义缓冲区大小为 20
      final customManager = EventManager<String>(bufferSize: 20);
      expect(customManager.buffers, isEmpty);

      // 缓冲区大小小于 10 时，应自动纠正为默认值 500
      final smallManager = EventManager<String>(bufferSize: 5);
      for (int i = 0; i < 600; i++) {
        smallManager.addEvent('Event $i');
      }
      expect(smallManager.buffers.length, 500);
    });

    // 测试添加事件逻辑：最新事件放在头部，达到容量限制时移除最老事件
    test('addEvent adds to buffer front and drops oldest when buffer is full', () {
      final manager = EventManager<int>(bufferSize: 10);
      for (int i = 1; i <= 15; i++) {
        manager.addEvent(i);
      }

      // 容量为 10，最新的事件 15 应该在 index 0（队列头部）
      expect(manager.buffers.length, 10);
      expect(manager.buffers.first, 15);
      expect(manager.buffers.last, 6);
    });

    // 测试 addEvent 和 clear 操作触发 ChangeNotifier 通知
    test('addEvent and clear notify listeners', () {
      final manager = EventManager<String>(bufferSize: 10);
      int notifyCount = 0;
      manager.addListener(() {
        notifyCount++;
      });

      // 添加第一个事件，通知次数加 1
      manager.addEvent('A');
      expect(notifyCount, 1);

      // 添加第二个事件，通知次数加 1
      manager.addEvent('B');
      expect(notifyCount, 2);

      // 清空事件，通知次数加 1
      manager.clear();
      expect(notifyCount, 3);
      expect(manager.buffers, isEmpty);
    });

    // 测试 saveEventsToFile 扩展方法将缓冲区事件正确格式化写入日志文件
    test('saveEventsToFile saves formatted events to log file', () async {
      final tempDir = await Directory.systemTemp.createTemp('an_console_test_');
      try {
        // 设置控制台日志保存路径
        AnConsole.instance.logFilesBasePath = tempDir.path;

        final manager = EventManager<String>(bufferSize: 10);
        manager.addEvent('Log line 1');
        manager.addEvent('Log line 2');

        // 执行保存操作
        final savedPath = await manager.saveEventsToFile(
          logFile: 'test_logs',
          convert: (e) => '[TEST] $e',
        );

        // 验证文件存在且内容正确
        expect(savedPath, isNotEmpty);
        final file = File(savedPath);
        expect(await file.exists(), isTrue);

        final content = await file.readAsString();
        expect(content, contains('[TEST] Log line 2'));
        expect(content, contains('[TEST] Log line 1'));
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });

  group('EventManagerConsole Widget Tests', () {
    // 测试 EventManagerConsole 组件渲染事件列表及清空按钮逻辑
    testWidgets('renders events and handles clean action', (WidgetTester tester) async {
      final manager = EventManager<String>(bufferSize: 10);
      manager.addEvent('Item 1');
      manager.addEvent('Item 2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventManagerConsole<String>(
              manager: manager,
              eventBuilder: (context, position, event) => Text('Event: $event'),
              showClean: true,
            ),
          ),
        ),
      );

      // 验证事件节点已渲染
      expect(find.text('Event: Item 1'), findsOneWidget);
      expect(find.text('Event: Item 2'), findsOneWidget);

      // 查找并点击清空按钮
      final cleanButton = find.byIcon(Icons.cleaning_services_sharp);
      expect(cleanButton, findsOneWidget);
      await tester.tap(cleanButton);
      await tester.pump();

      // 验证事件数据已清空
      expect(manager.buffers, isEmpty);
      expect(find.text('Event: Item 1'), findsNothing);
    });

    // 测试使用 filterNotifier 对事件列表进行动态过滤
    testWidgets('filters events using filterNotifier', (WidgetTester tester) async {
      final manager = EventManager<String>(bufferSize: 10);
      manager.addEvent('Apple');
      manager.addEvent('Banana');
      manager.addEvent('Avocado');

      // 仅保留以 'A' 开头的字符串
      final filterNotifier = ValueNotifier<bool Function(String)>((item) => item.startsWith('A'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventManagerConsole<String>(
              manager: manager,
              filterNotifier: filterNotifier,
              eventBuilder: (context, position, event) => Text('Item: $event'),
            ),
          ),
        ),
      );

      // 验证过滤结果
      expect(find.text('Item: Apple'), findsOneWidget);
      expect(find.text('Item: Avocado'), findsOneWidget);
      expect(find.text('Item: Banana'), findsNothing);

      // 更新过滤规则：仅保留包含 'n' 的字符串
      filterNotifier.value = (item) => item.contains('n');
      await tester.pump();

      expect(find.text('Item: Banana'), findsOneWidget);
      expect(find.text('Item: Apple'), findsNothing);
    });
  });
}
