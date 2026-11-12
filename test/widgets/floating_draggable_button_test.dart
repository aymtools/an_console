import 'package:an_console/src/widget/draggable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // 设置 SharedPreferences 初始 Mock 数据
    SharedPreferences.setMockInitialValues({});
  });

  group('FloatingDraggableButton Widget Tests', () {
    // 测试悬浮按钮基本渲染与点击回调触发
    testWidgets('renders child and triggers onTap callback', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FloatingDraggableButton(
                  initOffset: const Offset(100, 100),
                  onTap: () {
                    tapped = true;
                  },
                  child: const Text('DragMe'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('DragMe'), findsOneWidget);

      // 点击悬浮按钮
      await tester.tap(find.text('DragMe'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    // 测试悬浮按钮指针拖拽，组件位置更新逻辑
    testWidgets('drags button to update position', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FloatingDraggableButton(
                  initOffset: const Offset(50, 100),
                  child: Container(
                    key: const Key('draggable_child'),
                    width: 50,
                    height: 50,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 获取初始 Positioned 偏移位置
      final initialPositioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(initialPositioned.left, 50);
      expect(initialPositioned.top, 100);

      // 拖拽 50px 右移，50px 下移
      await tester.drag(find.byKey(const Key('draggable_child')), const Offset(50, 50));
      await tester.pump();

      // 验证拖拽后位置偏移更新
      final updatedPositioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(updatedPositioned.left, greaterThan(50));
      expect(updatedPositioned.top, greaterThan(100));
    });
  });
}
