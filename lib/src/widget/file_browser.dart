import 'dart:async';
import 'dart:io';

import 'package:an_console/src/console.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

import 'floating_actions.dart';

/// 呼叫重新刷新列表
typedef CallRefresh = void Function();

/// 点击文件时的回调
typedef OnPressFile = void Function(File file, CallRefresh callRefresh);

/// 长按时的回调 包含 文件 和 文件夹
typedef OnLongPress = void Function(
    FileSystemEntity entity, CallRefresh callRefresh);

/// 悬浮按钮构建器
typedef FloatingActionsBuilder = List<FloatingActionButton> Function(
    BuildContext context, String path, CallRefresh callRefresh);

/// 文件浏览器的排序或过滤函数
typedef FileBrowserSortOrFilter = FutureOr<List<FileSystemEntity>> Function(
    List<FileSystemEntity>);

/// 文件浏览器 如果点击了 目录会自动跳转到下一级目录
/// 可以直接使用  [FileBrowser.setDefaultConfigs] 来直接配置全局的行为
class FileBrowser extends StatefulWidget {
  final FutureOr<String> path;

  /// 构建右下角的悬浮按钮
  final FloatingActionsBuilder? actions;

  /// 点击文件时
  final OnPressFile? onPressFile;

  /// 长按时处理 包含 文件 和 文件夹
  final OnLongPress? onLongPress;

  /// 排序或过滤函数
  final FileBrowserSortOrFilter? sortOrFilter;

  const FileBrowser({
    super.key,
    required this.path,
    this.actions,
    this.onPressFile,
    this.onLongPress,
    this.sortOrFilter,
  });

  @override
  State<FileBrowser> createState() => _FileBrowserState();

  /// 默认的全局悬浮 更方便管理
  static FloatingActionsBuilder? defaultActions;

  /// 默认的 文件点击 更方便管理
  static OnPressFile? defaultOnPressFile;

  /// 默认的 长按处理 更方便管理
  static OnLongPress? defaultOnLongPress;

  /// 默认的 排序或过滤函数
  static FileBrowserSortOrFilter? defaultSortOrFilter =
      _sofDirFileAndModifiedDesc;

  /// 设置所有的默认 行为
  static void setDefaultConfigs(
      {FloatingActionsBuilder? defaultActions,
      OnPressFile? defaultOnPressFile,
      OnLongPress? defaultOnLongPress,
      FileBrowserSortOrFilter? defaultSortOrFilter}) {
    if (defaultActions != null) {
      FileBrowser.defaultActions = defaultActions;
    }
    if (defaultOnPressFile != null) {
      FileBrowser.defaultOnPressFile = defaultOnPressFile;
    }
    if (defaultOnLongPress != null) {
      FileBrowser.defaultOnLongPress = defaultOnLongPress;
    }
    if (defaultSortOrFilter != null) {
      FileBrowser.defaultSortOrFilter = defaultSortOrFilter;
    }
  }

  /// 默认的排序或过滤函数：目录在前，文件在后，按修改时间降序
  static FileBrowserSortOrFilter get sofDirFileAndModifiedDesc =>
      _sofDirFileAndModifiedDesc;

  /// 默认的排序或过滤函数：目录在前，文件在后，按修改时间升序
  static FileBrowserSortOrFilter get sofDirFileAndModifiedAsc =>
      _sofDirFileAndModifiedAsc;

  /// 默认的排序或过滤函数：文件在前，目录在后，按修改时间降序
  static FileBrowserSortOrFilter get sofFileDirAndModifiedDesc =>
      _sofFileDirAndModifiedDesc;

  /// 默认的排序或过滤函数：文件在前，目录在后，按修改时间升序
  static FileBrowserSortOrFilter get sofFileDirAndModifiedAsc =>
      _sofFileDirAndModifiedAsc;

  /// 默认的排序或过滤函数：不排序
  static FileBrowserSortOrFilter get sofNone => _sofNone;
}

class _FileBrowserState extends State<FileBrowser> {
  late var _files = loadFiles();
  late String _path = '';

  void _refreshFiles() {
    if (!mounted) return;
    _files = loadFiles();
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant FileBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.path != oldWidget.path) {
      _files = loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      key: ValueKey(_files),
      future: _files,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final files = snapshot.data!;

          return FloatingActions.bottomRight(
            actions: [
              if (widget.actions != null)
                ...widget.actions!(context, _path, _refreshFiles),
              if (widget.actions == null && FileBrowser.defaultActions != null)
                ...FileBrowser.defaultActions!(context, _path, _refreshFiles),
            ],
            child: files.isEmpty
                ? Center(child: Text('Empty: ${_path}'))
                : ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final isFile = file is File;
                      final fileName = basename(file.path);
                      return ListTile(
                        leading:
                            Icon(isFile ? Icons.file_present : Icons.folder),
                        title: Text(fileName),
                        subtitle:
                            isFile ? Text('${file.lengthSync()} bytes') : null,
                        onTap: () {
                          if (!isFile) {
                            final newDir = join(_path, fileName);
                            AnConsole.push(
                                fileName,
                                FileBrowser(
                                    path: newDir, actions: widget.actions));
                          } else {
                            if (widget.onPressFile != null) {
                              widget.onPressFile?.call(file, _refreshFiles);
                            } else if (FileBrowser.defaultOnPressFile != null) {
                              FileBrowser.defaultOnPressFile
                                  ?.call(file, _refreshFiles);
                            }
                          }
                        },
                        onLongPress: () {
                          if (widget.onLongPress != null) {
                            widget.onLongPress?.call(file, _refreshFiles);
                          } else if (FileBrowser.defaultOnLongPress != null) {
                            FileBrowser.defaultOnLongPress
                                ?.call(file, _refreshFiles);
                          }
                        },
                      );
                    },
                  ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<List<FileSystemEntity>> loadFiles() async {
    var files = await _getFiles().toList();
    if (files.length > 1) {
      if (widget.sortOrFilter != null) {
        files = await widget.sortOrFilter!(files);
      } else if (FileBrowser.defaultSortOrFilter != null) {
        files = await FileBrowser.defaultSortOrFilter!(files);
      }
    }
    return files;
  }

  Stream<FileSystemEntity> _getFiles() async* {
    final dirs = Directory(await _getDirPath()).list();
    yield* dirs;
  }

  Future<String> _getDirPath() async {
    _path = await widget.path;
    final dir = Directory(_path);
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }
}

Future<List<FileSystemEntity>> _sofNone(
        List<FileSystemEntity> entities) async =>
    entities;

Future<List<FileSystemEntity>> _sofDirFileAndModifiedDesc(
    List<FileSystemEntity> entities) async {
  // 获取每个实体的 stat（带时间信息）
  final withStats = await Future.wait(entities.map((entity) async {
    final stat = await entity.stat();
    return MapEntry(entity, stat);
  }));

  /// 降序
  withStats.sort((a, b) => b.value.modified.compareTo(a.value.modified));

  // 分成文件夹和文件分别排序
  final dirs = withStats
      .where((e) => e.value.type == FileSystemEntityType.directory)
      .toList();

  final files = withStats
      .where((e) => e.value.type == FileSystemEntityType.file)
      .toList();

  final sorted = [...dirs, ...files]; // 文件夹在前，文件在后

  return sorted.map((e) => e.key).toList();
}

Future<List<FileSystemEntity>> _sofDirFileAndModifiedAsc(
    List<FileSystemEntity> entities) async {
  // 获取每个实体的 stat（带时间信息）
  final withStats = await Future.wait(entities.map((entity) async {
    final stat = await entity.stat();
    return MapEntry(entity, stat);
  }));

  /// 升序
  withStats.sort((a, b) => a.value.modified.compareTo(b.value.modified));

  // 分成文件夹和文件分别排序
  final dirs = withStats
      .where((e) => e.value.type == FileSystemEntityType.directory)
      .toList();

  final files = withStats
      .where((e) => e.value.type == FileSystemEntityType.file)
      .toList();

  final sorted = [...dirs, ...files]; // 文件夹在前，文件在后

  return sorted.map((e) => e.key).toList();
}

Future<List<FileSystemEntity>> _sofFileDirAndModifiedDesc(
    List<FileSystemEntity> entities) async {
  // 获取每个实体的 stat（带时间信息）
  final withStats = await Future.wait(entities.map((entity) async {
    final stat = await entity.stat();
    return MapEntry(entity, stat);
  }));

  /// 降序
  withStats.sort((a, b) => b.value.modified.compareTo(a.value.modified));

  // 分成文件夹和文件分别排序
  final dirs = withStats
      .where((e) => e.value.type == FileSystemEntityType.directory)
      .toList();

  final files = withStats
      .where((e) => e.value.type == FileSystemEntityType.file)
      .toList();

  final sorted = [...files, ...dirs]; // 文件在前，文件夹在后

  return sorted.map((e) => e.key).toList();
}

Future<List<FileSystemEntity>> _sofFileDirAndModifiedAsc(
    List<FileSystemEntity> entities) async {
  // 获取每个实体的 stat（带时间信息）
  final withStats = await Future.wait(entities.map((entity) async {
    final stat = await entity.stat();
    return MapEntry(entity, stat);
  }));

  /// 升序
  withStats.sort((a, b) => a.value.modified.compareTo(b.value.modified));

  // 分成文件夹和文件分别排序
  final dirs = withStats
      .where((e) => e.value.type == FileSystemEntityType.directory)
      .toList();

  final files = withStats
      .where((e) => e.value.type == FileSystemEntityType.file)
      .toList();

  final sorted = [...files, ...dirs]; // 文件在前，文件夹在后

  return sorted.map((e) => e.key).toList();
}
