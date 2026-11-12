import 'package:an_console/an_console.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FloatingActions Widget Tests', () {
    // 测试 FloatingActions.bottomRight 构造并正常渲染悬浮子节点
    testWidgets('renders FloatingActions.bottomRight with action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingActions.bottomRight(
              actions: [
                const Icon(Icons.add, key: Key('action_add')),
                const Icon(Icons.delete, key: Key('action_delete')),
              ],
              child: ListView.builder(
                itemCount: 50,
                itemBuilder: (context, index) => Text('Item $index'),
              ),
            ),
          ),
        ),
      );

      // 验证主内容及右下角悬浮按钮均已成功渲染
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.byKey(const Key('action_add')), findsOneWidget);
      expect(find.byKey(const Key('action_delete')), findsOneWidget);
    });

    // 测试 FloatingActions.topRight 构造函数
    testWidgets('renders FloatingActions.topRight with action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingActions.topRight(
              actions: [
                const Icon(Icons.star, key: Key('action_star')),
              ],
              child: const Center(child: Text('Content')),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byKey(const Key('action_star')), findsOneWidget);
    });

    // 测试向上/向下滚动列表时，悬浮按钮自动隐藏与重新显示的联动效果
    testWidgets('hides actions on scroll down and shows actions on scroll up', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingActions.bottomRight(
              actions: [
                const Icon(Icons.refresh, key: Key('action_refresh')),
              ],
              child: ListView.builder(
                itemCount: 100,
                itemBuilder: (context, index) => SizedBox(
                  height: 50,
                  child: Text('Item $index'),
                ),
              ),
            ),
          ),
        ),
      );

      // 初始状态下悬浮按钮可见
      expect(find.byKey(const Key('action_refresh')), findsOneWidget);

      // 向下滚动 300 像素，触发隐藏悬浮按钮
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();

      expect(find.byKey(const Key('action_refresh')), findsNothing);

      // 向上滚动 300 像素，触发重新显示悬浮按钮
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pump();

      expect(find.byKey(const Key('action_refresh')), findsOneWidget);
    });
  });
}
