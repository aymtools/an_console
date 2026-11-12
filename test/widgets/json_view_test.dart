import 'package:an_console/an_console.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // 单元测试环境中配置同步 JSON 解析器，避免 compute Isolate 与 pumpAndSettle 超时
    JsonView.jsonParser = (json, parsing) async => parsing(json);
  });

  group('JsonView Data Structures & Utility Tests', () {
    // 测试 isPrimitive 判断标量基础类型逻辑
    test('isPrimitive checks basic primitive types correctly', () {
      expect(isPrimitive(123), isTrue);
      expect(isPrimitive(3.14), isTrue);
      expect(isPrimitive('hello'), isTrue);
      expect(isPrimitive(true), isTrue);

      expect(isPrimitive([1, 2, 3]), isFalse);
      expect(isPrimitive({'key': 'value'}), isFalse);
      expect(isPrimitive(null), isFalse);
    });

    // 测试 JTreeNode 节点树结构的属性与路径计算
    test('JTreeNode construction and absolutePath generation', () {
      final root = JTreeNode.root(type: NodeType.mapStart, value: {});
      expect(root.isRoot, isTrue);
      expect(root.level, 0);

      final child = root.makeChild(
        path: 'user',
        type: NodeType.mapKey,
        value: const MapEntry('user', 'Alice'),
      );

      expect(child.isRoot, isFalse);
      expect(child.parent, root);
      expect(child.level, 1);
      expect(root.children.length, 1);
      expect(root.children.first, child);
    });
  });

  group('JsonView Widget Tests', () {
    // 测试解析 Map 类型的 JSON 数据并正确渲染
    testWidgets('renders JsonView with Map data', (WidgetTester tester) async {
      final jsonMap = {
        'name': 'an_console',
        'version': 1.0,
        'enabled': true,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JsonView(json: jsonMap),
          ),
        ),
      );

      await tester.pump();

      // 验证 JSON 中的 key 与 value 字符串在界面呈现
      expect(find.textContaining('name'), findsWidgets);
      expect(find.textContaining('an_console'), findsWidgets);
      expect(find.textContaining('version'), findsWidgets);
      expect(find.textContaining('enabled'), findsWidgets);
    });

    // 测试解析 List 类型的 JSON 数据并正确渲染
    testWidgets('renders JsonView with List data', (WidgetTester tester) async {
      final jsonList = ['apple', 'banana', 'cherry'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JsonView(json: jsonList),
          ),
        ),
      );

      await tester.pump();

      // 验证数组索引与列表元素正常展示
      expect(find.textContaining('[0]'), findsOneWidget);
      expect(find.textContaining('"apple"'), findsOneWidget);
      expect(find.textContaining('[1]'), findsOneWidget);
      expect(find.textContaining('"banana"'), findsOneWidget);
    });

    // 测试直接传入 JSON 格式字符串解析
    testWidgets('renders JsonView with raw JSON string', (WidgetTester tester) async {
      const rawJson = '{"status": "ok", "code": 200}';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JsonView(json: rawJson),
          ),
        ),
      );

      await tester.pump();

      expect(find.textContaining('status'), findsWidgets);
      expect(find.textContaining('ok'), findsWidgets);
      expect(find.textContaining('code'), findsWidgets);
    });

    // 测试 JsonView.sliver 的 Sliver 场景构建
    testWidgets('renders JsonView.sliver inside CustomScrollView', (WidgetTester tester) async {
      final jsonMap = {'tag': 'sliver_test'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                JsonView.sliver(json: jsonMap),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.textContaining('tag'), findsWidgets);
      expect(find.textContaining('sliver_test'), findsWidgets);
    });

    // 测试 JsonView.custom 自定义节点渲染器
    testWidgets('renders JsonView.custom with custom builder', (WidgetTester tester) async {
      final jsonMap = {'key1': 'val1', 'key2': 'val2'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JsonView.custom(
              json: jsonMap,
              sliver: false,
              builder: (context, nodes) {
                return Text('Custom Nodes Count: ${nodes.nodes.length}');
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.textContaining('Custom Nodes Count:'), findsOneWidget);
    });
  });
}
