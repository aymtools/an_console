import 'package:an_console/src/widget/change_notifier_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 用于测试的简单 ChangeNotifier 实现类
class TestNotifier extends ChangeNotifier {
  int _counter = 0;
  int get counter => _counter;

  bool get hasTestListeners => hasListeners;

  void increment() {
    _counter++;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChangeNotifierBuilder Widget Tests', () {
    // 测试 ChangeNotifierBuilder 监听通知并触发重新构建
    testWidgets('rebuilds child widget when notifier updates', (WidgetTester tester) async {
      final notifier = TestNotifier();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierBuilder<TestNotifier>(
              changeNotifier: notifier,
              builder: (context, data, child) {
                return Text('Value: ${data.counter}');
              },
            ),
          ),
        ),
      );

      // 初始值验证
      expect(find.text('Value: 0'), findsOneWidget);

      // 递增计数并通知监听器
      notifier.increment();
      await tester.pump();

      // 验证 UI 重新构建并展示更新后的数值
      expect(find.text('Value: 1'), findsOneWidget);
    });

    // 测试当传入新的 changeNotifier 实例时，能够解绑旧实例并绑定新实例
    testWidgets('updates listener when changeNotifier property changes', (WidgetTester tester) async {
      final notifier1 = TestNotifier();
      final notifier2 = TestNotifier();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierBuilder<TestNotifier>(
              changeNotifier: notifier1,
              builder: (context, data, child) {
                return Text('Value: ${data.counter}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Value: 0'), findsOneWidget);

      // 传入新的 notifier2 示例
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierBuilder<TestNotifier>(
              changeNotifier: notifier2,
              builder: (context, data, child) {
                return Text('Value: ${data.counter}');
              },
            ),
          ),
        ),
      );

      // 触发 notifier1 更新，UI 不应响应
      notifier1.increment();
      await tester.pump();
      expect(find.text('Value: 0'), findsOneWidget);

      // 触发 notifier2 更新，UI 应当正常响应
      notifier2.increment();
      await tester.pump();
      expect(find.text('Value: 1'), findsOneWidget);
    });

    // 测试组件销毁 (dispose) 时移除监听器
    testWidgets('removes listener on dispose', (WidgetTester tester) async {
      final notifier = TestNotifier();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierBuilder<TestNotifier>(
              changeNotifier: notifier,
              builder: (context, data, child) {
                return Text('Value: ${data.counter}');
              },
            ),
          ),
        ),
      );

      expect(notifier.hasTestListeners, isTrue);

      // 移除组件
      await tester.pumpWidget(const SizedBox.shrink());

      // 验证监听器是否已被完全移除
      expect(notifier.hasTestListeners, isFalse);
    });
  });
}
