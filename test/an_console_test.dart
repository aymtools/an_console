import 'package:an_console/an_console.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnConsole Package Export Verification', () {
    // 验证 an_console 核心类及入口可用
    test('exports and instantiates AnConsole successfully', () {
      expect(AnConsole.instance, isNotNull);
      expect(EventManager<String>(), isNotNull);
    });
  });
}
