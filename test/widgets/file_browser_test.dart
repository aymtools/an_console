import 'dart:io';

import 'package:an_console/an_console.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File fileA;
  late File fileB;
  late Directory subDir;

  setUp(() async {
    // 创建临时测试目录及文件结构
    tempDir = await Directory.systemTemp.createTemp('file_browser_test_');

    // 创建子目录
    subDir = Directory('${tempDir.path}/dir_a');
    await subDir.create();

    // 创建测试文件 A
    fileA = File('${tempDir.path}/file_a.txt');
    await fileA.writeAsString('File A content');

    // 短暂延迟以拉开修改时间间隔
    await Future.delayed(const Duration(milliseconds: 50));

    // 创建测试文件 B
    fileB = File('${tempDir.path}/file_b.txt');
    await fileB.writeAsString('File B content');
  });

  tearDown(() async {
    // 清理临时文件
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FileBrowser Sorting Functions Unit Tests', () {
    // 测试 FileBrowser.sofNone 不改变原始排序
    test('sofNone returns original entities without reordering', () async {
      final entities = [fileA, subDir, fileB];
      final sorted = await FileBrowser.sofNone(entities);
      expect(sorted, equals(entities));
    });

    // 测试 DirFileAndModifiedDesc（目录在前，文件在后，按修改时间降序）
    test('sofDirFileAndModifiedDesc puts directories first, followed by files desc by modified time', () async {
      final entities = [fileA, subDir, fileB];
      final sorted = await FileBrowser.sofDirFileAndModifiedDesc(entities);

      // 第一项应当为目录 subDir
      expect(sorted.first.path, equals(subDir.path));

      // 接下来应当是较新修改的文件 fileB，而后是 fileA
      expect(sorted[1].path, equals(fileB.path));
      expect(sorted[2].path, equals(fileA.path));
    });

    // 测试 FileDirAndModifiedDesc（文件在前，目录在后，按修改时间降序）
    test('sofFileDirAndModifiedDesc puts files first desc, followed by directories', () async {
      final entities = [fileA, subDir, fileB];
      final sorted = await FileBrowser.sofFileDirAndModifiedDesc(entities);

      // 文件位于列表前面
      expect(sorted[0].path, equals(fileB.path));
      expect(sorted[1].path, equals(fileA.path));
      // 目录位于列表末尾
      expect(sorted[2].path, equals(subDir.path));
    });

    // 测试 DirFileAndModifiedAsc（目录在前，文件在后，按修改时间升序）
    test('sofDirFileAndModifiedAsc puts directories first, followed by files asc', () async {
      final entities = [fileA, subDir, fileB];
      final sorted = await FileBrowser.sofDirFileAndModifiedAsc(entities);

      expect(sorted.first.path, equals(subDir.path));
      expect(sorted[1].path, equals(fileA.path));
      expect(sorted[2].path, equals(fileB.path));
    });

    // 测试 FileDirAndModifiedAsc（文件在前，目录在后，按修改时间升序）
    test('sofFileDirAndModifiedAsc puts files first asc, followed by directories', () async {
      final entities = [fileA, subDir, fileB];
      final sorted = await FileBrowser.sofFileDirAndModifiedAsc(entities);

      expect(sorted[0].path, equals(fileA.path));
      expect(sorted[1].path, equals(fileB.path));
      expect(sorted[2].path, equals(subDir.path));
    });
  });

  group('FileBrowser Widget Tests', () {
    // 测试 FileBrowser.setDefaultConfigs 全局默认配置与点击回调
    testWidgets('renders directory contents and triggers onPressFile callback', (WidgetTester tester) async {
      File? pressedFile;

      FileBrowser.setDefaultConfigs(
        defaultOnPressFile: (file, callRefresh) {
          pressedFile = file as File;
        },
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileBrowser(
                path: tempDir.path,
                sortOrFilter: FileBrowser.sofNone,
              ),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      // 验证目录和文件名渲染
      expect(find.text('dir_a'), findsOneWidget);
      expect(find.text('file_a.txt'), findsOneWidget);
      expect(find.text('file_b.txt'), findsOneWidget);

      // 点击 file_a.txt
      await tester.tap(find.text('file_a.txt'));
      await tester.pump();

      // 验证回调函数接收到的文件路径
      expect(pressedFile, isNotNull);
      expect(pressedFile!.path, equals(fileA.path));
    });

    // 测试长按文件/文件夹回调函数 trigger onLongPress
    testWidgets('triggers onLongPress callback on entity long press', (WidgetTester tester) async {
      FileSystemEntity? longPressedEntity;

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileBrowser(
                path: tempDir.path,
                onLongPress: (entity, callRefresh) {
                  longPressedEntity = entity as FileSystemEntity;
                },
              ),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      // 长按子目录 dir_a
      await tester.longPress(find.text('dir_a'));
      await tester.pump();

      expect(longPressedEntity, isNotNull);
      expect(longPressedEntity!.path, equals(subDir.path));
    });
  });
}
