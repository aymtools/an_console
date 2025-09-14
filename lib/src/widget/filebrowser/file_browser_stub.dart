import 'dart:async';

import 'package:flutter/material.dart';

/// 呼叫重新刷新列表
typedef CallRefresh = void Function();

/// 点击文件时的回调
typedef OnPressFile = void Function(dynamic file, CallRefresh callRefresh);

/// 长按时的回调 包含 文件 和 文件夹
typedef OnLongPress = void Function(dynamic entity, CallRefresh callRefresh);

/// 悬浮按钮构建器
typedef FloatingActionsBuilder = List<FloatingActionButton> Function(
    BuildContext context, String path, CallRefresh callRefresh);

/// 文件浏览器的排序或过滤函数
typedef FileBrowserSortOrFilter = FutureOr<List<dynamic>> Function(
    List<dynamic>);

class FileBrowser extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Center(
      child: Text('unsupported'),
    );
  }

  /// 默认的全局悬浮 更方便管理
  static FloatingActionsBuilder? defaultActions;

  /// 默认的 文件点击 更方便管理
  static OnPressFile? defaultOnPressFile;

  /// 默认的 长按处理 更方便管理
  static OnLongPress? defaultOnLongPress;

  /// 默认的 排序或过滤函数
  static FileBrowserSortOrFilter? defaultSortOrFilter = _sofNone;

  /// 设置所有的默认 行为
  static void setDefaultConfigs(
      {FloatingActionsBuilder? defaultActions,
      OnPressFile? defaultOnPressFile,
      OnLongPress? defaultOnLongPress,
      FileBrowserSortOrFilter? defaultSortOrFilter}) {}

  /// 默认的排序或过滤函数：目录在前，文件在后，按修改时间降序
  static FileBrowserSortOrFilter get sofDirFileAndModifiedDesc =>
      _sofUnsupported;

  /// 默认的排序或过滤函数：目录在前，文件在后，按修改时间升序
  static FileBrowserSortOrFilter get sofDirFileAndModifiedAsc =>
      _sofUnsupported;

  /// 默认的排序或过滤函数：文件在前，目录在后，按修改时间降序
  static FileBrowserSortOrFilter get sofFileDirAndModifiedDesc =>
      _sofUnsupported;

  /// 默认的排序或过滤函数：文件在前，目录在后，按修改时间升序
  static FileBrowserSortOrFilter get sofFileDirAndModifiedAsc =>
      _sofUnsupported;

  /// 默认的排序或过滤函数：不排序
  static FileBrowserSortOrFilter get sofNone => _sofNone;
}

Future<List<dynamic>> _sofUnsupported(List<dynamic> entities) async {
  throw 'unsupported';
}

Future<List<dynamic>> _sofNone(List<dynamic> entities) async => entities;
