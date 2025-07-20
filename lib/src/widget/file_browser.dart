import 'dart:io';

import 'package:an_console/src/console.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

import 'floating_actions.dart';

typedef CallRefresh = void Function();
typedef OnPressFile = void Function(File file, CallRefresh callRefresh);
typedef OnLongPress = void Function(
    FileSystemEntity entity, CallRefresh callRefresh);
typedef FloatingActionsBuilder = List<FloatingActionButton> Function(
    BuildContext context, String path, CallRefresh callRefresh);

/// 文件浏览器 如果点击了 目录会自动跳转到下一级目录
/// 可以直接使用  [FileBrowser.setDefaultConfigs] 来直接配置全局的行为
class FileBrowser extends StatefulWidget {
  final String path;

  /// 构建右下角的悬浮按钮
  final FloatingActionsBuilder? actions;

  /// 点击文件时
  final OnPressFile? onPressFile;

  /// 长按时处理 包含 文件 和 文件夹
  final OnLongPress? onLongPress;

  const FileBrowser(
      {super.key,
      required this.path,
      required this.actions,
      this.onPressFile,
      this.onLongPress});

  @override
  State<FileBrowser> createState() => _FileBrowserState();

  /// 默认的全局悬浮 更方便管理
  static FloatingActionsBuilder? defaultActions;

  /// 默认的 文件点击 更方便管理
  static OnPressFile? defaultOnPressFile;

  /// 默认的 长按处理 更方便管理
  static OnLongPress? defaultOnLongPress;

  /// 设置所有的默认 行为
  static void setDefaultConfigs(
      {FloatingActionsBuilder? defaultActions,
      OnPressFile? defaultOnPressFile,
      OnLongPress? defaultOnLongPress}) {
    if (defaultActions != null) {
      FileBrowser.defaultActions = defaultActions;
    }
    if (defaultOnPressFile != null) {
      FileBrowser.defaultOnPressFile = defaultOnPressFile;
    }
    if (defaultOnLongPress != null) {
      FileBrowser.defaultOnLongPress = defaultOnLongPress;
    }
  }
}

class _FileBrowserState extends State<FileBrowser> {
  late var _files = getFiles().toList();

  void _refreshFiles() {
    if (!mounted) return;
    _files = getFiles().toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _files,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final files = snapshot.data!;

          return FloatingActions.bottomRight(
            actions: [
              if (widget.actions != null)
                ...widget.actions!(context, widget.path, _refreshFiles),
              if (FileBrowser.defaultActions != null)
                ...FileBrowser.defaultActions!(
                    context, widget.path, _refreshFiles),
            ],
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                final isFile = file is File;
                final fileName = basename(file.path);
                return ListTile(
                  leading: Icon(isFile ? Icons.file_present : Icons.folder),
                  title: Text(fileName),
                  subtitle: isFile ? Text('${file.lengthSync()} bytes') : null,
                  onTap: () {
                    if (!isFile) {
                      final newDir = join(widget.path, fileName);
                      AnConsole.push(fileName,
                          FileBrowser(path: newDir, actions: widget.actions));
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
                      FileBrowser.defaultOnLongPress?.call(file, _refreshFiles);
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

  Stream<FileSystemEntity> getFiles() async* {
    final dirs = Directory(await _getDirPath()).list();
    yield* dirs;
  }

  Future<String> _getDirPath() async {
    final dir = Directory(widget.path);
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }
}
