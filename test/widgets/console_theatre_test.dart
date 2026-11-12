import 'package:an_console/src/console_theater.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsoleTheatre RenderObject Widget Tests', () {
    // 测试 ConsoleTheatre 当 skipCount 为 0 时正常渲染全部子组件
    testWidgets('renders all children onstage when skipCount is 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConsoleTheatre(
              skipCount: 0,
              children: const [
                Text('Child 1'),
                Text('Child 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsOneWidget);
    });

    // 测试 ConsoleTheatre 当 skipCount 为 1 时跳过前 1 个子组件（将其作为 offstage 处理）
    testWidgets('skips layout and rendering for first skipCount children', (WidgetTester tester) async {
      bool child1Tapped = false;
      bool child2Tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConsoleTheatre(
              skipCount: 1,
              children: [
                GestureDetector(
                  onTap: () => child1Tapped = true,
                  child: const Text('Child 1'),
                ),
                GestureDetector(
                  onTap: () => child2Tapped = true,
                  child: const Text('Child 2'),
                ),
              ],
            ),
          ),
        ),
      );

      // Child 2 在台前 (onstage)，能够成功响应点击测试
      await tester.tap(find.text('Child 2'));
      await tester.pump();
      expect(child2Tapped, isTrue);

      // Child 1 在后台 (offstage)，尝试点击不应触发响应
      expect(child1Tapped, isFalse);
    });
  });
}
